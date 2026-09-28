select
    location_id,
    borough,
    zone,
    service_zone,
    source_file,
    loaded_at
from {{ source('raw_nyc_taxi', 'raw_taxi_zone_lookup') }}
