with rate_codes as (
    select distinct rate_code_id
    from {{ ref('slv_yellow_taxi') }}
    where rate_code_id is not null
)

select -1 as rate_code_key, 'Unknown' as rate_code_name
union all
select
    rate_code_id as rate_code_key,
    case rate_code_id
        when 1 then 'Standard rate'
        when 2 then 'JFK'
        when 3 then 'Newark'
        when 4 then 'Nassau or Westchester'
        when 5 then 'Negotiated fare'
        when 6 then 'Group ride'
        when 99 then 'Null or unknown'
        else 'Rate code ' || rate_code_id::varchar
    end as rate_code_name
from rate_codes
