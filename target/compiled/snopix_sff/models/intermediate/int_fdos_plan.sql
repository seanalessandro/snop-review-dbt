-- FDOS Plan: distributor-channel, upload-keyed, PERIOD-level (no week dimension).
--   fdos_plan    -> t_fdos_h, summed where period = anchor period (Java fdosPlan)
--   fdos_plan_w1 -> t_fdos_d2, Week-1 only (Java fdosPlanW1blk, weekly view override)
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
with anchor_prev as (
    select distinct anchor_year, anchor_period, prev_year, prev_period
    from "logistic"."dwh_intermediate"."int_period_window"
),

plan as (
    select
        ap.anchor_year   as year,
        ap.anchor_period as period,
        dist.sls_div     as channel,
        h.pcode,
        p.ct_id,
        sum(h.qty_adj)   as fdos_plan
    from "logistic"."dwh_staging"."stg_t_fdos_h" h
    join anchor_prev ap
        on  h.year_upload   = ap.prev_year
        and h.period_upload = ap.prev_period
        and h.period        = ap.anchor_period
    join "logistic"."dwh_intermediate"."int_product" p on h.pcode = p.pcode
    join "logistic"."dwh_staging"."stg_m_distributor" dist
        on h.sub_id = dist.distributor_id and dist.sls_div in ('GT', 'MT')
    group by ap.anchor_year, ap.anchor_period, dist.sls_div, h.pcode, p.ct_id
),

plan_w1 as (
    select
        pw.anchor_year   as year,
        pw.anchor_period as period,
        dist.sls_div     as channel,
        d2.pcode,
        p.ct_id,
        sum(d2.qty_adj)  as fdos_plan_w1
    from "logistic"."dwh_staging"."stg_t_fdos_d2" d2
    join "logistic"."dwh_intermediate"."int_period_window" pw
        on  d2.year = pw.member_year
        and d2.week = pw.member_week
        and d2.year_upload   = pw.prev_year
        and d2.period_upload = pw.prev_period
    join "logistic"."dwh_intermediate"."int_product" p on d2.pcode = p.pcode
    join "logistic"."dwh_staging"."stg_m_distributor" dist
        on d2.sub_id = dist.distributor_id and dist.sls_div in ('GT', 'MT')
    where pw.wk_rank = 1
    group by pw.anchor_year, pw.anchor_period, dist.sls_div, d2.pcode, p.ct_id
)

select
    coalesce(pl.year, w1.year)         as year,
    coalesce(pl.period, w1.period)     as period,
    coalesce(pl.channel, w1.channel)   as channel,
    coalesce(pl.pcode, w1.pcode)       as pcode,
    coalesce(pl.ct_id, w1.ct_id)       as ct_id,
    coalesce(pl.fdos_plan, 0)          as fdos_plan,
    coalesce(w1.fdos_plan_w1, 0)       as fdos_plan_w1
from plan pl
full outer join plan_w1 w1
    on  pl.year = w1.year and pl.period = w1.period and pl.channel = w1.channel
    and pl.pcode = w1.pcode and pl.ct_id = w1.ct_id