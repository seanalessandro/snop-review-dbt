
  
    

  create  table "logistic"."dwh_intermediate"."int_product__dbt_tmp"
  
  
    as
  
  (
    -- Product master with hierarchy names + resolved country name.
-- Country name mirrors the Java FROM block: COALESCE(export.m_country, logistic.m_country).
-- Grain: one row per pcode.
select
    p.pcode,
    p.pcodename,
    p.div_id,
    p.brand_id,
    p.subbrand_id,
    p.parent_id,
    p.ct_id,
    d.div_nm,
    b.brand_nm,
    s.subbrand_nm,
    pr.parent_nm,
    coalesce(ec.ct_nm, lc.ct_nm) as ct_nm
from "logistic"."dwh_staging"."stg_m_product" p
left join "logistic"."dwh_staging"."stg_m_division"       d  on p.div_id = d.div_id
left join "logistic"."dwh_staging"."stg_m_brand"          b  on p.brand_id = b.brand_id
left join "logistic"."dwh_staging"."stg_m_subbrand"       s  on p.brand_id = s.brand_id
                                              and p.subbrand_id = s.subbrand_id
left join "logistic"."dwh_staging"."stg_m_parent"         pr on p.parent_id = pr.parent_id
left join "logistic"."dwh_staging"."stg_m_country_export" ec on p.ct_id = ec.ct_id
left join "logistic"."dwh_staging"."stg_m_country"        lc on p.ct_id = lc.ct_id
  );
  