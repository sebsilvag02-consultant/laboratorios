with minutes as (
    select row_number() over (order by seq4()) - 1 as minute_of_day
    from table(generator(rowcount => 1440))
)

select
    floor(minute_of_day / 60) * 100 + mod(minute_of_day, 60) as time_key,
    floor(minute_of_day / 60) as hour_number,
    mod(minute_of_day, 60) as minute_number,
    case
        when hour_number between 5 and 11 then 'Morning'
        when hour_number between 12 and 16 then 'Afternoon'
        when hour_number between 17 and 20 then 'Evening'
        else 'Night'
    end as day_part
from minutes
