{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select distinct
    acc_id,
    div_id
from {{ source('edi_logistic', 'm_acc_div') }}
where acc_id in ('AC0001', 'AC0002', 'AC0003', 'AC0004', 'MT')

