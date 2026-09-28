# Arquitectura Kestra + Snowflake + dbt

```mermaid
flowchart LR
    USER[Usuario / Schedule]
    KESTRA[Kestra 2.0.3<br/>orquestación y observabilidad]
    PG[(PostgreSQL<br/>metadata de Kestra)]
    TLC[NYC TLC<br/>Parquet + zonas CSV]
    PY[Imagen Python<br/>bootstrap e ingesta]
    STAGE[Snowflake internal stages]
    RAW[(Bronze raw<br/>VARIANT + metadata)]
    DBT[dbt Core<br/>ejecutado por Kestra]
    BRZ[(Bronze<br/>tipado)]
    SLV[(Silver<br/>válidos + rechazados)]
    GLD[(Gold<br/>estrella + resumen SQL)]

    USER --> KESTRA
    KESTRA <--> PG
    KESTRA --> PY
    TLC -->|HTTPS| PY
    PY -->|PUT + COPY INTO| STAGE --> RAW
    KESTRA --> DBT
    RAW --> DBT --> BRZ --> SLV --> GLD
    GLD -->|SELECT mensual| KESTRA
```

## Flujo Kestra

```mermaid
flowchart TD
    A[bootstrap_snowflake]
    B[ingest_yellow_taxi]
    C[dbt_build]
    D[gold_sql_summary]

    A -->|éxito| B
    B -->|éxito| C
    C -->|modelos y tests correctos| D
```

El archivo declarativo del flujo es
`kestra/flows/main_lab.semana07.nyc_yellow_taxi_elt.yml`. Compose monta esa carpeta
en modo de solo lectura y Kestra la carga al iniciar mediante `--flow-path`, por lo
que la orquestación queda versionada junto al código sin permitir que la interfaz
modifique los archivos del repositorio.
