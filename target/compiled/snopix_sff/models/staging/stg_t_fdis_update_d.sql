-- FDIS update detail. Warehouse-keyed (wh_id -> channel). Country-agnostic in
-- Java (no ct_id in its join); at pcode grain ct_id is fixed by the product.
select
    year,
    week,
    wh_id,
    pcode,
    cast(fdis_finish as numeric) as fdis_finish
from "logistic"."logistic"."t_fdis_update_d"