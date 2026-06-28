-- SALFO: distributor-channel, upload-keyed, period weeks only.
-- Grain: (year, period, channel, pcode, ct_id). channel in ('GT','MT').
select
    pw.anchor_year   as year,
    pw.anchor_period as period,
    dist.sls_div     as channel,
    s.pcode,
    p.ct_id,
    sum(case when pw.in_period   then s.qty else 0 end) as salfo,
    sum(case when pw.wk_rank = 1 then s.qty else 0 end) as salfo_w1
from {{ ref('stg_t_salfo_confirm_d') }} s
join {{ ref('int_period_window') }} pw
    on  s.year = pw.member_year
    and s.week = pw.member_week
    and s.year_upload   = pw.prev_year
    and s.period_upload = pw.prev_period
join {{ ref('int_product') }} p on s.pcode = p.pcode
join {{ ref('stg_m_distributor') }} dist
    on s.sub_id = dist.distributor_id and dist.sls_div in ('GT', 'MT')
where pw.in_period
group by pw.anchor_year, pw.anchor_period, dist.sls_div, s.pcode, p.ct_id
