-- Pre-computed MONTHLY monitoring SFF, replacing
-- MonitoringSffRepositoryImpl.viewDataMonitoringMonthly().
--
-- Grain: one row per (year, period, channel, pcode, ct_id), channel in GT/MT/ALL.
-- The Spring Boot API then serves any hierarchy level with a trivial
--   SELECT <group key> as ket, SUM(salfo), AVG... FROM this mart
--   WHERE year=? AND period=? AND channel=? [AND ct_id IN ...] GROUP BY <group key>
--
-- Percentages + SCD are pre-computed here (computed_metrics macro) so the API no
-- longer calls setComputedValues(). NOTE: percentages are per-pcode here; if the API
-- aggregates to div/brand it must recompute them from the summed metrics (they are
-- ratios, not additive) - see README.
{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['year', 'period', 'channel', 'country_id']},
      {'columns': ['year', 'period', 'channel', 'div_id']},
      {'columns': ['year', 'period', 'channel', 'brand_id']}
    ]
) }}

with channels as (
    select unnest(array['GT', 'MT', 'ALL']) as channel
),

week_count as (
    select anchor_year as year, anchor_period as period, count(*) as jml_week
    from {{ ref('int_period_window') }}
    where in_period
    group by 1, 2
),

base as (
    select
        a.year,
        a.period,
        ch.channel,
        a.pcode,
        a.ct_id,

        {{ channel_pick('a.salfo_gt', 'a.salfo_mt') }}          as salfo,
        {{ channel_pick('a.sta_gt', 'a.sta_mt') }}              as sta,
        {{ channel_pick('a.avg13sta_gt', 'a.avg13sta_mt') }}    as avg13sta,
        {{ channel_pick('a.avg5sta_gt', 'a.avg5sta_mt') }}      as avg5sta,
        {{ channel_pick('a.std_gt', 'a.std_mt') }}              as std,
        {{ channel_pick('a.avg13std_gt', 'a.avg13std_mt') }}    as avg13std,
        {{ channel_pick('a.avg5std_gt', 'a.avg5std_mt') }}      as avg5std,
        {{ channel_pick('a.stm_gt', 'a.stm_mt') }}              as stm,
        {{ channel_pick('a.avg13stm_gt', 'a.avg13stm_mt') }}    as avg13stm,
        {{ channel_pick('a.avg5stm_gt', 'a.avg5stm_mt') }}      as avg5stm,
        {{ channel_pick('a.fdos_plan_gt', 'a.fdos_plan_mt') }}  as fdos_plan,
        {{ channel_pick('a.fdos_upd_gt', 'a.fdos_upd_mt') }}    as fdos_upd,
        {{ fdis_plan_pick('a.fdis_plan_gt', 'a.fdis_plan_mt', 'a.fdis_plan_exp') }} as fdis_plan,
        {{ channel_pick('a.fdis_upd_gt', 'a.fdis_upd_mt') }}    as fdis_upd,
        a.fdis_conf                                             as fdis_conf,
        a.fdis_conf_upd                                         as fdis_conf_upd,
        a.mps                                                   as mps,
        {{ channel_pick('a.stock_dist_gt', 'a.stock_dist_mt') }} as stock_subdist,
        {{ channel_pick('a.stock_ibn_gt', 'a.stock_ibn_mt') }}   as stock_ibn

    from {{ ref('int_sff_assembled') }} a
    cross join channels ch
)

select
    salfo_base.year,
    salfo_base.period,
    salfo_base.channel,
    salfo_base.pcode,
    p.pcodename,
    p.div_id,
    p.div_nm,
    p.brand_id,
    p.brand_nm,
    p.subbrand_id,
    p.subbrand_nm,
    p.parent_id,
    p.parent_nm,
    salfo_base.ct_id            as country_id,
    p.ct_nm                     as country_name,

    -- raw metrics
    salfo_base.salfo,
    salfo_base.sta,
    salfo_base.avg13sta,
    salfo_base.avg5sta,
    salfo_base.std,
    salfo_base.avg13std,
    salfo_base.avg5std,
    salfo_base.stm,
    salfo_base.avg13stm,
    salfo_base.avg5stm,
    salfo_base.fdos_plan,
    salfo_base.fdos_upd,
    salfo_base.fdis_plan,
    salfo_base.fdis_upd,
    salfo_base.fdis_conf,
    salfo_base.fdis_conf_upd,
    salfo_base.mps,
    salfo_base.stock_subdist,
    salfo_base.stock_ibn,
    coalesce(wc.jml_week, 0)    as jml_week,

    -- computed percentages + SCD (port of setComputedValues)
    {{ computed_metrics() }}

from base salfo_base
join {{ ref('int_product') }} p on salfo_base.pcode = p.pcode
left join week_count wc
    on salfo_base.year = wc.year and salfo_base.period = wc.period
