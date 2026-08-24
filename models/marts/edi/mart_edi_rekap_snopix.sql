{{ config(
    materialized='table',
    schema='mart',
    tags=['edi_rekap_snopix'],
    indexes=[
      {'columns': ['year_upload', 'period_upload', 'divisi', 'sbu']},
      {'columns': ['year_upload', 'period_upload', 'divisi', 'div_id']},
      {'columns': ['year_tujuan', 'periode_tujuan', 'pcode']},
      {
        'columns': ['year_upload', 'period_upload', 'divisi', 'year_tujuan', 'periode_tujuan', 'pcode', 'ct_id'],
        'unique': true
      }
    ]
) }}

select
    a.divisi,
    case
        when p.div_id = '16' then 'HOMECARE'
        else upper(trim(p.div_nm))
    end as sbu,
    a.year_upload,
    a.period_upload,
    a.year_tujuan,
    a.periode_tujuan,
    a.pcode,
    p.pcodename as sku_name,
    a.div_id,
    a.ct_id,
    a.target,
    a.salfo_qty,
    a.salfo_value,
    a.price_missing,
    a.fdos_plan,
    a.fdis_plan,
    a.fdis_confirm,
    a.fdis_confirm_update,
    a.fdis_update,
    a.stock_subdist,
    a.stock_ibn,
    a.std,
    a.sta,
    a.stm
from {{ ref('int_edi_assembled') }} a
join {{ ref('int_product') }} p
  on p.pcode = a.pcode
 and p.ct_id = a.ct_id

