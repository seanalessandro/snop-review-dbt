-- Period/week calendar. Drives period-week membership, the trailing 13w/5w
-- moving-average windows, and the previous-period (upload key) lookup.
select
    year,
    period,
    week
from {{ source('logistic', 'm_cycle2') }}
