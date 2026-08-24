{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

with channels as (
    select 'GT'::text as divisi
    union all
    select 'MT'::text as divisi
),

cycle as (
    select distinct year, period, week
    from {{ ref('stg_m_cycle2') }}
),

product as (
    select pcode, div_id, ct_id
    from {{ ref('int_product') }}
    where ct_id = '{{ var("local_country_id") }}'
),

base as (
    select
        f.year_upload,
        f.period_upload,
        c.year as year_tujuan,
        c.period as periode_tujuan,
        f.pcode,
        p.div_id,
        f.ct_id,
        sum(coalesce(f.qty, 0)) as fdis_confirm
    from {{ ref('stg_edi_t_fdis_confirm') }} f
    join cycle c
      on c.year = f.year
     and c.week = f.week
    join product p
      on p.pcode = f.pcode
     and p.ct_id = f.ct_id
    where f.ct_id = '{{ var("local_country_id") }}'
    group by
        f.year_upload,
        f.period_upload,
        c.year,
        c.period,
        f.pcode,
        p.div_id,
        f.ct_id
)

-- The source has no GT/MT dimension. The same confirmed quantity is exposed
-- for both selectable EDI channels instead of being arbitrarily split.
select
    b.year_upload,
    b.period_upload,
    ch.divisi,
    b.year_tujuan,
    b.periode_tujuan,
    b.pcode,
    b.div_id,
    b.ct_id,
    b.fdis_confirm
from base b
cross join channels ch

