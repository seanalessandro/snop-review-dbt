{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

-- Direct aggregation is deliberate. The senior trend mart cross-creates GT and
-- MT rows for every SKU, including zero rows for a channel that had no source
-- data. EDI must preserve only the channel grain actually present in SALFO.
with cycle as (
    select distinct year, period, week
    from {{ ref('stg_m_cycle2') }}
),

product as (
    select pcode, div_id, ct_id
    from {{ ref('int_product') }}
    where ct_id = '{{ var("local_country_id") }}'
),

salfo_by_sku as (
    select
        s.year_upload,
        s.period_upload,
        d.divisi,
        c.year as year_tujuan,
        c.period as periode_tujuan,
        s.pcode,
        p.div_id,
        p.ct_id,
        sum(coalesce(s.qty, 0)) as salfo_qty
    from {{ ref('stg_t_salfo_confirm_d') }} s
    join cycle c
      on c.year = s.year
     and c.week = s.week
    join product p
      on p.pcode = s.pcode
    join {{ ref('stg_edi_m_distributor') }} d
      on d.distributor_id = s.sub_id
     and d.ct_id = p.ct_id
    group by
        s.year_upload,
        s.period_upload,
        d.divisi,
        c.year,
        c.period,
        s.pcode,
        p.div_id,
        p.ct_id
)

select
    s.year_upload,
    s.period_upload,
    s.divisi,
    s.year_tujuan,
    s.periode_tujuan,
    s.pcode,
    s.div_id,
    s.ct_id,
    s.salfo_qty,
    s.salfo_qty * coalesce(pr.price, 0) as salfo_value,
    coalesce(pr.price, 0) <= 0 and s.salfo_qty <> 0 as price_missing
from salfo_by_sku s
left join {{ ref('stg_edi_m_price_divisi') }} pr
  on pr.pcode = s.pcode
 and pr.divisi = s.divisi
 and pr.year = s.year_tujuan
