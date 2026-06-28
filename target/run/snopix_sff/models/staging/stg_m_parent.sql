
  create view "logistic"."dwh_staging"."stg_m_parent__dbt_tmp"
    
    
  as (
    select
    parent_id,
    parent_nm
from "logistic"."logistic"."m_parent"
  );