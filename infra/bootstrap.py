"""Create the Snowflake objects required by the ELT pipeline."""

from __future__ import annotations

import os
import re
from pathlib import Path

import snowflake.connector


IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")


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


def main() -> None:
    replacements = {
        "{{ database }}": safe_identifier("SNOWFLAKE_DATABASE", "NYC_TAXI"),
        "{{ warehouse }}": safe_identifier("SNOWFLAKE_WAREHOUSE", "NYC_TAXI_WH"),
    }
    sql_path = Path(__file__).with_name("snowflake_setup.sql")
    sql = sql_path.read_text(encoding="utf-8")
    for placeholder, value in replacements.items():
        sql = sql.replace(placeholder, value)

    connection = snowflake.connector.connect(
        account=required_env("SNOWFLAKE_ACCOUNT"),
        user=required_env("SNOWFLAKE_USER"),
        password=required_env("SNOWFLAKE_PASSWORD"),
        role=os.getenv("SNOWFLAKE_ROLE", "SYSADMIN"),
        session_parameters={"QUERY_TAG": "nyc_taxi_elt_bootstrap"},
    )
    try:
        for cursor in connection.execute_string(sql):
            cursor.close()
        print("Snowflake infrastructure is ready.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
