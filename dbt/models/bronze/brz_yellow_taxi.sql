select
    raw_record,
    raw_record:"VendorID"::number as vendor_id,
    to_timestamp_ntz(
        raw_record:"tpep_pickup_datetime"::number,
        6
    ) as pickup_at,
    to_timestamp_ntz(
        raw_record:"tpep_dropoff_datetime"::number,
        6
    ) as dropoff_at,
    raw_record:"passenger_count"::number as passenger_count,
    raw_record:"trip_distance"::float as trip_distance,
    raw_record:"RatecodeID"::number as rate_code_id,
    raw_record:"store_and_fwd_flag"::varchar as store_and_fwd_flag,
    raw_record:"PULocationID"::number as pickup_location_id,
    raw_record:"DOLocationID"::number as dropoff_location_id,
    raw_record:"payment_type"::number as payment_type_id,
    raw_record:"fare_amount"::number(18, 2) as fare_amount,
    raw_record:"extra"::number(18, 2) as extra_amount,
    raw_record:"mta_tax"::number(18, 2) as mta_tax,
    raw_record:"tip_amount"::number(18, 2) as tip_amount,
    raw_record:"tolls_amount"::number(18, 2) as tolls_amount,
    raw_record:"improvement_surcharge"::number(18, 2) as improvement_surcharge,
    raw_record:"total_amount"::number(18, 2) as total_amount,
    raw_record:"congestion_surcharge"::number(18, 2) as congestion_surcharge,
    coalesce(
        raw_record:"Airport_fee"::number(18, 2),
        raw_record:"airport_fee"::number(18, 2)
    ) as airport_fee,
    raw_record:"cbd_congestion_fee"::number(18, 2) as cbd_congestion_fee,
    source_file,
    source_period,
    source_row_number,
    loaded_at
from {{ source('raw_nyc_taxi', 'raw_yellow_taxi') }}
