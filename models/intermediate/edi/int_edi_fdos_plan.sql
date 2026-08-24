{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

with fdos_channel as (
    select
        acc_id,
        div_id,
        case
            when acc_id = 'MT' then 'MT'
            when acc_id in ('AC0001', 'AC0002', 'AC0003', 'AC0004') then 'GT'
        end as divisi
    from {{ ref('stg_edi_m_acc_div') }}
),

product as (
    select pcode, div_id, ct_id
    from {{ ref('int_product') }}
    where ct_id = '{{ var("local_country_id") }}'
)

-- FDOS lives at subdist/account level, but subdist is not part of the EDI
-- output grain. qty_adj is therefore summed to submit/channel/target/SKU.
select
    f.year_upload,
    f.period_upload,
    fc.divisi,
    f.year as year_tujuan,
    f.period as periode_tujuan,
    f.pcode,
    p.div_id,
    f.ct_id,
    sum(coalesce(f.qty_adj, 0)) as fdos_plan
from {{ ref('stg_edi_t_fdos_h') }} f
join product p
  on p.pcode = f.pcode
 and p.ct_id = f.ct_id
join fdos_channel fc
  on fc.acc_id = f.acc_id
 and fc.div_id = p.div_id
where f.ct_id = '{{ var("local_country_id") }}'
group by
    f.year_upload,
    f.period_upload,
    fc.divisi,
    f.year,
    f.period,
    f.pcode,
    p.div_id,
    f.ct_id

