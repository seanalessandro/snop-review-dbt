{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

with product as (
    select pcode, div_id, ct_id
    from {{ ref('int_product') }}
    where ct_id = '{{ var("local_country_id") }}'
)

select
    sp.year_upload,
    sp.period_upload,
    d.divisi,
    t.year as year_tujuan,
    t.period as periode_tujuan,
    t.pcode,
    p.div_id,
    t.ct_id,
    sum(coalesce(t.amount, 0)) as target
from {{ ref('stg_edi_t_target_subdist') }} t
join {{ ref('int_edi_submit_periods') }} sp
  on sp.year_tujuan = t.year
 and sp.periode_tujuan = t.period
join product p
  on p.pcode = t.pcode
 and p.ct_id = t.ct_id
join {{ ref('stg_edi_m_distributor') }} d
  on d.ct_id = t.ct_id
 and d.distributor_id = t.sub_id
where t.ct_id = '{{ var("local_country_id") }}'
group by
    sp.year_upload,
    sp.period_upload,
    d.divisi,
    t.year,
    t.period,
    t.pcode,
    p.div_id,
    t.ct_id

