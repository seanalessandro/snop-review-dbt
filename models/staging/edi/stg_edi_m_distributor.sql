{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

-- stg_edi_m_distributor.sql
select distinct
    ct_id,
    distributor_id,
    sls_div as divisi
from {{ source('edi_logistic', 'm_distributor') }}
where sls_div in ('GT', 'MT')

