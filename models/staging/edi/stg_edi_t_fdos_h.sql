{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year_upload,
    period_upload,
    year,
    period,
    trim(sub_id) as sub_id,
    trim(ct_id) as ct_id,
    trim(pcode) as pcode,
    trim(acc_id) as acc_id,
    qty_adj,
    flag_proc
from {{ source('edi_logistic', 't_fdos_h') }}
where flag_proc = 1

