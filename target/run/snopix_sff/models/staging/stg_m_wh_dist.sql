
  create view "logistic"."dwh_staging"."stg_m_wh_dist__dbt_tmp"
    
    
  as (
    -- Warehouse <-> distributor mapping. Joined to m_distributor to derive the
-- warehouse channel set for the warehouse-keyed metrics (sta, std, fdis upd, stock ibn).
select
    distributor_id,
    wh_id
from "logistic"."logistic"."m_wh_dist"
where wh_id is not null and wh_id <> ''
  );