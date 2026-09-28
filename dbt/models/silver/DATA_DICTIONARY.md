# Diccionario de datos — Silver

La capa Silver tipa, normaliza, deduplica y valida los registros de Bronze. Los
modelos públicos se materializan como tablas en `NYC_TAXI.SILVER`.

## Reglas de calidad

Un registro se conserva en `SLV_YELLOW_TAXI` cuando es la versión más reciente de
la fila fuente y cumple todas estas condiciones:

- `PICKUP_AT` y `DROPOFF_AT` no son nulos.
- `PICKUP_AT` pertenece al rango del laboratorio y coincide con `SOURCE_PERIOD`.
- `DROPOFF_AT` no es anterior a `PICKUP_AT`.
- La duración no supera 24 horas.
- `TRIP_DISTANCE` está entre 0 y 1.000 millas.
- Las ubicaciones de origen y destino son números positivos.
- Cuando existe, `PASSENGER_COUNT` está entre 0 y 20.
- No existe otra fila más reciente con el mismo `SOURCE_FILE` y
  `SOURCE_ROW_NUMBER`.

Los valores de `STORE_AND_FWD_FLAG` se normalizan a `Y` o `N`; cualquier otro
valor se convierte en nulo. Los registros que incumplen las reglas se conservan
en `SLV_YELLOW_TAXI_REJECTED` para auditoría.

## `SLV_YELLOW_TAXI`

**Grano:** un viaje válido y deduplicado por fila de archivo fuente.

**Clave primaria lógica:** `TRIP_KEY`.

| Columna | Tipo lógico | Nulos | Descripción |
|---|---|---:|---|
| `TRIP_KEY` | `VARCHAR(64)` | No | Identificador SHA-256 derivado de `SOURCE_FILE + SOURCE_ROW_NUMBER`. |
| `VENDOR_ID` | `NUMBER` | Sí | Código del proveedor del registro. |
| `PICKUP_AT` | `TIMESTAMP_NTZ` | No | Fecha y hora de inicio del viaje. |
| `DROPOFF_AT` | `TIMESTAMP_NTZ` | No | Fecha y hora de finalización del viaje. |
| `PASSENGER_COUNT` | `NUMBER` | Sí | Número de pasajeros informado; un nulo significa desconocido. |
| `TRIP_DISTANCE` | `FLOAT` | No | Distancia válida del viaje, en millas. |
| `RATE_CODE_ID` | `NUMBER` | Sí | Código de tarifa. |
| `STORE_AND_FWD_FLAG` | `VARCHAR(1)` | Sí | `Y` si el registro fue almacenado antes de enviarse; `N` si se transmitió normalmente. |
| `PICKUP_LOCATION_ID` | `NUMBER` | No | Identificador TLC de la zona de origen. |
| `DROPOFF_LOCATION_ID` | `NUMBER` | No | Identificador TLC de la zona de destino. |
| `PAYMENT_TYPE_ID` | `NUMBER` | Sí | Código del método de pago. |
| `FARE_AMOUNT` | `NUMBER(18,2)` | Sí | Tarifa base, en USD. |
| `EXTRA_AMOUNT` | `NUMBER(18,2)` | Sí | Recargos adicionales, en USD. |
| `MTA_TAX` | `NUMBER(18,2)` | Sí | Impuesto MTA, en USD. |
| `TIP_AMOUNT` | `NUMBER(18,2)` | Sí | Propina electrónica registrada, en USD. |
| `TOLLS_AMOUNT` | `NUMBER(18,2)` | Sí | Peajes, en USD. |
| `IMPROVEMENT_SURCHARGE` | `NUMBER(18,2)` | Sí | Recargo de mejora, en USD. |
| `TOTAL_AMOUNT` | `NUMBER(18,2)` | Sí | Importe total registrado, en USD. |
| `CONGESTION_SURCHARGE` | `NUMBER(18,2)` | Sí | Recargo por congestión, en USD. |
| `AIRPORT_FEE` | `NUMBER(18,2)` | Sí | Tarifa aeroportuaria, en USD. |
| `CBD_CONGESTION_FEE` | `NUMBER(18,2)` | Sí | Tarifa de congestión del distrito central, en USD. |
| `SOURCE_FILE` | `VARCHAR` | No | Archivo Parquet de origen. |
| `SOURCE_PERIOD` | `VARCHAR(7)` | No | Periodo de origen en formato `YYYY-MM`. |
| `SOURCE_ROW_NUMBER` | `NUMBER` | No | Número de fila en el archivo fuente. |
| `LOADED_AT` | `TIMESTAMP_TZ` | No | Fecha y hora de carga. |

### Códigos de `VENDOR_ID`

| Código | Significado |
|---:|---|
| `1` | Creative Mobile Technologies |
| `2` | Curb Mobility |
| `6` | Myle Technologies |
| `7` | Helix |
| Otro | Proveedor no catalogado; se presenta como `Vendor <código>` en Gold. |

### Códigos de `PAYMENT_TYPE_ID`

| Código | Significado |
|---:|---|
| `0` | Flex Fare trip |
| `1` | Tarjeta de crédito |
| `2` | Efectivo |
| `3` | Sin cargo |
| `4` | Disputa |
| `5` | Desconocido |
| `6` | Viaje anulado |

### Códigos de `RATE_CODE_ID`

| Código | Significado |
|---:|---|
| `1` | Tarifa estándar |
| `2` | JFK |
| `3` | Newark |
| `4` | Nassau o Westchester |
| `5` | Tarifa negociada |
| `6` | Viaje grupal |
| `99` | Nulo o desconocido en la fuente |

## `SLV_TAXI_ZONES`

**Grano:** una fila por `LOCATION_ID`.

**Clave primaria lógica:** `LOCATION_ID`.

| Columna | Tipo lógico | Nulos | Descripción |
|---|---|---:|---|
| `LOCATION_ID` | `NUMBER` | No | Identificador único de la zona TLC. |
| `BOROUGH` | `VARCHAR` | Sí | Borough normalizado; cadenas vacías se convierten en nulo. |
| `ZONE_NAME` | `VARCHAR` | Sí | Nombre normalizado de la zona; cadenas vacías se convierten en nulo. |
| `SERVICE_ZONE` | `VARCHAR` | Sí | Categoría de servicio normalizada. |

## `SLV_YELLOW_TAXI_REJECTED`

**Grano:** una fila por registro rechazado o duplicado técnico.

| Columna | Tipo lógico | Descripción |
|---|---|---|
| `TRIP_KEY` | `VARCHAR(64)` | Identificador técnico del registro. |
| `SOURCE_FILE` | `VARCHAR` | Archivo de origen. |
| `SOURCE_PERIOD` | `VARCHAR(7)` | Periodo de origen en formato `YYYY-MM`. |
| `SOURCE_ROW_NUMBER` | `NUMBER` | Número de fila en el archivo fuente. |
| `LOADED_AT` | `TIMESTAMP_TZ` | Fecha y hora de carga. |
| `IS_TECHNICAL_DUPLICATE` | `BOOLEAN` | Verdadero cuando existe una versión más reciente de la misma fila fuente. |
| `REJECTION_REASON` | `VARCHAR` | Primera regla de calidad incumplida o `duplicate source row`. |

## Modelo interno `INT_YELLOW_TAXI_TYPED`

Es un modelo dbt `ephemeral`: participa en la transformación, pero no crea una
tabla física consultable en Snowflake. Calcula `TRIP_KEY`, normaliza
`STORE_AND_FWD_FLAG`, asigna el rango de duplicado y determina
`REJECTION_REASON`.
