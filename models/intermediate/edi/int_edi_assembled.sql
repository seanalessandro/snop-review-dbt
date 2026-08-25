{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi', 'div_id']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

-- Each upstream model is already unique at the final EDI grain. Stack the
-- narrow metric projections once and collapse them with one GROUP BY. This is
-- equivalent to a full outer merge by grain, without the increasingly complex
-- COALESCE join predicates that become very expensive on production volumes.

with metric_rows as (
    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric as target,
        salfo_qty,
        salfo_value,
        price_missing,
        0::numeric as fdos_plan,
        0::numeric as fdis_plan,
        0::numeric as fdis_confirm,
        0::numeric as fdis_confirm_update,
        0::numeric as fdis_update,
        0::numeric as stock_subdist,
        0::numeric as stock_ibn,
        0::numeric as std,
        0::numeric as sta,
        0::numeric as stm
    from {{ ref('int_edi_salfo') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        fdos_plan,
        0::numeric, 0::numeric, 0::numeric, 0::numeric,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric
    from {{ ref('int_edi_fdos_plan') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        0::numeric,
        fdis_plan,
        0::numeric, 0::numeric, 0::numeric,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric
    from {{ ref('int_edi_fdis_plan') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        0::numeric, 0::numeric,
        fdis_confirm,
        0::numeric, 0::numeric,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric
    from {{ ref('int_edi_fdis_confirm') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        0::numeric, 0::numeric, 0::numeric,
        fdis_confirm_update,
        0::numeric,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric
    from {{ ref('int_edi_fdis_confirm_update') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        target,
        0::numeric, 0::numeric, false,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric
    from {{ ref('int_edi_target') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        0::numeric, 0::numeric, 0::numeric, 0::numeric,
        fdis_update,
        0::numeric,
        stock_ibn,
        std,
        sta,
        0::numeric
    from {{ ref('int_edi_calendar_metrics') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric,
        stock_subdist,
        0::numeric, 0::numeric, 0::numeric, 0::numeric
    from {{ ref('int_edi_stock_subdist') }}

    union all

    select
        year_upload, period_upload, divisi, year_tujuan, periode_tujuan,
        pcode, div_id, ct_id,
        0::numeric, 0::numeric, 0::numeric, false,
        0::numeric, 0::numeric, 0::numeric, 0::numeric, 0::numeric,
        0::numeric, 0::numeric, 0::numeric, 0::numeric,
        stm
    from {{ ref('int_edi_stm') }}
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
    sum(target) as target,
    sum(salfo_qty) as salfo_qty,
    sum(salfo_value) as salfo_value,
    bool_or(price_missing) as price_missing,
    sum(fdos_plan) as fdos_plan,
    sum(fdis_plan) as fdis_plan,
    sum(fdis_confirm) as fdis_confirm,
    sum(fdis_confirm_update) as fdis_confirm_update,
    sum(fdis_update) as fdis_update,
    sum(stock_subdist) as stock_subdist,
    sum(stock_ibn) as stock_ibn,
    sum(std) as std,
    sum(sta) as sta,
    sum(stm) as stm
from metric_rows
group by
    year_upload,
    period_upload,
    divisi,
    year_tujuan,
    periode_tujuan,
    pcode,
    div_id,
    ct_id
