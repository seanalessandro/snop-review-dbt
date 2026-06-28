-- FDOS update detail. Calendar-keyed (year, period, week) — NO upload key.
-- distributor_id -> channel.
select
    year,
    period,
    week,
    pcode,
    distributor_id,
    cast(qty_adj as numeric) as qty_adj
from {{ source('logistic', 't_fdos_update_d') }}
