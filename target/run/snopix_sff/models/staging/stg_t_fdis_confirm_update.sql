
  create view "logistic"."dwh_staging"."stg_t_fdis_confirm_update__dbt_tmp"
    
    
  as (
    -- FDIS confirm update. Per-week value = day1+..+day6. Channel-AGNOSTIC.
-- flag_proc = 1 only. Keyed by upload + calendar.
select
    year_upload,
    period_upload,
    flag_proc,
    year,
    week,
    pcode,
    cast(day1 as numeric) as day1,
    cast(day2 as numeric) as day2,
    cast(day3 as numeric) as day3,
    cast(day4 as numeric) as day4,
    cast(day5 as numeric) as day5,
    cast(day6 as numeric) as day6
from "logistic"."logistic"."t_fdis_confirm_update"
  );