# Diccionario de datos — Bronze

La capa Bronze conserva los datos de NYC Yellow Taxi lo más cerca posible de la
fuente. Las tablas `RAW_*` son creadas por el proceso de infraestructura e ingesta;
los modelos `BRZ_*` son vistas dbt que exponen el contenido con nombres y tipos
utilizables en SQL.

Base y esquema predeterminados: `NYC_TAXI.BRONZE`.

## `RAW_YELLOW_TAXI`

**Grano:** una fila por registro de cada archivo Parquet de Yellow Taxi.

| Columna | Tipo Snowflake | Nulos | Descripción |
|---|---|---:|---|
| `RAW_RECORD` | `VARIANT` | No | Registro original del Parquet, sin modificar. |
| `SOURCE_FILE` | `VARCHAR` | No | Nombre del archivo Parquet del que procede el registro. |
| `SOURCE_PERIOD` | `VARCHAR(7)` | No | Mes representado por el archivo, en formato `YYYY-MM`. |
| `SOURCE_ROW_NUMBER` | `NUMBER` | No | Posición de la fila dentro del archivo fuente. |
| `LOADED_AT` | `TIMESTAMP_TZ` | No | Fecha y hora de carga en Snowflake, con zona horaria. |

La combinación `SOURCE_FILE + SOURCE_ROW_NUMBER` identifica establemente una fila
de origen y se utiliza después para construir `TRIP_KEY`.

## `RAW_TAXI_ZONE_LOOKUP`

**Grano:** una fila por ubicación del catálogo TLC Taxi Zone Lookup.

| Columna | Tipo Snowflake | Nulos | Descripción |
|---|---|---:|---|
| `LOCATION_ID` | `NUMBER` | Sí | Identificador numérico de la zona TLC. |
| `BOROUGH` | `VARCHAR` | Sí | Borough o distrito de Nueva York. |
| `ZONE` | `VARCHAR` | Sí | Nombre de la zona TLC. |
| `SERVICE_ZONE` | `VARCHAR` | Sí | Categoría de servicio asignada a la zona. |
| `SOURCE_FILE` | `VARCHAR` | No | Archivo CSV del que procede el registro. |
| `LOADED_AT` | `TIMESTAMP_TZ` | No | Fecha y hora de carga en Snowflake. |

## `BRZ_YELLOW_TAXI`

**Materialización:** vista dbt.

**Grano:** una fila por registro de `RAW_YELLOW_TAXI`. La vista conserva
`RAW_RECORD`, extrae sus atributos y convierte explícitamente sus tipos.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `RAW_RECORD` | `VARIANT` | Registro fuente completo para trazabilidad. |
| `VENDOR_ID` | `NUMBER` | Código del proveedor que envió el registro. |
| `PICKUP_AT` | `TIMESTAMP_NTZ` | Fecha y hora de inicio del viaje. El entero Unix del Parquet se interpreta en microsegundos. |
| `DROPOFF_AT` | `TIMESTAMP_NTZ` | Fecha y hora de finalización del viaje. El entero Unix del Parquet se interpreta en microsegundos. |
| `PASSENGER_COUNT` | `NUMBER` | Número de pasajeros informado por el conductor. |
| `TRIP_DISTANCE` | `FLOAT` | Distancia registrada por el taxímetro, en millas. |
| `RATE_CODE_ID` | `NUMBER` | Código de tarifa vigente al finalizar el viaje. |
| `STORE_AND_FWD_FLAG` | `VARCHAR` | Indicador fuente de almacenamiento y envío posterior. |
| `PICKUP_LOCATION_ID` | `NUMBER` | Zona TLC donde comenzó el viaje. |
| `DROPOFF_LOCATION_ID` | `NUMBER` | Zona TLC donde terminó el viaje. |
| `PAYMENT_TYPE_ID` | `NUMBER` | Código del método de pago. |
| `FARE_AMOUNT` | `NUMBER(18,2)` | Tarifa base calculada por tiempo y distancia, en USD. |
| `EXTRA_AMOUNT` | `NUMBER(18,2)` | Recargos adicionales, en USD. |
| `MTA_TAX` | `NUMBER(18,2)` | Impuesto MTA, en USD. |
| `TIP_AMOUNT` | `NUMBER(18,2)` | Propina registrada electrónicamente, en USD; no representa necesariamente propinas en efectivo. |
| `TOLLS_AMOUNT` | `NUMBER(18,2)` | Total de peajes, en USD. |
| `IMPROVEMENT_SURCHARGE` | `NUMBER(18,2)` | Recargo de mejora, en USD. |
| `TOTAL_AMOUNT` | `NUMBER(18,2)` | Importe total registrado para el viaje, en USD. |
| `CONGESTION_SURCHARGE` | `NUMBER(18,2)` | Recargo por congestión, en USD. |
| `AIRPORT_FEE` | `NUMBER(18,2)` | Tarifa aeroportuaria, en USD. Acepta las variantes de nombre `Airport_fee` y `airport_fee`. |
| `CBD_CONGESTION_FEE` | `NUMBER(18,2)` | Tarifa de congestión del distrito central, en USD. |
| `SOURCE_FILE` | `VARCHAR` | Archivo Parquet de origen. |
| `SOURCE_PERIOD` | `VARCHAR(7)` | Periodo de origen en formato `YYYY-MM`. |
| `SOURCE_ROW_NUMBER` | `NUMBER` | Número de fila dentro del archivo de origen. |
| `LOADED_AT` | `TIMESTAMP_TZ` | Fecha y hora de carga. |

## `BRZ_TAXI_ZONES`

**Materialización:** vista dbt.

**Grano:** una fila del archivo fuente del catálogo de zonas.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `LOCATION_ID` | `NUMBER` | Identificador de la zona TLC. |
| `BOROUGH` | `VARCHAR` | Borough o distrito. |
| `ZONE` | `VARCHAR` | Nombre original de la zona. |
| `SERVICE_ZONE` | `VARCHAR` | Categoría de servicio. |
| `SOURCE_FILE` | `VARCHAR` | Archivo fuente. |
| `LOADED_AT` | `TIMESTAMP_TZ` | Fecha y hora de carga. |
