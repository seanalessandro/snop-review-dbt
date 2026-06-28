-- Country master in the export schema. Resolved with COALESCE(export, logistic)
-- in int_product, mirroring COALESCE(ec.ct_id, lc.ct_id) in the Java FROM block.
select
    ct_id,
    ct_nm
from "logistic"."export"."m_country"