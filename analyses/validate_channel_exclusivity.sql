-- Run with: dbt compile  (then execute the compiled SQL), or paste into psql.
--
-- The mart's 'ALL' channel assumes GT + MT, which is exact only when no warehouse
-- and no distributor belongs to BOTH channels. These two checks must return ZERO
-- rows for the 'ALL' totals to be trustworthy. If they return rows, the shared
-- warehouses/distributors are double-counted in 'ALL'.

-- 1) Warehouses mapped to both a GT and an MT distributor
select wh_id, count(distinct channel) as channels
from {{ ref('int_warehouse_channel') }}
group by wh_id
having count(distinct channel) > 1

union all

-- 2) Distributors flagged with more than one channel
select distributor_id::text as wh_id, count(distinct sls_div) as channels
from {{ ref('stg_m_distributor') }}
where sls_div in ('GT', 'MT')
group by distributor_id
having count(distinct sls_div) > 1
