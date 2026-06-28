-- FDIS Confirm Update: channel-AGNOSTIC, upload-keyed, period weeks, flag_proc = 1.
-- Per-week value = day1 + day2 + ... + day6. Period total + W1..W5 pivot. No channel.
-- Grain: (year, period, pcode, ct_id).
with src as (
    select
        year_upload,
        period_upload,
        year,
        week,
        pcode,
        ( coalesce(day1, 0) + coalesce(day2, 0) + coalesce(day3, 0)
        + coalesce(day4, 0) + coalesce(day5, 0) + coalesce(day6, 0) ) as qty
    from "logistic"."dwh_staging"."stg_t_fdis_confirm_update"
    where flag_proc = 1
)
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    s.pcode,
    p.ct_id,
    sum(case when pw.in_period   then s.qty else 0 end) as fdis_conf_upd,
    sum(case when pw.wk_rank = 1 then s.qty else 0 end) as fdis_conf_upd_w1,
    sum(case when pw.wk_rank = 2 then s.qty else 0 end) as fdis_conf_upd_w2,
    sum(case when pw.wk_rank = 3 then s.qty else 0 end) as fdis_conf_upd_w3,
    sum(case when pw.wk_rank = 4 then s.qty else 0 end) as fdis_conf_upd_w4,
    sum(case when pw.wk_rank = 5 then s.qty else 0 end) as fdis_conf_upd_w5
from src s
join "logistic"."dwh_intermediate"."int_period_window" pw
    on  s.year = pw.member_year
    and s.week = pw.member_week
    and s.year_upload   = pw.prev_year
    and s.period_upload = pw.prev_period
join "logistic"."dwh_intermediate"."int_product" p on s.pcode = p.pcode
where pw.in_period
group by pw.anchor_year, pw.anchor_period, s.pcode, p.ct_id