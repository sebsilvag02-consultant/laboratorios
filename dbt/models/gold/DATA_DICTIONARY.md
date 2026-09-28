# Diccionario de datos — Gold

La capa Gold implementa un esquema estrella para analizar los viajes. Todos los
modelos se materializan como tablas en `NYC_TAXI.GOLD`.

## `FCT_TRIPS`

**Grano:** un viaje Yellow Taxi válido y deduplicado por fila de archivo fuente.

**Clave primaria lógica:** `TRIP_KEY`.

| Columna | Rol / tipo lógico | Descripción |
|---|---|---|
| `TRIP_KEY` | PK, `VARCHAR(64)` | Identificador único del viaje. |
| `VENDOR_KEY` | FK → `DIM_VENDOR` | Proveedor que transmitió el registro. |
| `PICKUP_DATE_KEY` | FK → `DIM_DATE` | Fecha de inicio en formato numérico `YYYYMMDD`. |
| `PICKUP_TIME_KEY` | FK → `DIM_TIME` | Hora y minuto de inicio en formato numérico `HHMM`. |
| `DROPOFF_DATE_KEY` | FK → `DIM_DATE` | Fecha de finalización en formato `YYYYMMDD`. |
| `DROPOFF_TIME_KEY` | FK → `DIM_TIME` | Hora y minuto de finalización en formato `HHMM`. |
| `PICKUP_LOCATION_KEY` | FK → `DIM_LOCATION` | Zona TLC de origen. |
| `DROPOFF_LOCATION_KEY` | FK → `DIM_LOCATION` | Zona TLC de destino. |
| `RATE_CODE_KEY` | FK → `DIM_RATE_CODE` | Tarifa aplicada al viaje. |
| `PAYMENT_TYPE_KEY` | FK → `DIM_PAYMENT_TYPE` | Método de pago. |
| `PASSENGER_COUNT` | `NUMBER` | Número de pasajeros informado. |
| `TRIP_DISTANCE` | `FLOAT` | Distancia del viaje en millas. |
| `TRIP_DURATION_SECONDS` | `NUMBER` | Duración calculada entre inicio y fin, en segundos. |
| `FARE_AMOUNT` | `NUMBER(18,2)` | Tarifa base, en USD. |
| `EXTRA_AMOUNT` | `NUMBER(18,2)` | Recargos adicionales, en USD. |
| `MTA_TAX` | `NUMBER(18,2)` | Impuesto MTA, en USD. |
| `TIP_AMOUNT` | `NUMBER(18,2)` | Propina electrónica registrada, en USD. |
| `TOLLS_AMOUNT` | `NUMBER(18,2)` | Peajes, en USD. |
| `IMPROVEMENT_SURCHARGE` | `NUMBER(18,2)` | Recargo de mejora, en USD. |
| `TOTAL_AMOUNT` | `NUMBER(18,2)` | Importe total registrado, en USD. |
| `CONGESTION_SURCHARGE` | `NUMBER(18,2)` | Recargo por congestión, en USD. |
| `AIRPORT_FEE` | `NUMBER(18,2)` | Tarifa aeroportuaria, en USD. |
| `CBD_CONGESTION_FEE` | `NUMBER(18,2)` | Tarifa de congestión del distrito central, en USD. |
| `STORE_AND_FWD_FLAG` | `VARCHAR(1)` | Indicador normalizado `Y`, `N` o nulo. |
| `SOURCE_FILE` | `VARCHAR` | Archivo Parquet de origen. |
| `SOURCE_PERIOD` | `VARCHAR(7)` | Mes de origen en formato `YYYY-MM`. |
| `LOADED_AT` | `TIMESTAMP_TZ` | Fecha y hora de carga del registro fuente. |

Las claves `VENDOR_KEY`, `RATE_CODE_KEY` y `PAYMENT_TYPE_KEY` usan `-1` cuando el
valor fuente es nulo. Cada dimensión contiene la fila `-1 = Unknown`.

## `DIM_DATE`

**Grano:** una fila por fecha presente en el inicio o fin de los viajes.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `DATE_KEY` | PK, `NUMBER` | Fecha en formato numérico `YYYYMMDD`. |
| `CALENDAR_DATE` | `DATE` | Fecha calendario. |
| `YEAR_NUMBER` | `NUMBER` | Año. |
| `QUARTER_NUMBER` | `NUMBER` | Trimestre, de 1 a 4. |
| `MONTH_NUMBER` | `NUMBER` | Mes, de 1 a 12. |
| `MONTH_NAME` | `VARCHAR` | Nombre abreviado del mes generado por Snowflake. |
| `ISO_WEEK_NUMBER` | `NUMBER` | Número de semana según ISO-8601. |
| `ISO_DAY_OF_WEEK` | `NUMBER` | Día ISO: 1 lunes a 7 domingo. |
| `DAY_NAME` | `VARCHAR` | Nombre abreviado del día generado por Snowflake. |
| `IS_WEEKEND` | `BOOLEAN` | Verdadero para sábado o domingo. |

## `DIM_TIME`

**Grano:** un minuto del día; contiene 1.440 filas.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `TIME_KEY` | PK, `NUMBER` | Hora y minuto en formato numérico `HHMM`; por ejemplo, `930` representa 09:30. |
| `HOUR_NUMBER` | `NUMBER` | Hora, de 0 a 23. |
| `MINUTE_NUMBER` | `NUMBER` | Minuto, de 0 a 59. |
| `DAY_PART` | `VARCHAR` | Franja: `Morning`, `Afternoon`, `Evening` o `Night`. |

## `DIM_VENDOR`

**Grano:** un proveedor observado, más la fila desconocida.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `VENDOR_KEY` | PK, `NUMBER` | Código del proveedor; `-1` significa desconocido. |
| `VENDOR_NAME` | `VARCHAR` | Nombre descriptivo del proveedor. |

| `VENDOR_KEY` | `VENDOR_NAME` |
|---:|---|
| `-1` | Unknown |
| `1` | Creative Mobile Technologies |
| `2` | Curb Mobility |
| `6` | Myle Technologies |
| `7` | Helix |

Los códigos no catalogados se muestran como `Vendor <código>`.

## `DIM_PAYMENT_TYPE`

**Grano:** un tipo de pago observado, más la fila desconocida.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `PAYMENT_TYPE_KEY` | PK, `NUMBER` | Código del método de pago; `-1` significa desconocido. |
| `PAYMENT_TYPE_NAME` | `VARCHAR` | Nombre descriptivo del método. |

| Clave | Nombre |
|---:|---|
| `-1` | Unknown |
| `0` | Flex Fare trip |
| `1` | Credit card |
| `2` | Cash |
| `3` | No charge |
| `4` | Dispute |
| `5` | Unknown |
| `6` | Voided trip |

## `DIM_RATE_CODE`

**Grano:** un código de tarifa observado, más la fila desconocida.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `RATE_CODE_KEY` | PK, `NUMBER` | Código de tarifa; `-1` significa desconocido. |
| `RATE_CODE_NAME` | `VARCHAR` | Nombre descriptivo de la tarifa. |

| Clave | Nombre |
|---:|---|
| `-1` | Unknown |
| `1` | Standard rate |
| `2` | JFK |
| `3` | Newark |
| `4` | Nassau or Westchester |
| `5` | Negotiated fare |
| `6` | Group ride |
| `99` | Null or unknown |

## `DIM_LOCATION`

**Grano:** una zona TLC observada como origen o destino, más la fila desconocida.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `LOCATION_KEY` | PK, `NUMBER` | Identificador de la zona TLC; `-1` significa desconocido. |
| `BOROUGH` | `VARCHAR` | Borough o distrito. |
| `ZONE_NAME` | `VARCHAR` | Nombre de la zona. Si falta en el catálogo se usa `Location <id>`. |
| `SERVICE_ZONE` | `VARCHAR` | Categoría de servicio; `Unknown` cuando no está disponible. |

## `RPT_MONTHLY_TRIP_SUMMARY`

**Grano:** una fila por mes de origen.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `SOURCE_PERIOD` | `VARCHAR(7)` | Mes analizado en formato `YYYY-MM`. |
| `TRIP_COUNT` | `NUMBER` | Cantidad de viajes válidos del mes. |
| `TOTAL_PASSENGERS` | `NUMBER` | Suma de pasajeros; los nulos se tratan como cero solo para esta métrica. |
| `TOTAL_DISTANCE` | `NUMBER` | Distancia total en millas, redondeada a dos decimales. |
| `AVERAGE_TRIP_MINUTES` | `NUMBER` | Duración promedio en minutos, redondeada a dos decimales. |
| `TOTAL_FARE_AMOUNT` | `NUMBER` | Suma de tarifas base en USD, redondeada a dos decimales. |
| `TOTAL_TIP_AMOUNT` | `NUMBER` | Suma de propinas registradas en USD, redondeada a dos decimales. |
| `TOTAL_REVENUE` | `NUMBER` | Suma de `TOTAL_AMOUNT` en USD, redondeada a dos decimales. |

Consulta recomendada:

```sql
SELECT *
FROM NYC_TAXI.GOLD.RPT_MONTHLY_TRIP_SUMMARY
ORDER BY SOURCE_PERIOD;
```
