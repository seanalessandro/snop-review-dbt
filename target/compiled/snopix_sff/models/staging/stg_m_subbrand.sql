-- Subbrand is keyed by (brand_id, subbrand_id) — matches the Java join
-- p.brand_id = s.brand_id and p.subbrand_id = s.subbrand_id.
select
    brand_id,
    subbrand_id,
    subbrand_nm
from "logistic"."logistic"."m_subbrand"