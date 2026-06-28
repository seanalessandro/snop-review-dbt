-- Country master in the main (logistic) schema.
select
    ct_id,
    ct_nm
from {{ source('logistic', 'm_country') }}
