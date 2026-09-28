with payment_types as (
    select distinct payment_type_id
    from {{ ref('slv_yellow_taxi') }}
    where payment_type_id is not null
)

select -1 as payment_type_key, 'Unknown' as payment_type_name
union all
select
    payment_type_id as payment_type_key,
    case payment_type_id
        when 0 then 'Flex Fare trip'
        when 1 then 'Credit card'
        when 2 then 'Cash'
        when 3 then 'No charge'
        when 4 then 'Dispute'
        when 5 then 'Unknown'
        when 6 then 'Voided trip'
        else 'Payment type ' || payment_type_id::varchar
    end as payment_type_name
from payment_types
