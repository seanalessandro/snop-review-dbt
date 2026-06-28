-- STM (MT channel). Same TEXT year/week normalization as stg_t_tmp_stm.
select
    cast(trim(year) as integer) as year,
    cast(trim(week) as integer) as week,
    distributor_id,
    pcode,
    cast(qty as numeric)        as qty,
    'MT'::text                  as channel
from "logistic"."logistic"."t_tmp_stm_mt"