-- FDIS plan EXPORT leg (ct_id = export_country_id). CRITICAL: pcode_gdp is the
-- product key here (Java: d.pcode_gdp as pcode ... join p.pcode_gdp = p.pcode).
-- Channel-agnostic: the export leg is always added regardless of selected channel.
select
    year_upload,
    period_upload,
    year,
    week,
    pcode_gdp as pcode,
    cast(qty_adj as numeric) as qty_adj
from "logistic"."export"."t_fdis_export_d"