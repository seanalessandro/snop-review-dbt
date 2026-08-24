{{ config(
    materialized='table',
    schema='intermediate',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload']},
      {'columns': ['year_tujuan', 'periode_tujuan']}
    ]
) }}

with all_submit_periods as (
    select year_upload, period_upload, year_tujuan, periode_tujuan from {{ ref('int_edi_salfo') }}
    union all
    select year_upload, period_upload, year_tujuan, periode_tujuan from {{ ref('int_edi_fdos_plan') }}
    union all
    select year_upload, period_upload, year_tujuan, periode_tujuan from {{ ref('int_edi_fdis_plan') }}
    union all
    select year_upload, period_upload, year_tujuan, periode_tujuan from {{ ref('int_edi_fdis_confirm') }}
    union all
    select year_upload, period_upload, year_tujuan, periode_tujuan from {{ ref('int_edi_fdis_confirm_update') }}
)

select distinct
    year_upload,
    period_upload,
    year_tujuan,
    periode_tujuan
from all_submit_periods
where year_upload is not null
  and period_upload is not null
  and year_tujuan is not null
  and periode_tujuan is not null

