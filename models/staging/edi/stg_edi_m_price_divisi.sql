{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    trim(pcode) as pcode,
    price,
    upper(trim(sls_div)) as divisi,
    year
from {{ source('edi_logistic', 'm_price_divisi') }}
where upper(trim(sls_div)) in ('GT', 'MT')
