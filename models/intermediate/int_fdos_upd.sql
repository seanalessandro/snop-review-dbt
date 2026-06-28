-- FDOS Update: distributor-channel, calendar-keyed (period weeks). NO upload key.
-- Period total + per-week W1..W5 pivot.
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    dist.sls_div     as channel,
    u.pcode,
    p.ct_id,
    sum(case when pw.in_period   then u.qty_adj else 0 end) as fdos_upd,
    sum(case when pw.wk_rank = 1 then u.qty_adj else 0 end) as fdos_upd_w1,
    sum(case when pw.wk_rank = 2 then u.qty_adj else 0 end) as fdos_upd_w2,
    sum(case when pw.wk_rank = 3 then u.qty_adj else 0 end) as fdos_upd_w3,
    sum(case when pw.wk_rank = 4 then u.qty_adj else 0 end) as fdos_upd_w4,
    sum(case when pw.wk_rank = 5 then u.qty_adj else 0 end) as fdos_upd_w5
from {{ ref('stg_t_fdos_update_d') }} u
join {{ ref('int_period_window') }} pw
    on  u.year   = pw.member_year
    and u.week   = pw.member_week
    and u.period = pw.member_period
join {{ ref('int_product') }} p on u.pcode = p.pcode
join {{ ref('stg_m_distributor') }} dist
    on u.distributor_id = dist.distributor_id and dist.sls_div in ('GT', 'MT')
where pw.in_period
group by pw.anchor_year, pw.anchor_period, dist.sls_div, u.pcode, p.ct_id
