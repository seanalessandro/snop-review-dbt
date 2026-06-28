-- Distinct warehouse -> channel ('GT'|'MT'), the warehouse-channel filter shared by
-- STA, STD, FDIS update and Stock IBN (Java whFilter: distinct wh_id from m_wh_dist
-- join m_distributor on sls_div in (channel)).
--
-- ASSUMPTION (channel exclusivity): a warehouse belongs to a single channel. If a
-- warehouse maps to both a GT and an MT distributor it yields two rows here, which
-- would double-count that warehouse in the 'ALL' channel of the mart. Validate with
-- analyses/validate_channel_exclusivity.sql before trusting 'ALL' totals.
select distinct
    wd.wh_id,
    d.sls_div as channel
from "logistic"."dwh_staging"."stg_m_wh_dist" wd
join "logistic"."dwh_staging"."stg_m_distributor" d
    on wd.distributor_id = d.distributor_id
where d.sls_div in ('GT', 'MT')