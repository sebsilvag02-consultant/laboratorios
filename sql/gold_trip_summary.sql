-- Resultado analítico final del laboratorio. No exporta archivos CSV.
select
    source_period,
    trip_count,
    total_passengers,
    total_distance,
    average_trip_minutes,
    total_fare_amount,
    total_tip_amount,
    total_revenue
from NYC_TAXI.GOLD.RPT_MONTHLY_TRIP_SUMMARY
order by source_period;
