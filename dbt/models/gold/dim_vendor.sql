with vendors as (
    select distinct vendor_id
    from {{ ref('slv_yellow_taxi') }}
    where vendor_id is not null
)

select -1 as vendor_key, 'Unknown' as vendor_name
union all
select
    vendor_id as vendor_key,
    case vendor_id
        when 1 then 'Creative Mobile Technologies'
        when 2 then 'Curb Mobility'
        when 6 then 'Myle Technologies'
        when 7 then 'Helix'
        else 'Vendor ' || vendor_id::varchar
    end as vendor_name
from vendors
