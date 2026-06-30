{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['metric', 'channel', 'target_year', 'target_period']},
      {'columns': ['metric', 'channel', 'target_period']},
      {'columns': ['submit_year', 'submit_period']}
    ]
) }}

with
cyc  as ( select year, period, week from {{ ref('stg_m_cycle2') }} ),
prod as ( select pcode, div_id, brand_id, subbrand_id, parent_id, ct_id from {{ ref('int_product') }} ),
dist as ( select distributor_id, sls_div from {{ ref('stg_m_distributor') }} where sls_div in ('GT', 'MT') ),
chan as ( select unnest(array['GT', 'MT', 'ALL']) as channel ),

-- ---- SALFO (distributor channel) ----
salfo_cm as (
    select
        c.year   as target_year,
        c.period as target_period,
        s.year_upload   as submit_year,
        s.period_upload as submit_period,
        s.pcode, p.div_id, p.brand_id, p.subbrand_id, p.parent_id, p.ct_id,
        sum(case when d.sls_div = 'GT' then s.qty else 0 end) as gt,
        sum(case when d.sls_div = 'MT' then s.qty else 0 end) as mt
    from {{ ref('stg_t_salfo_confirm_d') }} s
    join cyc  c on s.year = c.year and s.week = c.week
    join prod p on s.pcode = p.pcode
    join dist d on s.sub_id = d.distributor_id
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
salfo as (
    select target_year, target_period, submit_year, submit_period, 'SALFO' as metric,
        ch.channel, pcode, div_id, brand_id, subbrand_id, parent_id, ct_id,
        case ch.channel when 'GT' then gt when 'MT' then mt else gt + mt end as value
    from salfo_cm cross join chan ch
),

-- ---- FDOS (distributor channel; period-only, target_year = NULL) ----
fdos_cm as (
    select
        cast(null as integer) as target_year,
        h.period              as target_period,
        h.year_upload   as submit_year,
        h.period_upload as submit_period,
        h.pcode, p.div_id, p.brand_id, p.subbrand_id, p.parent_id, p.ct_id,
        sum(case when d.sls_div = 'GT' then h.qty_adj else 0 end) as gt,
        sum(case when d.sls_div = 'MT' then h.qty_adj else 0 end) as mt
    from {{ ref('stg_t_fdos_h') }} h
    join prod p on h.pcode = p.pcode
    join dist d on h.sub_id = d.distributor_id
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
fdos as (
    select target_year, target_period, submit_year, submit_period, 'FDOS' as metric,
        ch.channel, pcode, div_id, brand_id, subbrand_id, parent_id, ct_id,
        case ch.channel when 'GT' then gt when 'MT' then mt else gt + mt end as value
    from fdos_cm cross join chan ch
),

-- ---- FDIS (local marketing GT/MT + export agnostic) ----
fdis_local as (
    select
        c.year as target_year, c.period as target_period,
        m.year_upload as submit_year, m.period_upload as submit_period,
        m.pcode, p.div_id, p.brand_id, p.subbrand_id, p.parent_id, p.ct_id,
        sum(case when m.sls_div = 'GT' then m.qty_final else 0 end) as gt,
        sum(case when m.sls_div = 'MT' then m.qty_final else 0 end) as mt,
        cast(0 as numeric) as exp
    from {{ ref('stg_t_fdis_marketing_d') }} m
    join cyc  c on m.year = c.year and m.week = c.week
    join prod p on m.pcode = p.pcode and p.ct_id = '{{ var("local_country_id") }}'
    where m.sls_div in ('GT', 'MT')
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
fdis_export as (
    select
        c.year as target_year, c.period as target_period,
        e.year_upload as submit_year, e.period_upload as submit_period,
        e.pcode, p.div_id, p.brand_id, p.subbrand_id, p.parent_id, p.ct_id,
        cast(0 as numeric) as gt,
        cast(0 as numeric) as mt,
        sum(e.qty_adj) as exp
    from {{ ref('stg_t_fdis_export_d') }} e
    join cyc  c on e.year = c.year and e.week = c.week
    join prod p on e.pcode = p.pcode and p.ct_id = '{{ var("export_country_id") }}'
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
fdis_cm as (
    select * from fdis_local
    union all
    select * from fdis_export
),
fdis as (
    select target_year, target_period, submit_year, submit_period, 'FDIS' as metric,
        ch.channel, pcode, div_id, brand_id, subbrand_id, parent_id, ct_id,
        case ch.channel
            when 'GT' then gt + exp
            when 'MT' then mt + exp
            else gt + mt + exp
        end as value
    from fdis_cm cross join chan ch
),

-- ---- MPS (channel-agnostic) ----
mps_cm as (
    select
        c.year as target_year, c.period as target_period,
        m.year_upload as submit_year, m.period_upload as submit_period,
        m.pcode, p.div_id, p.brand_id, p.subbrand_id, p.parent_id, p.ct_id,
        sum(m.qty_adj) as val
    from {{ ref('stg_t_upload_mps') }} m
    join cyc  c on m.year = c.year and m.week = c.week
    join prod p on m.pcode = p.pcode
    where m.flag_proc = 1
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
mps as (
    select target_year, target_period, submit_year, submit_period, 'MPS' as metric,
        ch.channel, pcode, div_id, brand_id, subbrand_id, parent_id, ct_id, val as value
    from mps_cm cross join chan ch
),

-- ---- FDIS CONFIRM (channel-agnostic) ----
fdisconf_cm as (
    select
        c.year as target_year, c.period as target_period,
        f.year_upload as submit_year, f.period_upload as submit_period,
        f.pcode, p.div_id, p.brand_id, p.subbrand_id, p.parent_id, p.ct_id,
        sum(f.qty) as val
    from {{ ref('stg_t_fdis_confirm') }} f
    join cyc  c on f.year = c.year and f.week = c.week
    join prod p on f.pcode = p.pcode
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),
fdisconf as (
    select target_year, target_period, submit_year, submit_period, 'FDISCONF' as metric,
        ch.channel, pcode, div_id, brand_id, subbrand_id, parent_id, ct_id, val as value
    from fdisconf_cm cross join chan ch
)

select * from salfo
union all select * from fdos
union all select * from fdis
union all select * from mps
union all select * from fdisconf
