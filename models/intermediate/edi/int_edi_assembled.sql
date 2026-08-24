{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi', 'div_id']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

-- Chained FULL OUTER JOIN instead of UNION ALL + SELECT DISTINCT spine +
-- 9 separate LEFT JOINs. The old pattern scanned each of the 9 source
-- tables twice (once to build the spine, once to join back) and paid for
-- a DISTINCT over the full unioned key set. This version scans each
-- source table exactly once; the join key is carried forward via
-- COALESCE at each step since either side of a FULL OUTER JOIN can be
-- the one missing the key.

with base as (
    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan, pcode, div_id, ct_id,
        salfo_qty, salfo_value, price_missing
    from {{ ref('int_edi_salfo') }}
),

plus_fdos_plan as (
    select
        coalesce(base.year_upload, fd.year_upload) as year_upload,
        coalesce(base.period_upload, fd.period_upload) as period_upload,
        coalesce(base.divisi, fd.divisi) as divisi,
        coalesce(base.year_tujuan, fd.year_tujuan) as year_tujuan,
        coalesce(base.periode_tujuan, fd.periode_tujuan) as periode_tujuan,
        coalesce(base.pcode, fd.pcode) as pcode,
        coalesce(base.div_id, fd.div_id) as div_id,
        coalesce(base.ct_id, fd.ct_id) as ct_id,
        base.salfo_qty,
        base.salfo_value,
        base.price_missing,
        fd.fdos_plan
    from base
    full outer join {{ ref('int_edi_fdos_plan') }} fd
      on fd.year_upload = base.year_upload
     and fd.period_upload = base.period_upload
     and fd.divisi = base.divisi
     and fd.year_tujuan = base.year_tujuan
     and fd.periode_tujuan = base.periode_tujuan
     and fd.pcode = base.pcode
     and fd.div_id = base.div_id
     and fd.ct_id = base.ct_id
),

plus_fdis_plan as (
    select
        coalesce(plus_fdos_plan.year_upload, fp.year_upload) as year_upload,
        coalesce(plus_fdos_plan.period_upload, fp.period_upload) as period_upload,
        coalesce(plus_fdos_plan.divisi, fp.divisi) as divisi,
        coalesce(plus_fdos_plan.year_tujuan, fp.year_tujuan) as year_tujuan,
        coalesce(plus_fdos_plan.periode_tujuan, fp.periode_tujuan) as periode_tujuan,
        coalesce(plus_fdos_plan.pcode, fp.pcode) as pcode,
        coalesce(plus_fdos_plan.div_id, fp.div_id) as div_id,
        coalesce(plus_fdos_plan.ct_id, fp.ct_id) as ct_id,
        plus_fdos_plan.salfo_qty,
        plus_fdos_plan.salfo_value,
        plus_fdos_plan.price_missing,
        plus_fdos_plan.fdos_plan,
        fp.fdis_plan
    from plus_fdos_plan
    full outer join {{ ref('int_edi_fdis_plan') }} fp
      on fp.year_upload = plus_fdos_plan.year_upload
     and fp.period_upload = plus_fdos_plan.period_upload
     and fp.divisi = plus_fdos_plan.divisi
     and fp.year_tujuan = plus_fdos_plan.year_tujuan
     and fp.periode_tujuan = plus_fdos_plan.periode_tujuan
     and fp.pcode = plus_fdos_plan.pcode
     and fp.div_id = plus_fdos_plan.div_id
     and fp.ct_id = plus_fdos_plan.ct_id
),

plus_fdis_confirm as (
    select
        coalesce(plus_fdis_plan.year_upload, fc.year_upload) as year_upload,
        coalesce(plus_fdis_plan.period_upload, fc.period_upload) as period_upload,
        coalesce(plus_fdis_plan.divisi, fc.divisi) as divisi,
        coalesce(plus_fdis_plan.year_tujuan, fc.year_tujuan) as year_tujuan,
        coalesce(plus_fdis_plan.periode_tujuan, fc.periode_tujuan) as periode_tujuan,
        coalesce(plus_fdis_plan.pcode, fc.pcode) as pcode,
        coalesce(plus_fdis_plan.div_id, fc.div_id) as div_id,
        coalesce(plus_fdis_plan.ct_id, fc.ct_id) as ct_id,
        plus_fdis_plan.salfo_qty,
        plus_fdis_plan.salfo_value,
        plus_fdis_plan.price_missing,
        plus_fdis_plan.fdos_plan,
        plus_fdis_plan.fdis_plan,
        fc.fdis_confirm
    from plus_fdis_plan
    full outer join {{ ref('int_edi_fdis_confirm') }} fc
      on fc.year_upload = plus_fdis_plan.year_upload
     and fc.period_upload = plus_fdis_plan.period_upload
     and fc.divisi = plus_fdis_plan.divisi
     and fc.year_tujuan = plus_fdis_plan.year_tujuan
     and fc.periode_tujuan = plus_fdis_plan.periode_tujuan
     and fc.pcode = plus_fdis_plan.pcode
     and fc.div_id = plus_fdis_plan.div_id
     and fc.ct_id = plus_fdis_plan.ct_id
),

plus_fdis_confirm_update as (
    select
        coalesce(plus_fdis_confirm.year_upload, fcu.year_upload) as year_upload,
        coalesce(plus_fdis_confirm.period_upload, fcu.period_upload) as period_upload,
        coalesce(plus_fdis_confirm.divisi, fcu.divisi) as divisi,
        coalesce(plus_fdis_confirm.year_tujuan, fcu.year_tujuan) as year_tujuan,
        coalesce(plus_fdis_confirm.periode_tujuan, fcu.periode_tujuan) as periode_tujuan,
        coalesce(plus_fdis_confirm.pcode, fcu.pcode) as pcode,
        coalesce(plus_fdis_confirm.div_id, fcu.div_id) as div_id,
        coalesce(plus_fdis_confirm.ct_id, fcu.ct_id) as ct_id,
        plus_fdis_confirm.salfo_qty,
        plus_fdis_confirm.salfo_value,
        plus_fdis_confirm.price_missing,
        plus_fdis_confirm.fdos_plan,
        plus_fdis_confirm.fdis_plan,
        plus_fdis_confirm.fdis_confirm,
        fcu.fdis_confirm_update
    from plus_fdis_confirm
    full outer join {{ ref('int_edi_fdis_confirm_update') }} fcu
      on fcu.year_upload = plus_fdis_confirm.year_upload
     and fcu.period_upload = plus_fdis_confirm.period_upload
     and fcu.divisi = plus_fdis_confirm.divisi
     and fcu.year_tujuan = plus_fdis_confirm.year_tujuan
     and fcu.periode_tujuan = plus_fdis_confirm.periode_tujuan
     and fcu.pcode = plus_fdis_confirm.pcode
     and fcu.div_id = plus_fdis_confirm.div_id
     and fcu.ct_id = plus_fdis_confirm.ct_id
),

plus_target as (
    select
        coalesce(plus_fdis_confirm_update.year_upload, t.year_upload) as year_upload,
        coalesce(plus_fdis_confirm_update.period_upload, t.period_upload) as period_upload,
        coalesce(plus_fdis_confirm_update.divisi, t.divisi) as divisi,
        coalesce(plus_fdis_confirm_update.year_tujuan, t.year_tujuan) as year_tujuan,
        coalesce(plus_fdis_confirm_update.periode_tujuan, t.periode_tujuan) as periode_tujuan,
        coalesce(plus_fdis_confirm_update.pcode, t.pcode) as pcode,
        coalesce(plus_fdis_confirm_update.div_id, t.div_id) as div_id,
        coalesce(plus_fdis_confirm_update.ct_id, t.ct_id) as ct_id,
        plus_fdis_confirm_update.salfo_qty,
        plus_fdis_confirm_update.salfo_value,
        plus_fdis_confirm_update.price_missing,
        plus_fdis_confirm_update.fdos_plan,
        plus_fdis_confirm_update.fdis_plan,
        plus_fdis_confirm_update.fdis_confirm,
        plus_fdis_confirm_update.fdis_confirm_update,
        t.target
    from plus_fdis_confirm_update
    full outer join {{ ref('int_edi_target') }} t
      on t.year_upload = plus_fdis_confirm_update.year_upload
     and t.period_upload = plus_fdis_confirm_update.period_upload
     and t.divisi = plus_fdis_confirm_update.divisi
     and t.year_tujuan = plus_fdis_confirm_update.year_tujuan
     and t.periode_tujuan = plus_fdis_confirm_update.periode_tujuan
     and t.pcode = plus_fdis_confirm_update.pcode
     and t.div_id = plus_fdis_confirm_update.div_id
     and t.ct_id = plus_fdis_confirm_update.ct_id
),

plus_calendar_metrics as (
    select
        coalesce(plus_target.year_upload, cm.year_upload) as year_upload,
        coalesce(plus_target.period_upload, cm.period_upload) as period_upload,
        coalesce(plus_target.divisi, cm.divisi) as divisi,
        coalesce(plus_target.year_tujuan, cm.year_tujuan) as year_tujuan,
        coalesce(plus_target.periode_tujuan, cm.periode_tujuan) as periode_tujuan,
        coalesce(plus_target.pcode, cm.pcode) as pcode,
        coalesce(plus_target.div_id, cm.div_id) as div_id,
        coalesce(plus_target.ct_id, cm.ct_id) as ct_id,
        plus_target.salfo_qty,
        plus_target.salfo_value,
        plus_target.price_missing,
        plus_target.fdos_plan,
        plus_target.fdis_plan,
        plus_target.fdis_confirm,
        plus_target.fdis_confirm_update,
        plus_target.target,
        cm.fdis_update,
        cm.stock_ibn,
        cm.std,
        cm.sta
    from plus_target
    full outer join {{ ref('int_edi_calendar_metrics') }} cm
      on cm.year_upload = plus_target.year_upload
     and cm.period_upload = plus_target.period_upload
     and cm.divisi = plus_target.divisi
     and cm.year_tujuan = plus_target.year_tujuan
     and cm.periode_tujuan = plus_target.periode_tujuan
     and cm.pcode = plus_target.pcode
     and cm.div_id = plus_target.div_id
     and cm.ct_id = plus_target.ct_id
),

plus_stock_subdist as (
    select
        coalesce(plus_calendar_metrics.year_upload, ss.year_upload) as year_upload,
        coalesce(plus_calendar_metrics.period_upload, ss.period_upload) as period_upload,
        coalesce(plus_calendar_metrics.divisi, ss.divisi) as divisi,
        coalesce(plus_calendar_metrics.year_tujuan, ss.year_tujuan) as year_tujuan,
        coalesce(plus_calendar_metrics.periode_tujuan, ss.periode_tujuan) as periode_tujuan,
        coalesce(plus_calendar_metrics.pcode, ss.pcode) as pcode,
        coalesce(plus_calendar_metrics.div_id, ss.div_id) as div_id,
        coalesce(plus_calendar_metrics.ct_id, ss.ct_id) as ct_id,
        plus_calendar_metrics.salfo_qty,
        plus_calendar_metrics.salfo_value,
        plus_calendar_metrics.price_missing,
        plus_calendar_metrics.fdos_plan,
        plus_calendar_metrics.fdis_plan,
        plus_calendar_metrics.fdis_confirm,
        plus_calendar_metrics.fdis_confirm_update,
        plus_calendar_metrics.target,
        plus_calendar_metrics.fdis_update,
        plus_calendar_metrics.stock_ibn,
        plus_calendar_metrics.std,
        plus_calendar_metrics.sta,
        ss.stock_subdist
    from plus_calendar_metrics
    full outer join {{ ref('int_edi_stock_subdist') }} ss
      on ss.year_upload = plus_calendar_metrics.year_upload
     and ss.period_upload = plus_calendar_metrics.period_upload
     and ss.divisi = plus_calendar_metrics.divisi
     and ss.year_tujuan = plus_calendar_metrics.year_tujuan
     and ss.periode_tujuan = plus_calendar_metrics.periode_tujuan
     and ss.pcode = plus_calendar_metrics.pcode
     and ss.div_id = plus_calendar_metrics.div_id
     and ss.ct_id = plus_calendar_metrics.ct_id
),

plus_stm as (
    select
        coalesce(plus_stock_subdist.year_upload, stm.year_upload) as year_upload,
        coalesce(plus_stock_subdist.period_upload, stm.period_upload) as period_upload,
        coalesce(plus_stock_subdist.divisi, stm.divisi) as divisi,
        coalesce(plus_stock_subdist.year_tujuan, stm.year_tujuan) as year_tujuan,
        coalesce(plus_stock_subdist.periode_tujuan, stm.periode_tujuan) as periode_tujuan,
        coalesce(plus_stock_subdist.pcode, stm.pcode) as pcode,
        coalesce(plus_stock_subdist.div_id, stm.div_id) as div_id,
        coalesce(plus_stock_subdist.ct_id, stm.ct_id) as ct_id,
        plus_stock_subdist.salfo_qty,
        plus_stock_subdist.salfo_value,
        plus_stock_subdist.price_missing,
        plus_stock_subdist.fdos_plan,
        plus_stock_subdist.fdis_plan,
        plus_stock_subdist.fdis_confirm,
        plus_stock_subdist.fdis_confirm_update,
        plus_stock_subdist.target,
        plus_stock_subdist.fdis_update,
        plus_stock_subdist.stock_ibn,
        plus_stock_subdist.std,
        plus_stock_subdist.sta,
        plus_stock_subdist.stock_subdist,
        stm.stm
    from plus_stock_subdist
    full outer join {{ ref('int_edi_stm') }} stm
      on stm.year_upload = plus_stock_subdist.year_upload
     and stm.period_upload = plus_stock_subdist.period_upload
     and stm.divisi = plus_stock_subdist.divisi
     and stm.year_tujuan = plus_stock_subdist.year_tujuan
     and stm.periode_tujuan = plus_stock_subdist.periode_tujuan
     and stm.pcode = plus_stock_subdist.pcode
     and stm.div_id = plus_stock_subdist.div_id
     and stm.ct_id = plus_stock_subdist.ct_id
)

select
    year_upload,
    period_upload,
    divisi,
    year_tujuan,
    periode_tujuan,
    pcode,
    div_id,
    ct_id,
    coalesce(target, 0) as target,
    coalesce(salfo_qty, 0) as salfo_qty,
    coalesce(salfo_value, 0) as salfo_value,
    coalesce(price_missing, false) as price_missing,
    coalesce(fdos_plan, 0) as fdos_plan,
    coalesce(fdis_plan, 0) as fdis_plan,
    coalesce(fdis_confirm, 0) as fdis_confirm,
    coalesce(fdis_confirm_update, 0) as fdis_confirm_update,
    coalesce(fdis_update, 0) as fdis_update,
    coalesce(stock_subdist, 0) as stock_subdist,
    coalesce(stock_ibn, 0) as stock_ibn,
    coalesce(std, 0) as std,
    coalesce(sta, 0) as sta,
    coalesce(stm, 0) as stm
from plus_stm
