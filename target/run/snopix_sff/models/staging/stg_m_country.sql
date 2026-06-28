
  create view "logistic"."dwh_staging"."stg_m_country__dbt_tmp"
    
    
  as (
    -- Country master in the main (logistic) schema.
select
    ct_id,
    ct_nm
from "logistic"."logistic"."m_country"
  );