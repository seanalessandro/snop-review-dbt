{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

with last_week as (
    select year, period, max(week) as week
    from {{ ref('stg_m_cycle2') }}
    group by year, period
),

product as (
    select pcode, div_id, ct_id
    from {{ ref('int_product') }}
    where ct_id = '{{ var("local_country_id") }}'
)

select
    sp.year_upload,
    sp.period_upload,
    d.divisi,
    s.year as year_tujuan,
    s.period as periode_tujuan,
    s.pcode,
    p.div_id,
    s.ct_id,
    sum(coalesce(s.qty, 0)) as stock_subdist
from {{ ref('stg_edi_t_stock_dist_fdos') }} s
join {{ ref('int_edi_submit_periods') }} sp
  on sp.year_tujuan = s.year
 and sp.periode_tujuan = s.period
join last_week lw
  on lw.year = s.year
 and lw.period = s.period
 and lw.week = s.week
join product p
  on p.pcode = s.pcode
 and p.ct_id = s.ct_id
join {{ ref('stg_edi_m_distributor') }} d
  on d.ct_id = s.ct_id
 and d.distributor_id = s.sub_id
where s.ct_id = '{{ var("local_country_id") }}'
group by
    sp.year_upload,
    sp.period_upload,
    d.divisi,
    s.year,
    s.period,
    s.pcode,
    p.div_id,
    s.ct_id

