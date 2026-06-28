select
    div_id,
    div_nm
from {{ source('logistic', 'm_division') }}
