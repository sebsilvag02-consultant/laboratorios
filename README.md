# Laboratorio Integrador I — NYC Yellow Taxi ELT

Tubería ELT orquestada con **Kestra** que descarga NYC Yellow Taxi, conserva los
datos originales en Snowflake y ejecuta transformaciones dbt Bronze → Silver → Gold.
El resultado final es una tabla y una consulta SQL de resumen; no se exportan CSV.

## Arquitectura

Kestra ejecuta secuencialmente el flujo `lab.semana07.nyc_yellow_taxi_elt`:

1. `bootstrap_snowflake`: crea warehouse, base, esquemas, stages y tablas raw.
2. `ingest_yellow_taxi`: descarga y carga los Parquet y el catálogo de zonas.
3. `dbt_build`: construye y prueba Bronze, Silver y Gold dentro de Snowflake.
4. `gold_sql_summary`: consulta `GOLD.RPT_MONTHLY_TRIP_SUMMARY` y deja el resultado
   visible en la ejecución de Kestra.

Los diagramas están en [docs/architecture.md](docs/architecture.md) y
[docs/star-schema.md](docs/star-schema.md).

Los diccionarios de datos por capa están junto a sus modelos dbt:

- [Bronze](dbt/models/bronze/DATA_DICTIONARY.md)
- [Silver](dbt/models/silver/DATA_DICTIONARY.md)
- [Gold](dbt/models/gold/DATA_DICTIONARY.md)

## Requisitos

- Docker Desktop con Docker Compose.
- Cuenta Snowflake y un usuario capaz de crear warehouse, base y esquemas.
- PowerShell para preparar los secretos de Kestra OSS sin escribirlos en el repo.

## Configuración

Si todavía no existe `.env`:

```powershell
Copy-Item .env.example .env
```

Complete como mínimo:

```dotenv
SNOWFLAKE_ACCOUNT=organizacion-cuenta
SNOWFLAKE_USER=usuario
SNOWFLAKE_PASSWORD=contrasena
SNOWFLAKE_ROLE=SYSADMIN
SNOWFLAKE_WAREHOUSE=NYC_TAXI_WH
SNOWFLAKE_DATABASE=NYC_TAXI
TAXI_START_MONTH=2025-01
TAXI_END_MONTH=2026-08
KESTRA_ADMIN_EMAIL=admin@localhost.dev
KESTRA_ADMIN_PASSWORD=KestraLab2026!
```

`.env` está excluido de Git. El script de arranque codifica los valores en memoria
como variables `SECRET_*`, que es el mecanismo de secretos de Kestra Open Source.
No genera archivos con credenciales.

## Levantar Kestra

```powershell
.\scripts\start-kestra.ps1
```

El script:

- valida `.env`;
- construye `nyc-taxi-elt:local`, la imagen usada por las tareas Python y dbt;
- inicia PostgreSQL y Kestra;
- carga automáticamente al iniciar el flujo versionado en `kestra/flows/`.

Abra <http://localhost:8080> e inicie sesión con `KESTRA_ADMIN_EMAIL` y
`KESTRA_ADMIN_PASSWORD`. Luego ingrese al namespace `lab.semana07`, seleccione
`nyc_yellow_taxi_elt` y pulse **Execute**. Las credenciales predeterminadas son
solo para desarrollo local y deben cambiarse fuera del laboratorio. El schedule
mensual está incluido pero deshabilitado para evitar ejecuciones o costos
accidentales.

Para revisar el estado:

```powershell
docker compose ps
docker compose logs -f kestra
```

Para detener la infraestructura sin borrar los datos descargados ni la metadata:

```powershell
docker compose down
```

No use `down --volumes` salvo que desee borrar el historial local de Kestra, su
metadatabase y la caché de Parquet.

## Disponibilidad de agosto de 2026

La ingesta verifica todos los archivos antes de cargar datos. Al 28 de septiembre
de 2026, julio está disponible y agosto responde HTTP 403. Para probar el pipeline
puede utilizar temporalmente `TAXI_END_MONTH=2026-07`; la entrega final debe volver
a `2026-08` cuando TLC publique el archivo.

## Idempotencia

- Cada período se elimina y vuelve a cargar en una transacción Snowflake.
- El catálogo de zonas se reemplaza completo.
- La identidad técnica `TRIP_KEY` se deriva de archivo y número de fila.
- Silver y Gold son reconstruidos por `dbt build`, sin acumulación de duplicados.
- Una ejecución interrumpida puede reanudarse ejecutando otra vez el flujo Kestra.

## Calidad en Silver

- conversión explícita de tipos y nombres `snake_case`;
- conversión de timestamps Unix en microsegundos con escala `6`, tal como llegan
  desde los Parquet al `VARIANT` de Snowflake;
- normalización del indicador `store_and_fwd_flag`;
- deduplicación por archivo y número de fila;
- separación de registros inválidos en `SILVER.SLV_YELLOW_TAXI_REJECTED`;
- conservación de nulos cuyo significado real es “desconocido”;
- rechazo de fechas fuera del período fuente, duraciones, distancias, ubicaciones
  o pasajeros imposibles;
- pruebas dbt `not_null`, `unique` y `relationships`.
- prueba singular que impide aprobar una capa Gold vacía.

## Ejecución verificada

El 28 de septiembre de 2026 se ejecutó el flujo completo dos veces para verificar
la idempotencia. La ejecución final de Kestra `5nTqyF5B99QZ6tAogckRFI` terminó en
`SUCCESS` en 10 minutos y 32 segundos, con las cuatro tareas exitosas al primer
intento. Para los 19 archivos actualmente publicados se obtuvieron:

- 75,089,241 filas originales en Bronze;
- 75,083,502 viajes válidos en Silver y Gold;
- 5,739 registros conservados en la tabla de rechazados;
- 19 filas en el resumen mensual Gold;
- 51 pruebas dbt aprobadas, sin warnings ni errores.

Cuando TLC publique agosto de 2026, cambie `TAXI_END_MONTH` a `2026-08` y vuelva a
ejecutar el mismo flujo para completar los 20 meses exigidos.

## Resultado Gold en SQL

El modelo [rpt_monthly_trip_summary.sql](dbt/models/gold/rpt_monthly_trip_summary.sql)
crea `GOLD.RPT_MONTHLY_TRIP_SUMMARY`. La consulta entregable está en
[gold_trip_summary.sql](sql/gold_trip_summary.sql):

```sql
SELECT *
FROM NYC_TAXI.GOLD.RPT_MONTHLY_TRIP_SUMMARY
ORDER BY SOURCE_PERIOD;
```

El grano de `FCT_TRIPS` es un viaje válido por fila de archivo fuente. El resumen
Gold tiene una fila por mes y presenta viajes, pasajeros, distancia, duración,
tarifas, propinas e ingreso total.
