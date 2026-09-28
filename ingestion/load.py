"""Download NYC TLC source files and load them idempotently into Snowflake."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Iterator

import requests
import snowflake.connector
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


TAXI_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data/{filename}"
ZONE_URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")
MONTH = re.compile(r"^(20\d{2})-(0[1-9]|1[0-2])$")


@dataclass(frozen=True)
class Settings:
    account: str
    user: str
    password: str
    role: str
    warehouse: str
    database: str
    start_month: str
    end_month: str
    data_dir: Path


def required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def safe_identifier(name: str, default: str) -> str:
    value = os.getenv(name, default).strip()
    if not IDENTIFIER.fullmatch(value):
        raise RuntimeError(f"{name} is not a valid unquoted Snowflake identifier")
    return value.upper()


def load_settings() -> Settings:
    start_month = os.getenv("TAXI_START_MONTH", "2025-01")
    end_month = os.getenv("TAXI_END_MONTH", "2026-08")
    if not MONTH.fullmatch(start_month) or not MONTH.fullmatch(end_month):
        raise RuntimeError("TAXI_START_MONTH and TAXI_END_MONTH must use YYYY-MM")
    return Settings(
        account=required_env("SNOWFLAKE_ACCOUNT"),
        user=required_env("SNOWFLAKE_USER"),
        password=required_env("SNOWFLAKE_PASSWORD"),
        role=os.getenv("SNOWFLAKE_ROLE", "SYSADMIN"),
        warehouse=safe_identifier("SNOWFLAKE_WAREHOUSE", "NYC_TAXI_WH"),
        database=safe_identifier("SNOWFLAKE_DATABASE", "NYC_TAXI"),
        start_month=start_month,
        end_month=end_month,
        data_dir=Path(os.getenv("TAXI_DATA_DIR", "/data")),
    )


def month_range(start: str, end: str) -> Iterator[str]:
    start_year, start_number = map(int, start.split("-"))
    end_year, end_number = map(int, end.split("-"))
    current = date(start_year, start_number, 1)
    final = date(end_year, end_number, 1)
    if current > final:
        raise RuntimeError("TAXI_START_MONTH must not be after TAXI_END_MONTH")
    while current <= final:
        yield current.strftime("%Y-%m")
        current = date(
            current.year + (1 if current.month == 12 else 0),
            1 if current.month == 12 else current.month + 1,
            1,
        )


def http_session() -> requests.Session:
    retry = Retry(
        total=5,
        connect=5,
        read=5,
        backoff_factor=1,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=("GET", "HEAD"),
    )
    session = requests.Session()
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers["User-Agent"] = "nyc-taxi-elt-lab/1.0"
    return session


def verify_trip_sources(session: requests.Session, periods: list[str]) -> None:
    unavailable: list[str] = []
    for period in periods:
        filename = f"yellow_tripdata_{period}.parquet"
        response = session.head(
            TAXI_URL.format(filename=filename),
            allow_redirects=True,
            timeout=(15, 60),
        )
        if response.status_code != 200:
            unavailable.append(f"{filename} (HTTP {response.status_code})")
        response.close()
    if unavailable:
        detail = ", ".join(unavailable)
        raise RuntimeError(
            "The required NYC TLC source files are not all available: " + detail
        )
    print(f"Source preflight passed for {len(periods)} monthly files")


def download(session: requests.Session, url: str, destination: Path) -> None:
    if destination.exists() and destination.stat().st_size > 0:
        print(f"Using cached file {destination.name}")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".part")
    with session.get(url, stream=True, timeout=(15, 180)) as response:
        response.raise_for_status()
        with temporary.open("wb") as output:
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    output.write(chunk)
    temporary.replace(destination)
    print(f"Downloaded {destination.name} ({destination.stat().st_size:,} bytes)")


def sql_string(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def put_file(cursor, path: Path, stage: str) -> None:
    cursor.execute(
        f"PUT {sql_string('file://' + path.resolve().as_posix())} @{stage} "
        "AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
    )


def load_trip_file(connection, settings: Settings, path: Path, period: str) -> None:
    table = f"{settings.database}.BRONZE.RAW_YELLOW_TAXI"
    stage = f"{settings.database}.BRONZE.YELLOW_TAXI_STAGE"
    file_format = f"{settings.database}.BRONZE.YELLOW_TAXI_PARQUET_FORMAT"
    with connection.cursor() as cursor:
        put_file(cursor, path, stage)
        try:
            cursor.execute(f"DELETE FROM {table} WHERE SOURCE_PERIOD = %s", (period,))
            cursor.execute(
                f"""
                COPY INTO {table}
                    (RAW_RECORD, SOURCE_FILE, SOURCE_PERIOD, SOURCE_ROW_NUMBER, LOADED_AT)
                FROM (
                    SELECT $1, {sql_string(path.name)}, {sql_string(period)},
                           METADATA$FILE_ROW_NUMBER, CURRENT_TIMESTAMP()
                    FROM @{stage}
                )
                FILE_FORMAT = (FORMAT_NAME = {file_format})
                FILES = ({sql_string(path.name)})
                FORCE = TRUE
                ON_ERROR = 'ABORT_STATEMENT'
                """
            )
            connection.commit()
        except Exception:
            connection.rollback()
            raise
    print(f"Loaded source period {period}")


def load_zone_lookup(connection, settings: Settings, path: Path) -> None:
    table = f"{settings.database}.BRONZE.RAW_TAXI_ZONE_LOOKUP"
    stage = f"{settings.database}.BRONZE.TAXI_ZONE_STAGE"
    file_format = f"{settings.database}.BRONZE.TAXI_ZONE_CSV_FORMAT"
    with connection.cursor() as cursor:
        put_file(cursor, path, stage)
        try:
            cursor.execute(f"DELETE FROM {table}")
            cursor.execute(
                f"""
                COPY INTO {table}
                    (LOCATION_ID, BOROUGH, ZONE, SERVICE_ZONE, SOURCE_FILE, LOADED_AT)
                FROM (
                    SELECT TRY_TO_NUMBER($1), $2::VARCHAR, $3::VARCHAR, $4::VARCHAR,
                           {sql_string(path.name)}, CURRENT_TIMESTAMP()
                    FROM @{stage}
                )
                FILE_FORMAT = (FORMAT_NAME = {file_format})
                FILES = ({sql_string(path.name)})
                FORCE = TRUE
                ON_ERROR = 'ABORT_STATEMENT'
                """
            )
            connection.commit()
        except Exception:
            connection.rollback()
            raise
    print("Loaded taxi zone lookup")


def main() -> None:
    settings = load_settings()
    periods = list(month_range(settings.start_month, settings.end_month))
    print(f"Preparing {len(periods)} Yellow Taxi monthly files")
    if len(periods) != 20:
        print("Warning: configured range does not contain the 20 assignment months")

    session = http_session()
    verify_trip_sources(session, periods)
    zone_path = settings.data_dir / "taxi_zone_lookup.csv"
    download(session, ZONE_URL, zone_path)

    connection = snowflake.connector.connect(
        account=settings.account,
        user=settings.user,
        password=settings.password,
        role=settings.role,
        warehouse=settings.warehouse,
        database=settings.database,
        schema="BRONZE",
        autocommit=False,
        session_parameters={"QUERY_TAG": "nyc_taxi_elt_ingestion"},
    )
    try:
        load_zone_lookup(connection, settings, zone_path)
        for period in periods:
            filename = f"yellow_tripdata_{period}.parquet"
            path = settings.data_dir / filename
            download(session, TAXI_URL.format(filename=filename), path)
            load_trip_file(connection, settings, path, period)
    finally:
        connection.close()
        session.close()


if __name__ == "__main__":
    main()
