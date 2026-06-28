
  create view "logistic"."dwh_staging"."stg_t_salfo_confirm_d__dbt_tmp"
    
    
  as (
    -- SALFO confirmations (partitioned). Keyed by upload (year_upload, period_upload)
-- and by calendar (year, week). sub_id -> distributor channel.
select
    year_upload,
    period_upload,
    year,
    week,
    pcode,
    sub_id,
    cast(qty as numeric) as qty
from "logistic"."logistic"."t_salfo_confirm_d"
  );