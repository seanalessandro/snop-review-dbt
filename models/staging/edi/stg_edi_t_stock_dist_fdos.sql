{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year,
    period,
    week,
    sub_id,
    ct_id,
    pcode,
    qty
from {{ source('edi_logistic', 't_stock_dist_fdos') }}

