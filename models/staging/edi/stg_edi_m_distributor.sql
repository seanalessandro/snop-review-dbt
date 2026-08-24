{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select distinct
    trim(ct_id) as ct_id,
    trim(distributor_id) as distributor_id,
    upper(trim(sls_div)) as divisi
from {{ source('edi_logistic', 'm_distributor') }}
where upper(trim(sls_div)) in ('GT', 'MT')

