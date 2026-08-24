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
        p.ct_id,
        sum(coalesce(f.qty, 0)) as fdis_confirm_update
    from {{ ref('stg_edi_t_fdis_confirm_update') }} f
    join cycle c
      on c.year = f.year
     and c.week = f.week
    -- t_fdis_confirm_update has no ct_id column (unlike t_fdis_confirm), so
    -- product is joined by pcode alone -- correct only if pcode is unique
    -- across countries in this source. Confirmed safe for now: this table
    -- has only ever been loaded with local plant data (pcode/plant ranges
    -- match the local country in sample data). Re-verify with the data
    -- owner before a second country goes live, since nothing here or in
    -- this model's tests would catch a cross-country pcode collision.
    join product p
      on p.pcode = f.pcode
    group by
        f.year_upload,
        f.period_upload,
        c.year,
        c.period,
        f.pcode,
        p.div_id,
        p.ct_id
)

select
    b.year_upload,
    b.period_upload,
    ch.divisi,
    b.year_tujuan,
    b.periode_tujuan,
    b.pcode,
    b.div_id,
    b.ct_id,
    b.fdis_confirm_update
from base b
cross join channels ch

