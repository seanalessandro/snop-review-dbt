{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select distinct
    trim(acc_id) as acc_id,
    trim(div_id) as div_id
from {{ source('edi_logistic', 'm_acc_div') }}
where trim(acc_id) in ('AC0001', 'AC0002', 'AC0003', 'AC0004', 'MT')

