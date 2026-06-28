
  create view "logistic"."dwh_staging"."stg_t_omset__dbt_tmp"
    
    
  as (
    -- STA actuals. Warehouse-keyed (wh_id -> channel).
select
    year,
    week,
    wh_id,
    pcode,
    cast(qty_omset as numeric) as qty_omset
from "logistic"."logistic"."t_omset"
  );