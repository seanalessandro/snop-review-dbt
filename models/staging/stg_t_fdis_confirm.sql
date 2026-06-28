-- FDIS confirm. Channel-AGNOSTIC (no distributor/warehouse filter in Java).
-- Keyed by upload + calendar.
select
    year_upload,
    period_upload,
    year,
    week,
    pcode,
    cast(qty as numeric) as qty
from {{ source('logistic', 't_fdis_confirm') }}
