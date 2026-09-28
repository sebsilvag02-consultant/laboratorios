with dates as (
    select pickup_at::date as calendar_date from {{ ref('slv_yellow_taxi') }}
    union
    select dropoff_at::date as calendar_date from {{ ref('slv_yellow_taxi') }}
)

select
    to_number(to_char(calendar_date, 'YYYYMMDD')) as date_key,
    calendar_date,
    year(calendar_date) as year_number,
    quarter(calendar_date) as quarter_number,
    month(calendar_date) as month_number,
    monthname(calendar_date) as month_name,
    weekiso(calendar_date) as iso_week_number,
    dayofweekiso(calendar_date) as iso_day_of_week,
    dayname(calendar_date) as day_name,
    dayofweekiso(calendar_date) in (6, 7) as is_weekend
from dates
