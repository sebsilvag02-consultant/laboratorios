select
    source_period,
    count(*) as trip_count,
    sum(coalesce(passenger_count, 0)) as total_passengers,
    round(sum(trip_distance), 2) as total_distance,
    round(avg(trip_duration_seconds) / 60, 2) as average_trip_minutes,
    round(sum(fare_amount), 2) as total_fare_amount,
    round(sum(tip_amount), 2) as total_tip_amount,
    round(sum(total_amount), 2) as total_revenue
from {{ ref('fct_trips') }}
group by source_period
