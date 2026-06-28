
  create view "logistic"."dwh_staging"."stg_m_distributor__dbt_tmp"
    
    
  as (
    -- Distributor -> channel (sls_div = 'GT' | 'MT'). Channel filter for the
-- distributor-keyed metrics (salfo, fdos plan/upd, stock dist).
select
    distributor_id,
    sls_div
from "logistic"."logistic"."m_distributor"
  );