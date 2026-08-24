{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year,
    period,
    week,
    trim(sub_id) as sub_id,
    trim(ct_id) as ct_id,
    trim(pcode) as pcode,
    qty
from {{ source('edi_logistic', 't_stock_dist_fdos') }}

