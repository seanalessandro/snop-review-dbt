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
    s.channel as divisi,
    s.year as year_tujuan,
    s.period as periode_tujuan,
    s.pcode,
    p.div_id,
    s.ct_id,
    sum(coalesce(s.stm, 0)) as stm
from {{ ref('int_stm') }} s
join {{ ref('int_edi_submit_periods') }} sp
  on sp.year_tujuan = s.year
 and sp.periode_tujuan = s.period
join product p
  on p.pcode = s.pcode
 and p.ct_id = s.ct_id
where s.ct_id = '{{ var("local_country_id") }}'
  and s.channel in ('GT', 'MT')
  and coalesce(s.stm, 0) <> 0
group by
    sp.year_upload,
    sp.period_upload,
    s.channel,
    s.year,
    s.period,
    s.pcode,
    p.div_id,
    s.ct_id
