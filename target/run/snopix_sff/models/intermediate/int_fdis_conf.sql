
  
    

  create  table "logistic"."dwh_intermediate"."int_fdis_conf__dbt_tmp"
  
  
    as
  
  (
    -- FDIS Confirm: channel-AGNOSTIC, upload-keyed, period weeks.
-- Period total + per-week W1..W5 pivot. No channel column (same value for GT/MT/ALL).
-- Grain: (year, period, pcode, ct_id).
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    c.pcode,
    p.ct_id,
    sum(case when pw.in_period   then c.qty else 0 end) as fdis_conf,
    sum(case when pw.wk_rank = 1 then c.qty else 0 end) as fdis_conf_w1,
    sum(case when pw.wk_rank = 2 then c.qty else 0 end) as fdis_conf_w2,
    sum(case when pw.wk_rank = 3 then c.qty else 0 end) as fdis_conf_w3,
    sum(case when pw.wk_rank = 4 then c.qty else 0 end) as fdis_conf_w4,
    sum(case when pw.wk_rank = 5 then c.qty else 0 end) as fdis_conf_w5
from "logistic"."dwh_staging"."stg_t_fdis_confirm" c
join "logistic"."dwh_intermediate"."int_period_window" pw
    on  c.year = pw.member_year
    and c.week = pw.member_week
    and c.year_upload   = pw.prev_year
    and c.period_upload = pw.prev_period
join "logistic"."dwh_intermediate"."int_product" p on c.pcode = p.pcode
where pw.in_period
group by pw.anchor_year, pw.anchor_period, c.pcode, p.ct_id
  );
  