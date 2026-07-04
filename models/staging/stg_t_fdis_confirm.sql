-- FDIS confirm. Sourced from t_tmp_fdis_confirm (plant/wh/buyer grain).
-- Keyed by upload + calendar. year_upload/period_upload/year/week are stored
-- as varchar in this table (unlike other fact tables); normalize to integer
-- so joins to int_period_window / m_cycle2 (numeric) still work.
select
    cast(trim(year_upload) as integer)   as year_upload,
    cast(trim(period_upload) as integer) as period_upload,
    cast(trim(year) as integer)          as year,
    cast(trim(week) as integer)          as week,
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
