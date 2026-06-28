
  
    

  create  table "logistic"."dwh_intermediate"."int_fdis_upd__dbt_tmp"
  
  
    as
  
  (
    -- FDIS Update: warehouse-channel, calendar-keyed (period weeks). value = fdis_finish.
-- Period total + per-week W1..W5 pivot. (Country-agnostic in Java; here ct_id is
-- carried from the product so the mart can still split by country.)
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    wc.channel,
    u.pcode,
    p.ct_id,
    sum(case when pw.in_period   then u.fdis_finish else 0 end) as fdis_upd,
    sum(case when pw.wk_rank = 1 then u.fdis_finish else 0 end) as fdis_upd_w1,
    sum(case when pw.wk_rank = 2 then u.fdis_finish else 0 end) as fdis_upd_w2,
    sum(case when pw.wk_rank = 3 then u.fdis_finish else 0 end) as fdis_upd_w3,
    sum(case when pw.wk_rank = 4 then u.fdis_finish else 0 end) as fdis_upd_w4,
    sum(case when pw.wk_rank = 5 then u.fdis_finish else 0 end) as fdis_upd_w5
from "logistic"."dwh_staging"."stg_t_fdis_update_d" u
join "logistic"."dwh_intermediate"."int_period_window" pw
    on u.year = pw.member_year and u.week = pw.member_week
join "logistic"."dwh_intermediate"."int_product" p on u.pcode = p.pcode
join "logistic"."dwh_intermediate"."int_warehouse_channel" wc on u.wh_id = wc.wh_id
where pw.in_period
group by pw.anchor_year, pw.anchor_period, wc.channel, u.pcode, p.ct_id
  );
  