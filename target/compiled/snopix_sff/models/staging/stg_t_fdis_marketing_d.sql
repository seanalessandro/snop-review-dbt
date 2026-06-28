-- FDIS plan LOCAL leg (ct_id = local_country_id). Channel via the fact's own
-- sls_div column. Keyed by upload + calendar.
select
    year_upload,
    period_upload,
    year,
    week,
    pcode,
    sls_div,
    cast(qty_final as numeric) as qty_final
from "logistic"."logistic"."t_fdis_marketing_d"