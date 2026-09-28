select 1 as failure
where not exists (
    select 1
    from {{ ref('rpt_monthly_trip_summary') }}
)
