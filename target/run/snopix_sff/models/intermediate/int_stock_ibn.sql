
  
    

  create  table "logistic"."dwh_intermediate"."int_stock_ibn__dbt_tmp"
  
  
    as
  
  (
    -- Stock IBN (warehouse stock): warehouse-channel, anchored to the period's last
-- calendar week (int_period_window id = 1, the currentPeriod='N' anchor).
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
with anchor_last_week as (
    select anchor_year, anchor_period, member_year, member_week
    from "logistic"."dwh_intermediate"."int_period_window"
    where id = 1
)
select
    aw.anchor_year   as year,
    aw.anchor_period as period,
    wc.channel,
    s.pcode,
    p.ct_id,
    sum(s.qty)       as stock_ibn
from "logistic"."dwh_staging"."stg_t_stock_wh" s
join anchor_last_week aw
    on s.year = aw.member_year and s.week = aw.member_week
join "logistic"."dwh_intermediate"."int_product" p on s.pcode = p.pcode
join "logistic"."dwh_intermediate"."int_warehouse_channel" wc on s.wh_id = wc.wh_id
group by aw.anchor_year, aw.anchor_period, wc.channel, s.pcode, p.ct_id
  );
  