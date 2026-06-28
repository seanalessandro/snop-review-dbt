select
    parent_id,
    parent_nm
from {{ source('logistic', 'm_parent') }}
