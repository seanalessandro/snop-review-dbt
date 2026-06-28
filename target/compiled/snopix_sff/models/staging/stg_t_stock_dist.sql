-- Distributor stock. Anchored to the period's last loaded week. sub_id -> channel,
-- plus the m_mapping_product whitelist.
select
    year,
    period,
    week,
    pcode,
    sub_id,
    cast(qty as numeric) as qty
from "logistic"."logistic"."t_stock_dist"