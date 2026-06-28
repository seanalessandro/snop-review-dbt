-- STD actuals. Warehouse-keyed (wh_id -> channel).
select
    year,
    week,
    wh_id,
    pcode,
    cast(qty_actual as numeric) as qty_actual
from "logistic"."logistic"."t_fdis_actual"