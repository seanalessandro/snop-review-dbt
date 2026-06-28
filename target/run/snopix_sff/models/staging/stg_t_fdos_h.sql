
  create view "logistic"."dwh_staging"."stg_t_fdos_h__dbt_tmp"
    
    
  as (
    -- FDOS plan header. Period-level (no week dimension): aggregated by submit
-- (year_upload, period_upload) + period. sub_id -> distributor channel.
select
    year_upload,
    period_upload,
    period,
    pcode,
    sub_id,
    cast(qty_adj as numeric) as qty_adj
from "logistic"."logistic"."t_fdos_h"
  );