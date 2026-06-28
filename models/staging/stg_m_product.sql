-- Product master. Hierarchy keys + country marker drive every metric join.
select
    pcode,
    div_id,
    brand_id,
    subbrand_id,
    parent_id,
    ct_id,
    pcodename
from {{ source('logistic', 'm_product') }}
where div_id is not null
