
  create view "logistic"."dwh_staging"."stg_m_product__dbt_tmp"
    
    
  as (
    -- Product master. Hierarchy keys + country marker drive every metric join.
select
    pcode,
    div_id,
    brand_id,
    subbrand_id,
    parent_id,
    ct_id,
    pcodename
from "logistic"."logistic"."m_product"
where div_id is not null
  );