-- STA (from t_omset): warehouse-channel, calendar-keyed.
-- Period total + trailing 13w/5w moving averages + Week-1 value.
--
-- Moving average uses a FIXED window denominator (n13 / n5 = weeks in the window
-- from the cycle). Java divides by the number of weeks that actually had data; the
-- two agree whenever the group has data in every window week, and stay additive
-- across product/channel roll-ups (see README "Averaging note").
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    wc.channel,
    o.pcode,
    p.ct_id,
    sum(case when pw.in_period   then o.qty_omset else 0 end)                        as sta,
    sum(case when pw.wk_rank = 1 then o.qty_omset else 0 end)                        as sta_w1,
    sum(case when pw.in_w13 then o.qty_omset else 0 end) / nullif(max(pw.n13), 0)    as avg13sta,
    sum(case when pw.in_w5  then o.qty_omset else 0 end) / nullif(max(pw.n5), 0)     as avg5sta
from "logistic"."dwh_staging"."stg_t_omset" o
join "logistic"."dwh_intermediate"."int_period_window" pw
    on o.year = pw.member_year and o.week = pw.member_week
join "logistic"."dwh_intermediate"."int_product" p on o.pcode = p.pcode
join "logistic"."dwh_intermediate"."int_warehouse_channel" wc on o.wh_id = wc.wh_id
group by pw.anchor_year, pw.anchor_period, wc.channel, o.pcode, p.ct_id