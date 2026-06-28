-- Stock Dist (distributor stock): distributor-channel, anchored to the period's
-- last calendar week (int_period_window id = 1, the currentPeriod='N' anchor),
-- restricted to the m_mapping_product (distributor, pcode) whitelist.
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
with anchor_last_week as (
    select anchor_year, anchor_period, member_year, member_week
    from {{ ref('int_period_window') }}
    where id = 1
)
select
    aw.anchor_year   as year,
    aw.anchor_period as period,
    dist.sls_div     as channel,
    sd.pcode,
    p.ct_id,
    sum(sd.qty)      as stock_dist
from {{ ref('stg_t_stock_dist') }} sd
join anchor_last_week aw
    on sd.year = aw.member_year and sd.week = aw.member_week
join {{ ref('int_product') }} p on sd.pcode = p.pcode
join {{ ref('stg_m_distributor') }} dist
    on sd.sub_id = dist.distributor_id and dist.sls_div in ('GT', 'MT')
join {{ ref('stg_m_mapping_product') }} mp
    on sd.sub_id = mp.distributor_id and sd.pcode = mp.pcode
group by aw.anchor_year, aw.anchor_period, dist.sls_div, sd.pcode, p.ct_id
