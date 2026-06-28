
  create view "logistic"."dwh_staging"."stg_t_upload_mps__dbt_tmp"
    
    
  as (
    -- MPS uploads. Channel-AGNOSTIC. flag_proc = 1 only. Keyed by upload + calendar.
select
    year_upload,
    period_upload,
    flag_proc,
    year,
    week,
    pcode,
    cast(qty_adj as numeric) as qty_adj
from "logistic"."logistic"."t_upload_mps"
  );