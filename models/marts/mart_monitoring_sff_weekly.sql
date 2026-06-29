-- Pre-computed WEEKLY (SNOP) monitoring SFF, replacing
-- MonitoringSffRepositoryImpl.viewDataMonitoringWeekly().
--
-- Grain: one row per (year, period, channel, pcode, ct_id), channel in GT/MT/ALL.
--
-- SNOP weekly view rules (from the Java result mapping):
--   * Base display/percentage metrics are the WEEK-1 values: salfo, sta, std, stm,
--     fdos_plan (from t_fdos_d2), fdis_plan, fdos_upd, fdis_upd, fdis_conf, fdis_conf_upd.
--   * mps stays the MONTHLY total (Java does not override it to W1).
--   * Moving averages (avg13/avg5*) and stock stay MONTHLY.
--   * Percentages/SCD are computed on the Week-1 base, so they are Week-1 consistent.
--   * W1..W5 pivots are exposed for the six per-week metrics.
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

        -- Week-1 base metrics (override the monthly totals for the SNOP weekly view)
        {{ channel_pick('a.salfo_w1_gt', 'a.salfo_w1_mt') }}            as salfo,
        {{ channel_pick('a.sta_w1_gt', 'a.sta_w1_mt') }}               as sta,
        {{ channel_pick('a.std_w1_gt', 'a.std_w1_mt') }}               as std,
        {{ channel_pick('a.stm_w1_gt', 'a.stm_w1_mt') }}               as stm,
        {{ channel_pick('a.fdos_plan_w1_gt', 'a.fdos_plan_w1_mt') }}    as fdos_plan,
        {{ channel_pick('a.fdos_upd_w1_gt', 'a.fdos_upd_w1_mt') }}      as fdos_upd,
        {{ fdis_plan_pick('a.fdis_plan_w1_gt', 'a.fdis_plan_w1_mt', 'a.fdis_plan_w1_exp') }} as fdis_plan,
        {{ channel_pick('a.fdis_upd_w1_gt', 'a.fdis_upd_w1_mt') }}      as fdis_upd,
        a.fdis_conf_w1                                                  as fdis_conf,
        a.fdis_conf_upd_w1                                             as fdis_conf_upd,
        a.mps                                                          as mps,  -- monthly total (not overridden)

        -- Monthly moving averages + stock (not overridden in the weekly view)
        {{ channel_pick('a.avg13sta_gt', 'a.avg13sta_mt') }}           as avg13sta,
        {{ channel_pick('a.avg5sta_gt', 'a.avg5sta_mt') }}            as avg5sta,
        {{ channel_pick('a.avg13std_gt', 'a.avg13std_mt') }}          as avg13std,
        {{ channel_pick('a.avg5std_gt', 'a.avg5std_mt') }}           as avg5std,
        {{ channel_pick('a.avg13stm_gt', 'a.avg13stm_mt') }}          as avg13stm,
        {{ channel_pick('a.avg5stm_gt', 'a.avg5stm_mt') }}           as avg5stm,
        {{ channel_pick('a.stock_dist_gt', 'a.stock_dist_mt') }}      as stock_subdist,
        {{ channel_pick('a.stock_ibn_gt', 'a.stock_ibn_mt') }}        as stock_ibn,

        -- Per-week W1..W5 pivots
        {{ channel_pick('a.fdos_upd_w1_gt', 'a.fdos_upd_w1_mt') }}     as fdos_upd_w1,
        {{ channel_pick('a.fdos_upd_w2_gt', 'a.fdos_upd_w2_mt') }}     as fdos_upd_w2,
        {{ channel_pick('a.fdos_upd_w3_gt', 'a.fdos_upd_w3_mt') }}     as fdos_upd_w3,
        {{ channel_pick('a.fdos_upd_w4_gt', 'a.fdos_upd_w4_mt') }}     as fdos_upd_w4,
        {{ channel_pick('a.fdos_upd_w5_gt', 'a.fdos_upd_w5_mt') }}     as fdos_upd_w5,

        {{ fdis_plan_pick('a.fdis_plan_w1_gt', 'a.fdis_plan_w1_mt', 'a.fdis_plan_w1_exp') }} as fdis_plan_w1,
        {{ fdis_plan_pick('a.fdis_plan_w2_gt', 'a.fdis_plan_w2_mt', 'a.fdis_plan_w2_exp') }} as fdis_plan_w2,
        {{ fdis_plan_pick('a.fdis_plan_w3_gt', 'a.fdis_plan_w3_mt', 'a.fdis_plan_w3_exp') }} as fdis_plan_w3,
        {{ fdis_plan_pick('a.fdis_plan_w4_gt', 'a.fdis_plan_w4_mt', 'a.fdis_plan_w4_exp') }} as fdis_plan_w4,
        {{ fdis_plan_pick('a.fdis_plan_w5_gt', 'a.fdis_plan_w5_mt', 'a.fdis_plan_w5_exp') }} as fdis_plan_w5,

        a.mps_w1, a.mps_w2, a.mps_w3, a.mps_w4, a.mps_w5,

        a.fdis_conf_w1, a.fdis_conf_w2, a.fdis_conf_w3, a.fdis_conf_w4, a.fdis_conf_w5,

        a.fdis_conf_upd_w1, a.fdis_conf_upd_w2, a.fdis_conf_upd_w3,
        a.fdis_conf_upd_w4, a.fdis_conf_upd_w5,

        {{ channel_pick('a.fdis_upd_w1_gt', 'a.fdis_upd_w1_mt') }}     as fdis_upd_w1,
        {{ channel_pick('a.fdis_upd_w2_gt', 'a.fdis_upd_w2_mt') }}     as fdis_upd_w2,
        {{ channel_pick('a.fdis_upd_w3_gt', 'a.fdis_upd_w3_mt') }}     as fdis_upd_w3,
        {{ channel_pick('a.fdis_upd_w4_gt', 'a.fdis_upd_w4_mt') }}     as fdis_upd_w4,
        {{ channel_pick('a.fdis_upd_w5_gt', 'a.fdis_upd_w5_mt') }}     as fdis_upd_w5

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

    -- Week-1 base metrics
    salfo_base.salfo,
    salfo_base.sta,
    salfo_base.std,
    salfo_base.stm,
    salfo_base.fdos_plan,
    salfo_base.fdos_upd,
    salfo_base.fdis_plan,
    salfo_base.fdis_upd,
    salfo_base.fdis_conf,
    salfo_base.fdis_conf_upd,
    salfo_base.mps,

    -- monthly averages + stock
    salfo_base.avg13sta,
    salfo_base.avg5sta,
    salfo_base.avg13std,
    salfo_base.avg5std,
    salfo_base.avg13stm,
    salfo_base.avg5stm,
    salfo_base.stock_subdist,
    salfo_base.stock_ibn,
    coalesce(wc.jml_week, 0)    as jml_week,

    -- W1..W5 pivots
    salfo_base.fdos_upd_w1, salfo_base.fdos_upd_w2, salfo_base.fdos_upd_w3,
    salfo_base.fdos_upd_w4, salfo_base.fdos_upd_w5,
    salfo_base.fdis_plan_w1, salfo_base.fdis_plan_w2, salfo_base.fdis_plan_w3,
    salfo_base.fdis_plan_w4, salfo_base.fdis_plan_w5,
    salfo_base.mps_w1, salfo_base.mps_w2, salfo_base.mps_w3,
    salfo_base.mps_w4, salfo_base.mps_w5,
    salfo_base.fdis_conf_w1, salfo_base.fdis_conf_w2, salfo_base.fdis_conf_w3,
    salfo_base.fdis_conf_w4, salfo_base.fdis_conf_w5,
    salfo_base.fdis_conf_upd_w1, salfo_base.fdis_conf_upd_w2, salfo_base.fdis_conf_upd_w3,
    salfo_base.fdis_conf_upd_w4, salfo_base.fdis_conf_upd_w5,
    salfo_base.fdis_upd_w1, salfo_base.fdis_upd_w2, salfo_base.fdis_upd_w3,
    salfo_base.fdis_upd_w4, salfo_base.fdis_upd_w5,

    -- computed percentages + SCD on the Week-1 base (port of setComputedValues)
    {{ computed_metrics() }}

from base salfo_base
join {{ ref('int_product') }} p on salfo_base.pcode = p.pcode
left join week_count wc
    on salfo_base.year = wc.year and salfo_base.period = wc.period
