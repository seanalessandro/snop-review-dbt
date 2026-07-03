-- FDIS confirm. Sourced from t_tmp_fdis_confirm (plant/wh/buyer grain).
-- Keyed by upload + calendar.
select
    year_upload,
    period_upload,
    year,
    week,
    plant_id,
    reff_plant_id,
    wh_id,
    buyer_id,
    ct_id,
    pcode,
    cast(qty as numeric) as qty,
    user_id,
    flag_upload,
    flag1,
    nomor,
    fdis_plant_id
from {{ source('logistic', 't_tmp_fdis_confirm') }}
