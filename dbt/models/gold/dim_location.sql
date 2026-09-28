with observed_locations as (
    select pickup_location_id as location_id from {{ ref('slv_yellow_taxi') }}
    union
    select dropoff_location_id as location_id from {{ ref('slv_yellow_taxi') }}
),

all_locations as (
    select
        observed.location_id,
        zones.borough,
        zones.zone_name,
        zones.service_zone
    from observed_locations observed
    left join {{ ref('slv_taxi_zones') }} zones using (location_id)
)

select
    -1 as location_key,
    'Unknown' as borough,
    'Unknown' as zone_name,
    'Unknown' as service_zone
union all
select
    location_id as location_key,
    coalesce(borough, 'Unknown') as borough,
    coalesce(zone_name, 'Location ' || location_id::varchar) as zone_name,
    coalesce(service_zone, 'Unknown') as service_zone
from all_locations
