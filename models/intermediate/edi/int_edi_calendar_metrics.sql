{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']}
    ]
) }}

-- These four metrics are calendar-keyed, not submit-keyed. The existing senior
-- monthly mart already computes their period totals with the agreed WH channel.
-- Its shared spine also contains rows belonging only to other monitoring
-- metrics; those all-zero rows must not create artificial EDI output grain.
select
    sp.year_upload,
    sp.period_upload,
    m.channel as divisi,
    m.year as year_tujuan,
    m.period as periode_tujuan,
    m.pcode,
    m.div_id,
    m.country_id as ct_id,
    sum(coalesce(m.fdis_upd, 0)) as fdis_update,
    sum(coalesce(m.stock_ibn, 0)) as stock_ibn,
    sum(coalesce(m.std, 0)) as std,
    sum(coalesce(m.sta, 0)) as sta
from {{ ref('int_edi_submit_periods') }} sp
join {{ ref('mart_monitoring_sff_monthly') }} m
  on m.year = sp.year_tujuan
 and m.period = sp.periode_tujuan
where m.channel in ('GT', 'MT')
  and m.country_id = '{{ var("local_country_id") }}'
  and (
       coalesce(m.fdis_upd, 0) <> 0
    or coalesce(m.stock_ibn, 0) <> 0
    or coalesce(m.std, 0) <> 0
    or coalesce(m.sta, 0) <> 0
  )
group by
    sp.year_upload,
    sp.period_upload,
    m.channel,
    m.year,
    m.period,
    m.pcode,
    m.div_id,
    m.country_id
