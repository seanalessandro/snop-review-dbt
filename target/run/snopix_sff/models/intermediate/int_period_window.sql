
  
    

  create  table "logistic"."dwh_intermediate"."int_period_window__dbt_tmp"
  
  
    as
  
  (
    -- Calendar backbone. For every anchor (year, period) this enumerates the calendar
-- weeks it needs, tagged with the windows each week belongs to. Built once; every
-- metric model joins its fact (year, week) onto this.
--
-- Columns:
--   anchor_year/anchor_period : the period a mart row is built for
--   prev_year/prev_period     : previous existing period -> the UPLOAD key
--                               (Java util.getPrevYearAndPeriod), used by the
--                               upload-keyed metrics (salfo, fdos plan, fdis *, mps)
--   member_year/member_week   : a calendar week inside the trailing 13-week window
--   in_period                 : week belongs to the anchor period (period totals)
--   in_w13 / in_w5            : week is in the trailing 13 / 5 week moving-avg window
--   wk_rank                   : 1..5 position within the anchor period (W1..W5 pivots)
--   n13 / n5                  : week count of each window (moving-average denominator)
--
-- NOTE (currentPeriod='N' semantics): the trailing window ends at the anchor period's
-- last week, matching the historical branch of the Java query. The live currentPeriod='Y'
-- branch (m_cycle3, window shifted back one week) is intentionally not modelled here -
-- the in-progress period is better served live; see README.


with weeks as (
    select distinct year, period, week from "logistic"."dwh_staging"."stg_m_cycle2"
),

anchors as (
    select distinct year as anchor_year, period as anchor_period
    from "logistic"."dwh_staging"."stg_m_cycle2"
),

-- Previous existing period (handles year/period wrap data-driven via lag).
anchor_seq as (
    select
        anchor_year,
        anchor_period,
        lag(anchor_year)   over (order by anchor_year, anchor_period) as prev_year,
        lag(anchor_period) over (order by anchor_year, anchor_period) as prev_period
    from anchors
),

-- Trailing weeks: every week whose period <= the anchor period, ranked most-recent
-- first. Mirrors the Java row_number() ... desc window over m_cycle2.
ranked as (
    select
        a.anchor_year,
        a.anchor_period,
        w.year   as member_year,
        w.period as member_period,
        w.week   as member_week,
        row_number() over (
            partition by a.anchor_year, a.anchor_period
            order by cast(w.year as text) || lpad(cast(w.week as text), 2, '0') desc
        ) as id
    from anchors a
    join weeks w
      on cast(w.year as text)        || lpad(cast(w.period as text), 2, '0')
      <= cast(a.anchor_year as text) || lpad(cast(a.anchor_period as text), 2, '0')
),

-- Position of each week WITHIN its anchor period (ascending) -> W1..W5.
period_ranked as (
    select
        a.anchor_year,
        a.anchor_period,
        w.year as member_year,
        w.week as member_week,
        row_number() over (
            partition by a.anchor_year, a.anchor_period
            order by cast(w.year as text) || lpad(cast(w.week as text), 2, '0')
        ) as wk_rank
    from anchors a
    join weeks w on w.year = a.anchor_year and w.period = a.anchor_period
)

select
    r.anchor_year,
    r.anchor_period,
    s.prev_year,
    s.prev_period,
    r.member_year,
    r.member_period,
    r.member_week,
    r.id,
    (r.member_year = r.anchor_year and r.member_period = r.anchor_period) as in_period,
    (r.id <= 13) as in_w13,
    (r.id <= 5)  as in_w5,
    pr.wk_rank,
    count(*) filter (where r.id <= 13) over (partition by r.anchor_year, r.anchor_period) as n13,
    count(*) filter (where r.id <= 5)  over (partition by r.anchor_year, r.anchor_period) as n5
from ranked r
join anchor_seq s
    on r.anchor_year = s.anchor_year and r.anchor_period = s.anchor_period
left join period_ranked pr
    on  pr.anchor_year  = r.anchor_year
    and pr.anchor_period = r.anchor_period
    and pr.member_year  = r.member_year
    and pr.member_week  = r.member_week
where r.id <= 13
  );
  