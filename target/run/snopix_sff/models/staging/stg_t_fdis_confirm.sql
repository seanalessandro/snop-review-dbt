
  create view "logistic"."dwh_staging"."stg_t_fdis_confirm__dbt_tmp"
    
    
  as (
    -- FDIS confirm. Channel-AGNOSTIC (no distributor/warehouse filter in Java).
-- Keyed by upload + calendar.
select
    year_upload,
    period_upload,
    year,
    week,
    pcode,
    cast(qty as numeric) as qty
from "logistic"."logistic"."t_fdis_confirm"
  );