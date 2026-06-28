-- Wide, channel-pivoted fact: ONE row per (year, period, pcode, ct_id) holding
-- every metric split into _gt / _mt (and _exp for FDIS plan) columns, plus the
-- channel-agnostic metrics and all W1..W5 pivots.
--
-- Both marts read from here: the monthly mart picks period totals, the weekly mart
-- picks the Week-1 values, and each multiplexes _gt/_mt into GT/MT/ALL rows via the
-- channel_pick / fdis_plan_pick macros. Centralising the pivot keeps the two marts
-- thin and guarantees they stay numerically consistent.
{{ config(materialized='table') }}

with
spine as (
    select year, period, pcode, ct_id from {{ ref('int_salfo') }}
    union select year, period, pcode, ct_id from {{ ref('int_sta') }}
    union select year, period, pcode, ct_id from {{ ref('int_std') }}
    union select year, period, pcode, ct_id from {{ ref('int_stm') }}
    union select year, period, pcode, ct_id from {{ ref('int_fdos_plan') }}
    union select year, period, pcode, ct_id from {{ ref('int_fdos_upd') }}
    union select year, period, pcode, ct_id from {{ ref('int_fdis_plan') }}
    union select year, period, pcode, ct_id from {{ ref('int_fdis_upd') }}
    union select year, period, pcode, ct_id from {{ ref('int_fdis_conf') }}
    union select year, period, pcode, ct_id from {{ ref('int_mps') }}
    union select year, period, pcode, ct_id from {{ ref('int_fdis_conf_upd') }}
    union select year, period, pcode, ct_id from {{ ref('int_stock_dist') }}
    union select year, period, pcode, ct_id from {{ ref('int_stock_ibn') }}
),

salfo_p as (
    select year, period, pcode, ct_id,
        sum(salfo)    filter (where channel = 'GT') as salfo_gt,
        sum(salfo)    filter (where channel = 'MT') as salfo_mt,
        sum(salfo_w1) filter (where channel = 'GT') as salfo_w1_gt,
        sum(salfo_w1) filter (where channel = 'MT') as salfo_w1_mt
    from {{ ref('int_salfo') }} group by 1, 2, 3, 4
),

sta_p as (
    select year, period, pcode, ct_id,
        sum(sta)      filter (where channel = 'GT') as sta_gt,
        sum(sta)      filter (where channel = 'MT') as sta_mt,
        sum(sta_w1)   filter (where channel = 'GT') as sta_w1_gt,
        sum(sta_w1)   filter (where channel = 'MT') as sta_w1_mt,
        sum(avg13sta) filter (where channel = 'GT') as avg13sta_gt,
        sum(avg13sta) filter (where channel = 'MT') as avg13sta_mt,
        sum(avg5sta)  filter (where channel = 'GT') as avg5sta_gt,
        sum(avg5sta)  filter (where channel = 'MT') as avg5sta_mt
    from {{ ref('int_sta') }} group by 1, 2, 3, 4
),

std_p as (
    select year, period, pcode, ct_id,
        sum(std)      filter (where channel = 'GT') as std_gt,
        sum(std)      filter (where channel = 'MT') as std_mt,
        sum(std_w1)   filter (where channel = 'GT') as std_w1_gt,
        sum(std_w1)   filter (where channel = 'MT') as std_w1_mt,
        sum(avg13std) filter (where channel = 'GT') as avg13std_gt,
        sum(avg13std) filter (where channel = 'MT') as avg13std_mt,
        sum(avg5std)  filter (where channel = 'GT') as avg5std_gt,
        sum(avg5std)  filter (where channel = 'MT') as avg5std_mt
    from {{ ref('int_std') }} group by 1, 2, 3, 4
),

stm_p as (
    select year, period, pcode, ct_id,
        sum(stm)      filter (where channel = 'GT') as stm_gt,
        sum(stm)      filter (where channel = 'MT') as stm_mt,
        sum(stm_w1)   filter (where channel = 'GT') as stm_w1_gt,
        sum(stm_w1)   filter (where channel = 'MT') as stm_w1_mt,
        sum(avg13stm) filter (where channel = 'GT') as avg13stm_gt,
        sum(avg13stm) filter (where channel = 'MT') as avg13stm_mt,
        sum(avg5stm)  filter (where channel = 'GT') as avg5stm_gt,
        sum(avg5stm)  filter (where channel = 'MT') as avg5stm_mt
    from {{ ref('int_stm') }} group by 1, 2, 3, 4
),

fdos_plan_p as (
    select year, period, pcode, ct_id,
        sum(fdos_plan)    filter (where channel = 'GT') as fdos_plan_gt,
        sum(fdos_plan)    filter (where channel = 'MT') as fdos_plan_mt,
        sum(fdos_plan_w1) filter (where channel = 'GT') as fdos_plan_w1_gt,
        sum(fdos_plan_w1) filter (where channel = 'MT') as fdos_plan_w1_mt
    from {{ ref('int_fdos_plan') }} group by 1, 2, 3, 4
),

fdos_upd_p as (
    select year, period, pcode, ct_id,
        sum(fdos_upd)    filter (where channel = 'GT') as fdos_upd_gt,
        sum(fdos_upd)    filter (where channel = 'MT') as fdos_upd_mt,
        sum(fdos_upd_w1) filter (where channel = 'GT') as fdos_upd_w1_gt,
        sum(fdos_upd_w1) filter (where channel = 'MT') as fdos_upd_w1_mt,
        sum(fdos_upd_w2) filter (where channel = 'GT') as fdos_upd_w2_gt,
        sum(fdos_upd_w2) filter (where channel = 'MT') as fdos_upd_w2_mt,
        sum(fdos_upd_w3) filter (where channel = 'GT') as fdos_upd_w3_gt,
        sum(fdos_upd_w3) filter (where channel = 'MT') as fdos_upd_w3_mt,
        sum(fdos_upd_w4) filter (where channel = 'GT') as fdos_upd_w4_gt,
        sum(fdos_upd_w4) filter (where channel = 'MT') as fdos_upd_w4_mt,
        sum(fdos_upd_w5) filter (where channel = 'GT') as fdos_upd_w5_gt,
        sum(fdos_upd_w5) filter (where channel = 'MT') as fdos_upd_w5_mt
    from {{ ref('int_fdos_upd') }} group by 1, 2, 3, 4
),

fdis_plan_p as (
    select year, period, pcode, ct_id,
        sum(fdis_plan)    filter (where channel = 'GT')  as fdis_plan_gt,
        sum(fdis_plan)    filter (where channel = 'MT')  as fdis_plan_mt,
        sum(fdis_plan)    filter (where channel = 'EXP') as fdis_plan_exp,
        sum(fdis_plan_w1) filter (where channel = 'GT')  as fdis_plan_w1_gt,
        sum(fdis_plan_w1) filter (where channel = 'MT')  as fdis_plan_w1_mt,
        sum(fdis_plan_w1) filter (where channel = 'EXP') as fdis_plan_w1_exp,
        sum(fdis_plan_w2) filter (where channel = 'GT')  as fdis_plan_w2_gt,
        sum(fdis_plan_w2) filter (where channel = 'MT')  as fdis_plan_w2_mt,
        sum(fdis_plan_w2) filter (where channel = 'EXP') as fdis_plan_w2_exp,
        sum(fdis_plan_w3) filter (where channel = 'GT')  as fdis_plan_w3_gt,
        sum(fdis_plan_w3) filter (where channel = 'MT')  as fdis_plan_w3_mt,
        sum(fdis_plan_w3) filter (where channel = 'EXP') as fdis_plan_w3_exp,
        sum(fdis_plan_w4) filter (where channel = 'GT')  as fdis_plan_w4_gt,
        sum(fdis_plan_w4) filter (where channel = 'MT')  as fdis_plan_w4_mt,
        sum(fdis_plan_w4) filter (where channel = 'EXP') as fdis_plan_w4_exp,
        sum(fdis_plan_w5) filter (where channel = 'GT')  as fdis_plan_w5_gt,
        sum(fdis_plan_w5) filter (where channel = 'MT')  as fdis_plan_w5_mt,
        sum(fdis_plan_w5) filter (where channel = 'EXP') as fdis_plan_w5_exp
    from {{ ref('int_fdis_plan') }} group by 1, 2, 3, 4
),

fdis_upd_p as (
    select year, period, pcode, ct_id,
        sum(fdis_upd)    filter (where channel = 'GT') as fdis_upd_gt,
        sum(fdis_upd)    filter (where channel = 'MT') as fdis_upd_mt,
        sum(fdis_upd_w1) filter (where channel = 'GT') as fdis_upd_w1_gt,
        sum(fdis_upd_w1) filter (where channel = 'MT') as fdis_upd_w1_mt,
        sum(fdis_upd_w2) filter (where channel = 'GT') as fdis_upd_w2_gt,
        sum(fdis_upd_w2) filter (where channel = 'MT') as fdis_upd_w2_mt,
        sum(fdis_upd_w3) filter (where channel = 'GT') as fdis_upd_w3_gt,
        sum(fdis_upd_w3) filter (where channel = 'MT') as fdis_upd_w3_mt,
        sum(fdis_upd_w4) filter (where channel = 'GT') as fdis_upd_w4_gt,
        sum(fdis_upd_w4) filter (where channel = 'MT') as fdis_upd_w4_mt,
        sum(fdis_upd_w5) filter (where channel = 'GT') as fdis_upd_w5_gt,
        sum(fdis_upd_w5) filter (where channel = 'MT') as fdis_upd_w5_mt
    from {{ ref('int_fdis_upd') }} group by 1, 2, 3, 4
),

stock_dist_p as (
    select year, period, pcode, ct_id,
        sum(stock_dist) filter (where channel = 'GT') as stock_dist_gt,
        sum(stock_dist) filter (where channel = 'MT') as stock_dist_mt
    from {{ ref('int_stock_dist') }} group by 1, 2, 3, 4
),

stock_ibn_p as (
    select year, period, pcode, ct_id,
        sum(stock_ibn) filter (where channel = 'GT') as stock_ibn_gt,
        sum(stock_ibn) filter (where channel = 'MT') as stock_ibn_mt
    from {{ ref('int_stock_ibn') }} group by 1, 2, 3, 4
)

select
    sp.year,
    sp.period,
    sp.pcode,
    sp.ct_id,

    -- SALFO
    coalesce(salfo_p.salfo_gt, 0)        as salfo_gt,
    coalesce(salfo_p.salfo_mt, 0)        as salfo_mt,
    coalesce(salfo_p.salfo_w1_gt, 0)     as salfo_w1_gt,
    coalesce(salfo_p.salfo_w1_mt, 0)     as salfo_w1_mt,

    -- STA
    coalesce(sta_p.sta_gt, 0)            as sta_gt,
    coalesce(sta_p.sta_mt, 0)            as sta_mt,
    coalesce(sta_p.sta_w1_gt, 0)         as sta_w1_gt,
    coalesce(sta_p.sta_w1_mt, 0)         as sta_w1_mt,
    coalesce(sta_p.avg13sta_gt, 0)       as avg13sta_gt,
    coalesce(sta_p.avg13sta_mt, 0)       as avg13sta_mt,
    coalesce(sta_p.avg5sta_gt, 0)        as avg5sta_gt,
    coalesce(sta_p.avg5sta_mt, 0)        as avg5sta_mt,

    -- STD
    coalesce(std_p.std_gt, 0)            as std_gt,
    coalesce(std_p.std_mt, 0)            as std_mt,
    coalesce(std_p.std_w1_gt, 0)         as std_w1_gt,
    coalesce(std_p.std_w1_mt, 0)         as std_w1_mt,
    coalesce(std_p.avg13std_gt, 0)       as avg13std_gt,
    coalesce(std_p.avg13std_mt, 0)       as avg13std_mt,
    coalesce(std_p.avg5std_gt, 0)        as avg5std_gt,
    coalesce(std_p.avg5std_mt, 0)        as avg5std_mt,

    -- STM
    coalesce(stm_p.stm_gt, 0)            as stm_gt,
    coalesce(stm_p.stm_mt, 0)            as stm_mt,
    coalesce(stm_p.stm_w1_gt, 0)         as stm_w1_gt,
    coalesce(stm_p.stm_w1_mt, 0)         as stm_w1_mt,
    coalesce(stm_p.avg13stm_gt, 0)       as avg13stm_gt,
    coalesce(stm_p.avg13stm_mt, 0)       as avg13stm_mt,
    coalesce(stm_p.avg5stm_gt, 0)        as avg5stm_gt,
    coalesce(stm_p.avg5stm_mt, 0)        as avg5stm_mt,

    -- FDOS PLAN
    coalesce(fdos_plan_p.fdos_plan_gt, 0)     as fdos_plan_gt,
    coalesce(fdos_plan_p.fdos_plan_mt, 0)     as fdos_plan_mt,
    coalesce(fdos_plan_p.fdos_plan_w1_gt, 0)  as fdos_plan_w1_gt,
    coalesce(fdos_plan_p.fdos_plan_w1_mt, 0)  as fdos_plan_w1_mt,

    -- FDOS UPDATE (+ W1..W5)
    coalesce(fdos_upd_p.fdos_upd_gt, 0)       as fdos_upd_gt,
    coalesce(fdos_upd_p.fdos_upd_mt, 0)       as fdos_upd_mt,
    coalesce(fdos_upd_p.fdos_upd_w1_gt, 0)    as fdos_upd_w1_gt,
    coalesce(fdos_upd_p.fdos_upd_w1_mt, 0)    as fdos_upd_w1_mt,
    coalesce(fdos_upd_p.fdos_upd_w2_gt, 0)    as fdos_upd_w2_gt,
    coalesce(fdos_upd_p.fdos_upd_w2_mt, 0)    as fdos_upd_w2_mt,
    coalesce(fdos_upd_p.fdos_upd_w3_gt, 0)    as fdos_upd_w3_gt,
    coalesce(fdos_upd_p.fdos_upd_w3_mt, 0)    as fdos_upd_w3_mt,
    coalesce(fdos_upd_p.fdos_upd_w4_gt, 0)    as fdos_upd_w4_gt,
    coalesce(fdos_upd_p.fdos_upd_w4_mt, 0)    as fdos_upd_w4_mt,
    coalesce(fdos_upd_p.fdos_upd_w5_gt, 0)    as fdos_upd_w5_gt,
    coalesce(fdos_upd_p.fdos_upd_w5_mt, 0)    as fdos_upd_w5_mt,

    -- FDIS PLAN (+ W1..W5; _exp = channel-agnostic export leg)
    coalesce(fdis_plan_p.fdis_plan_gt, 0)     as fdis_plan_gt,
    coalesce(fdis_plan_p.fdis_plan_mt, 0)     as fdis_plan_mt,
    coalesce(fdis_plan_p.fdis_plan_exp, 0)    as fdis_plan_exp,
    coalesce(fdis_plan_p.fdis_plan_w1_gt, 0)  as fdis_plan_w1_gt,
    coalesce(fdis_plan_p.fdis_plan_w1_mt, 0)  as fdis_plan_w1_mt,
    coalesce(fdis_plan_p.fdis_plan_w1_exp, 0) as fdis_plan_w1_exp,
    coalesce(fdis_plan_p.fdis_plan_w2_gt, 0)  as fdis_plan_w2_gt,
    coalesce(fdis_plan_p.fdis_plan_w2_mt, 0)  as fdis_plan_w2_mt,
    coalesce(fdis_plan_p.fdis_plan_w2_exp, 0) as fdis_plan_w2_exp,
    coalesce(fdis_plan_p.fdis_plan_w3_gt, 0)  as fdis_plan_w3_gt,
    coalesce(fdis_plan_p.fdis_plan_w3_mt, 0)  as fdis_plan_w3_mt,
    coalesce(fdis_plan_p.fdis_plan_w3_exp, 0) as fdis_plan_w3_exp,
    coalesce(fdis_plan_p.fdis_plan_w4_gt, 0)  as fdis_plan_w4_gt,
    coalesce(fdis_plan_p.fdis_plan_w4_mt, 0)  as fdis_plan_w4_mt,
    coalesce(fdis_plan_p.fdis_plan_w4_exp, 0) as fdis_plan_w4_exp,
    coalesce(fdis_plan_p.fdis_plan_w5_gt, 0)  as fdis_plan_w5_gt,
    coalesce(fdis_plan_p.fdis_plan_w5_mt, 0)  as fdis_plan_w5_mt,
    coalesce(fdis_plan_p.fdis_plan_w5_exp, 0) as fdis_plan_w5_exp,

    -- FDIS UPDATE (+ W1..W5)
    coalesce(fdis_upd_p.fdis_upd_gt, 0)       as fdis_upd_gt,
    coalesce(fdis_upd_p.fdis_upd_mt, 0)       as fdis_upd_mt,
    coalesce(fdis_upd_p.fdis_upd_w1_gt, 0)    as fdis_upd_w1_gt,
    coalesce(fdis_upd_p.fdis_upd_w1_mt, 0)    as fdis_upd_w1_mt,
    coalesce(fdis_upd_p.fdis_upd_w2_gt, 0)    as fdis_upd_w2_gt,
    coalesce(fdis_upd_p.fdis_upd_w2_mt, 0)    as fdis_upd_w2_mt,
    coalesce(fdis_upd_p.fdis_upd_w3_gt, 0)    as fdis_upd_w3_gt,
    coalesce(fdis_upd_p.fdis_upd_w3_mt, 0)    as fdis_upd_w3_mt,
    coalesce(fdis_upd_p.fdis_upd_w4_gt, 0)    as fdis_upd_w4_gt,
    coalesce(fdis_upd_p.fdis_upd_w4_mt, 0)    as fdis_upd_w4_mt,
    coalesce(fdis_upd_p.fdis_upd_w5_gt, 0)    as fdis_upd_w5_gt,
    coalesce(fdis_upd_p.fdis_upd_w5_mt, 0)    as fdis_upd_w5_mt,

    -- FDIS CONFIRM (channel-agnostic, + W1..W5)
    coalesce(fc.fdis_conf, 0)            as fdis_conf,
    coalesce(fc.fdis_conf_w1, 0)         as fdis_conf_w1,
    coalesce(fc.fdis_conf_w2, 0)         as fdis_conf_w2,
    coalesce(fc.fdis_conf_w3, 0)         as fdis_conf_w3,
    coalesce(fc.fdis_conf_w4, 0)         as fdis_conf_w4,
    coalesce(fc.fdis_conf_w5, 0)         as fdis_conf_w5,

    -- MPS (channel-agnostic, + W1..W5)
    coalesce(mps.mps, 0)                 as mps,
    coalesce(mps.mps_w1, 0)              as mps_w1,
    coalesce(mps.mps_w2, 0)              as mps_w2,
    coalesce(mps.mps_w3, 0)              as mps_w3,
    coalesce(mps.mps_w4, 0)              as mps_w4,
    coalesce(mps.mps_w5, 0)              as mps_w5,

    -- FDIS CONFIRM UPDATE (channel-agnostic, + W1..W5)
    coalesce(fcu.fdis_conf_upd, 0)       as fdis_conf_upd,
    coalesce(fcu.fdis_conf_upd_w1, 0)    as fdis_conf_upd_w1,
    coalesce(fcu.fdis_conf_upd_w2, 0)    as fdis_conf_upd_w2,
    coalesce(fcu.fdis_conf_upd_w3, 0)    as fdis_conf_upd_w3,
    coalesce(fcu.fdis_conf_upd_w4, 0)    as fdis_conf_upd_w4,
    coalesce(fcu.fdis_conf_upd_w5, 0)    as fdis_conf_upd_w5,

    -- STOCK
    coalesce(stock_dist_p.stock_dist_gt, 0)   as stock_dist_gt,
    coalesce(stock_dist_p.stock_dist_mt, 0)   as stock_dist_mt,
    coalesce(stock_ibn_p.stock_ibn_gt, 0)     as stock_ibn_gt,
    coalesce(stock_ibn_p.stock_ibn_mt, 0)     as stock_ibn_mt

from spine sp
left join salfo_p      on (sp.year, sp.period, sp.pcode, sp.ct_id) = (salfo_p.year, salfo_p.period, salfo_p.pcode, salfo_p.ct_id)
left join sta_p        on (sp.year, sp.period, sp.pcode, sp.ct_id) = (sta_p.year, sta_p.period, sta_p.pcode, sta_p.ct_id)
left join std_p        on (sp.year, sp.period, sp.pcode, sp.ct_id) = (std_p.year, std_p.period, std_p.pcode, std_p.ct_id)
left join stm_p        on (sp.year, sp.period, sp.pcode, sp.ct_id) = (stm_p.year, stm_p.period, stm_p.pcode, stm_p.ct_id)
left join fdos_plan_p  on (sp.year, sp.period, sp.pcode, sp.ct_id) = (fdos_plan_p.year, fdos_plan_p.period, fdos_plan_p.pcode, fdos_plan_p.ct_id)
left join fdos_upd_p   on (sp.year, sp.period, sp.pcode, sp.ct_id) = (fdos_upd_p.year, fdos_upd_p.period, fdos_upd_p.pcode, fdos_upd_p.ct_id)
left join fdis_plan_p  on (sp.year, sp.period, sp.pcode, sp.ct_id) = (fdis_plan_p.year, fdis_plan_p.period, fdis_plan_p.pcode, fdis_plan_p.ct_id)
left join fdis_upd_p   on (sp.year, sp.period, sp.pcode, sp.ct_id) = (fdis_upd_p.year, fdis_upd_p.period, fdis_upd_p.pcode, fdis_upd_p.ct_id)
left join {{ ref('int_fdis_conf') }}     fc  on (sp.year, sp.period, sp.pcode, sp.ct_id) = (fc.year, fc.period, fc.pcode, fc.ct_id)
left join {{ ref('int_mps') }}           mps on (sp.year, sp.period, sp.pcode, sp.ct_id) = (mps.year, mps.period, mps.pcode, mps.ct_id)
left join {{ ref('int_fdis_conf_upd') }} fcu on (sp.year, sp.period, sp.pcode, sp.ct_id) = (fcu.year, fcu.period, fcu.pcode, fcu.ct_id)
left join stock_dist_p on (sp.year, sp.period, sp.pcode, sp.ct_id) = (stock_dist_p.year, stock_dist_p.period, stock_dist_p.pcode, stock_dist_p.ct_id)
left join stock_ibn_p  on (sp.year, sp.period, sp.pcode, sp.ct_id) = (stock_ibn_p.year, stock_ibn_p.period, stock_ibn_p.pcode, stock_ibn_p.ct_id)
