{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

-- stg_edi_t_fdos_h.sql
select
    year_upload,
    period_upload,
    year,
    period,
    sub_id,
    ct_id,
    pcode,
    acc_id,
    qty_adj,
    flag_proc
from {{ source('edi_logistic', 't_fdos_h') }}
where flag_proc = 1

