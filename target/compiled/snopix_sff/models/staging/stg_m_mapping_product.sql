-- Distributor/product whitelist applied to Stock Dist
-- ( (sub_id, pcode) in (select distinct distributor_id, pcode from m_mapping_product) ).
select distinct
    distributor_id,
    pcode
from "logistic"."logistic"."m_mapping_product"