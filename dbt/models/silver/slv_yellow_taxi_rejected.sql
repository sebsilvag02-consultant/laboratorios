select
    trip_key,
    source_file,
    source_period,
    source_row_number,
    loaded_at,
    technical_duplicate_rank > 1 as is_technical_duplicate,
    coalesce(
        rejection_reason,
        iff(technical_duplicate_rank > 1, 'duplicate source row', null)
    ) as rejection_reason
from {{ ref('int_yellow_taxi_typed') }}
where technical_duplicate_rank > 1
   or rejection_reason is not null
