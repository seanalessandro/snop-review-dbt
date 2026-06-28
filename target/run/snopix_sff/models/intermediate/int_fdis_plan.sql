
  
    

  create  table "logistic"."dwh_intermediate"."int_fdis_plan__dbt_tmp"
  
  
    as
  
  (
    -- FDIS Plan: UNION of the LOCAL leg (t_fdis_marketing_d, ct = local_country_id,
-- channel = fact.sls_div) and the EXPORT leg (t_fdis_export_d, ct = export_country_id,
-- channel-agnostic). Both upload-keyed, restricted to the period weeks.
-- Period total + per-week W1..W5 pivot.
--
-- channel column: 'GT' | 'MT' for the local leg, 'EXP' for the export leg. The export
-- leg is added to EVERY selected channel in the mart (Java always appends the export
-- UNION regardless of channelDistribution).
-- Grain: (year, period, channel, pcode, ct_id).
with local_leg as (
    select
        pw.anchor_year   as year,
        pw.anchor_period as period,
        m.sls_div        as channel,
        m.pcode,
        p.ct_id,
        sum(case when pw.in_period   then m.qty_final else 0 end) as fdis_plan,
        sum(case when pw.wk_rank = 1 then m.qty_final else 0 end) as fdis_plan_w1,
        sum(case when pw.wk_rank = 2 then m.qty_final else 0 end) as fdis_plan_w2,
        sum(case when pw.wk_rank = 3 then m.qty_final else 0 end) as fdis_plan_w3,
        sum(case when pw.wk_rank = 4 then m.qty_final else 0 end) as fdis_plan_w4,
        sum(case when pw.wk_rank = 5 then m.qty_final else 0 end) as fdis_plan_w5
    from "logistic"."dwh_staging"."stg_t_fdis_marketing_d" m
    join "logistic"."dwh_intermediate"."int_period_window" pw
        on  m.year = pw.member_year
        and m.week = pw.member_week
        and m.year_upload   = pw.prev_year
        and m.period_upload = pw.prev_period
    join "logistic"."dwh_intermediate"."int_product" p on m.pcode = p.pcode
    where pw.in_period
      and m.sls_div in ('GT', 'MT')
      and p.ct_id = '120001'
    group by pw.anchor_year, pw.anchor_period, m.sls_div, m.pcode, p.ct_id
),

export_leg as (
    select
        pw.anchor_year   as year,
        pw.anchor_period as period,
        'EXP'            as channel,
        e.pcode,
        p.ct_id,
        sum(case when pw.in_period   then e.qty_adj else 0 end) as fdis_plan,
        sum(case when pw.wk_rank = 1 then e.qty_adj else 0 end) as fdis_plan_w1,
        sum(case when pw.wk_rank = 2 then e.qty_adj else 0 end) as fdis_plan_w2,
        sum(case when pw.wk_rank = 3 then e.qty_adj else 0 end) as fdis_plan_w3,
        sum(case when pw.wk_rank = 4 then e.qty_adj else 0 end) as fdis_plan_w4,
        sum(case when pw.wk_rank = 5 then e.qty_adj else 0 end) as fdis_plan_w5
    from "logistic"."dwh_staging"."stg_t_fdis_export_d" e
    join "logistic"."dwh_intermediate"."int_period_window" pw
        on  e.year = pw.member_year
        and e.week = pw.member_week
        and e.year_upload   = pw.prev_year
        and e.period_upload = pw.prev_period
    join "logistic"."dwh_intermediate"."int_product" p on e.pcode = p.pcode
    where pw.in_period
      and p.ct_id = '120002'
    group by pw.anchor_year, pw.anchor_period, e.pcode, p.ct_id
)

select * from local_leg
union all
select * from export_leg
  );
  