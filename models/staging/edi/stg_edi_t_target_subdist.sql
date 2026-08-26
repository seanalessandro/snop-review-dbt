{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year,
    period,
    sub_id,
    ct_id,
    pcode,
    amount,
    flag_proc
from {{ source('edi_logistic', 't_target_subdist') }}
