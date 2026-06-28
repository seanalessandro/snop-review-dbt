
  create view "logistic"."dwh_staging"."stg_m_cycle2__dbt_tmp"
    
    
  as (
    -- Period/week calendar. Drives period-week membership, the trailing 13w/5w
-- moving-average windows, and the previous-period (upload key) lookup.
select
    year,
    period,
    week
from "logistic"."logistic"."m_cycle2"
  );