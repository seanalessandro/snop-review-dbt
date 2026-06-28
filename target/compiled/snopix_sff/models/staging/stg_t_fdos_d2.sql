-- FDOS plan weekly detail. Source for the Week-1 FDOS Plan override in the
-- weekly view (Java fdosPlanW1blk). Keyed by upload + calendar. sub_id -> channel.
select
    year_upload,
    period_upload,
    year,
    week,
    pcode,
    sub_id,
    cast(qty_adj as numeric) as qty_adj
from "logistic"."logistic"."t_fdos_d2"