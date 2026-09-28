{{ config(materialized='ephemeral') }}

with normalized as (
    select
        sha2(source_file || '|' || source_row_number::varchar, 256) as trip_key,
        vendor_id,
        pickup_at,
        dropoff_at,
        passenger_count,
        trip_distance,
        rate_code_id,
        case
            when upper(trim(store_and_fwd_flag)) in ('Y', 'N')
                then upper(trim(store_and_fwd_flag))
        end as store_and_fwd_flag,
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
        loaded_at,
        row_number() over (
            partition by source_file, source_row_number
            order by loaded_at desc
        ) as technical_duplicate_rank
    from {{ ref('brz_yellow_taxi') }}
),

validated as (
    select
        *,
        case
            when pickup_at is null then 'pickup_at is null'
            when dropoff_at is null then 'dropoff_at is null'
            when pickup_at < '2025-01-01'::timestamp_ntz
                or pickup_at >= '2027-01-01'::timestamp_ntz
                then 'pickup_at is outside the assignment range'
            when to_char(pickup_at, 'YYYY-MM') <> source_period
                then 'pickup_at does not match source period'
            when dropoff_at < pickup_at then 'dropoff_at precedes pickup_at'
            when datediff('hour', pickup_at, dropoff_at) > 24 then 'trip duration exceeds 24 hours'
            when trip_distance is null or trip_distance < 0 or trip_distance > 1000
                then 'trip_distance is invalid'
            when pickup_location_id is null or pickup_location_id <= 0
                then 'pickup_location_id is invalid'
            when dropoff_location_id is null or dropoff_location_id <= 0
                then 'dropoff_location_id is invalid'
            when passenger_count < 0 or passenger_count > 20
                then 'passenger_count is invalid'
        end as rejection_reason
    from normalized
)

select * from validated
