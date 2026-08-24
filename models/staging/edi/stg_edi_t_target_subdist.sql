{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year,
    period,
    trim(sub_id) as sub_id,
    trim(ct_id) as ct_id,
    trim(pcode) as pcode,
    amount,
    flag_proc
from {{ source('edi_logistic', 't_target_subdist') }}
where flag_proc = 1

