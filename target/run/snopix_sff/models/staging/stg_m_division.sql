
  create view "logistic"."dwh_staging"."stg_m_division__dbt_tmp"
    
    
  as (
    select
    div_id,
    div_nm
from "logistic"."logistic"."m_division"
  );