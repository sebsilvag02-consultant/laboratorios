select
    location_id,
    nullif(trim(borough), '') as borough,
    nullif(trim(zone), '') as zone_name,
    nullif(trim(service_zone), '') as service_zone
from {{ ref('brz_taxi_zones') }}
where location_id is not null
qualify row_number() over (
    partition by location_id
    order by loaded_at desc
) = 1
