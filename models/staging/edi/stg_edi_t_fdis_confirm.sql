{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year_upload,
    period_upload,
    year,
    week,
    ct_id,
    pcode,
    qty
from {{ source('edi_logistic', 't_fdis_confirm') }}

