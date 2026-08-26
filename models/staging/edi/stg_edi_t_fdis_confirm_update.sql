{{ config(materialized='view', schema='staging', tags=['edi_rekap_snopix']) }}

select
    year_upload,
    period_upload,
    year,
    week,
    trim(pcode) as pcode,
    coalesce(day1, 0)
      + coalesce(day2, 0)
      + coalesce(day3, 0)
      + coalesce(day4, 0)
      + coalesce(day5, 0)
      + coalesce(day6, 0) as qty
from {{ source('edi_logistic', 't_fdis_confirm_update') }}
