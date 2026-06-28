
  create view "logistic"."dwh_staging"."stg_t_tmp_stm__dbt_tmp"
    
    
  as (
    -- STM (GT channel). CRITICAL: year/week are stored as TEXT in this table
-- (Java joins d.year = cast(c2.year as text) and d.week = LPAD(cast(c2.week as text),2,'0')).
-- Normalize to integer here so every downstream join uses integer year/week.
select
    cast(trim(year) as integer) as year,
    cast(trim(week) as integer) as week,
    distributor_id,
    pcode,
    cast(qty as numeric)        as qty,
    'GT'::text                  as channel
from "logistic"."logistic"."t_tmp_stm"
  );