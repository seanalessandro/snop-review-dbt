select
    brand_id,
    brand_nm
from {{ source('logistic', 'm_brand') }}
