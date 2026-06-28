-- MPS: channel-AGNOSTIC, upload-keyed, period weeks, flag_proc = 1 only.
-- Period total + per-week W1..W5 pivot. No channel column.
-- Grain: (year, period, pcode, ct_id).
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    m.pcode,
    p.ct_id,
    sum(case when pw.in_period   then m.qty_adj else 0 end) as mps,
    sum(case when pw.wk_rank = 1 then m.qty_adj else 0 end) as mps_w1,
    sum(case when pw.wk_rank = 2 then m.qty_adj else 0 end) as mps_w2,
    sum(case when pw.wk_rank = 3 then m.qty_adj else 0 end) as mps_w3,
    sum(case when pw.wk_rank = 4 then m.qty_adj else 0 end) as mps_w4,
    sum(case when pw.wk_rank = 5 then m.qty_adj else 0 end) as mps_w5
from "logistic"."dwh_staging"."stg_t_upload_mps" m
join "logistic"."dwh_intermediate"."int_period_window" pw
    on  m.year = pw.member_year
    and m.week = pw.member_week
    and m.year_upload   = pw.prev_year
    and m.period_upload = pw.prev_period
join "logistic"."dwh_intermediate"."int_product" p on m.pcode = p.pcode
where pw.in_period
  and m.flag_proc = 1
group by pw.anchor_year, pw.anchor_period, m.pcode, p.ct_id