{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year_upload,
    period_upload,
    year,
    period,
    sub_id,
    ct_id,
    pcode,
    acc_id,
    qty_adj
from {{ source('edi_logistic', 't_fdos_h') }}
