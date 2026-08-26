{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    pcode,
    price,
    sls_div as divisi,
    year
from {{ source('edi_logistic', 'm_price_divisi') }}
where sls_div in ('GT', 'MT')
