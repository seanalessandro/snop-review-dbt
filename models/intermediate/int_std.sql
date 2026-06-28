-- STD (from t_fdis_actual): warehouse-channel, calendar-keyed.
-- Period total + trailing 13w/5w moving averages + Week-1 value. Same averaging
-- convention as int_sta.
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    wc.channel,
    a.pcode,
    p.ct_id,
    sum(case when pw.in_period   then a.qty_actual else 0 end)                       as std,
    sum(case when pw.wk_rank = 1 then a.qty_actual else 0 end)                       as std_w1,
    sum(case when pw.in_w13 then a.qty_actual else 0 end) / nullif(max(pw.n13), 0)   as avg13std,
    sum(case when pw.in_w5  then a.qty_actual else 0 end) / nullif(max(pw.n5), 0)    as avg5std
from {{ ref('stg_t_fdis_actual') }} a
join {{ ref('int_period_window') }} pw
    on a.year = pw.member_year and a.week = pw.member_week
join {{ ref('int_product') }} p on a.pcode = p.pcode
join {{ ref('int_warehouse_channel') }} wc on a.wh_id = wc.wh_id
group by pw.anchor_year, pw.anchor_period, wc.channel, a.pcode, p.ct_id
