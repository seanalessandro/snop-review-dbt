-- Warehouse (IBN) stock. Anchored to the period's last loaded week.
-- Warehouse-keyed (wh_id -> channel).
select
    year,
    period,
    week,
    pcode,
    wh_id,
    cast(qty as numeric) as qty
from "logistic"."logistic"."t_stock_wh"