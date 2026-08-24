{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year_upload,
    period_upload,
    year,
    week,
    trim(ct_id) as ct_id,
    trim(pcode) as pcode,
    qty
from {{ source('edi_logistic', 't_fdis_confirm') }}

