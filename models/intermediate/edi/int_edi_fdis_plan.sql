{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

with cycle as (
    select distinct year, period, week
    from {{ ref('stg_m_cycle2') }}
),

product as (
    select pcode, div_id, ct_id
    from {{ ref('int_product') }}
    where ct_id = '{{ var("local_country_id") }}'
)

-- Direct aggregation prevents the senior trend mart from creating a zero GT
-- row for an MT-only SKU (and vice versa).
select
    f.year_upload,
    f.period_upload,
    upper(trim(f.sls_div)) as divisi,
    c.year as year_tujuan,
    c.period as periode_tujuan,
    f.pcode,
    p.div_id,
    p.ct_id,
    sum(coalesce(f.qty_final, 0)) as fdis_plan
from {{ ref('stg_t_fdis_marketing_d') }} f
join cycle c
  on c.year = f.year
 and c.week = f.week
join product p
  on p.pcode = f.pcode
where upper(trim(f.sls_div)) in ('GT', 'MT')
group by
    f.year_upload,
    f.period_upload,
    upper(trim(f.sls_div)),
    c.year,
    c.period,
    f.pcode,
    p.div_id,
    p.ct_id
