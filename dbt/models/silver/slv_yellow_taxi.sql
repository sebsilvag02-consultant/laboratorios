select
    trip_key,
    vendor_id,
    pickup_at,
    dropoff_at,
    passenger_count,
    trip_distance,
    rate_code_id,
    store_and_fwd_flag,
    pickup_location_id,
    dropoff_location_id,
    payment_type_id,
    fare_amount,
    extra_amount,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    source_file,
    source_period,
    source_row_number,
    loaded_at
from {{ ref('int_yellow_taxi_typed') }}
where technical_duplicate_rank = 1
  and rejection_reason is null
