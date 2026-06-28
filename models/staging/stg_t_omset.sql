-- STA actuals. Warehouse-keyed (wh_id -> channel).
select
    year,
    week,
    wh_id,
    pcode,
    cast(qty_omset as numeric) as qty_omset
from {{ source('logistic', 't_omset') }}
