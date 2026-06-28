
  create view "logistic"."dwh_staging"."stg_m_brand__dbt_tmp"
    
    
  as (
    select
    brand_id,
    brand_nm
from "logistic"."logistic"."m_brand"
  );