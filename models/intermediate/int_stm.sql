-- STM: channel comes from the source TABLE (t_tmp_stm = GT, t_tmp_stm_mt = MT),
-- already normalized to integer year/week and tagged with `channel` in staging.
-- Period total + trailing 13w/5w moving averages + Week-1 value.
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
with stm as (
    select year, week, pcode, qty, channel from {{ ref('stg_t_tmp_stm') }}
    union all
    select year, week, pcode, qty, channel from {{ ref('stg_t_tmp_stm_mt') }}
)
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    stm.channel,
    stm.pcode,
    p.ct_id,
    sum(case when pw.in_period   then stm.qty else 0 end)                        as stm,
    sum(case when pw.wk_rank = 1 then stm.qty else 0 end)                        as stm_w1,
    sum(case when pw.in_w13 then stm.qty else 0 end) / nullif(max(pw.n13), 0)    as avg13stm,
    sum(case when pw.in_w5  then stm.qty else 0 end) / nullif(max(pw.n5), 0)     as avg5stm
from stm
join {{ ref('int_period_window') }} pw
    on stm.year = pw.member_year and stm.week = pw.member_week
join {{ ref('int_product') }} p on stm.pcode = p.pcode
group by pw.anchor_year, pw.anchor_period, stm.channel, stm.pcode, p.ct_id
