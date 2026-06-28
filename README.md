# snopix_sff — dbt (TRANSFORM-only)

Pre-computes **Monitoring SFF Monthly & Weekly** into two mart tables so the Spring
Boot API stops building the ~2,800-line query in
`MonitoringSffRepositoryImpl.viewDataMonitoringMonthly()` / `viewDataMonitoringWeekly()`
at request time.

**No Extract/Load step.** dbt connects directly to the operational Postgres and reads
the live `logistic` / `export` schemas (TRANSFORM only). It writes three output schemas:

```
<schema>_staging        thin views over the source tables (casts/renames)
<schema>_intermediate   the heavy aggregations (one table per metric)
<schema>_mart           mart_monitoring_sff_monthly + mart_monitoring_sff_weekly
```

## Layout

```
dbt_project.yml          vars: src_schema, export_schema, local/export country ids
profiles.example.yml     copy to ~/.dbt/profiles.yml
packages.yml             dbt_utils

models/staging/          27 stg_* views + _sources.yml
models/intermediate/
  int_product            product + hierarchy names + resolved country name
  int_warehouse_channel  wh_id -> GT/MT
  int_period_window      calendar backbone: period weeks, 13w/5w windows, prev period
  int_salfo int_sta int_std int_stm
  int_fdos_plan int_fdos_upd
  int_fdis_plan int_fdis_upd int_fdis_conf int_fdis_conf_upd
  int_mps int_stock_dist int_stock_ibn
  int_sff_assembled      wide pivot: every metric as _gt/_mt(/_exp) + W1..W5
models/marts/
  mart_monitoring_sff_monthly
  mart_monitoring_sff_weekly
macros/                  channel_pick, fdis_plan_pick, computed_metrics
analyses/                validate_channel_exclusivity.sql
```

## Run

```bash
dbt deps
# point at a tenant schema if not the default 'logistic':
dbt build --vars '{src_schema: logistic, export_schema: export}'
# or layer by layer:
dbt run --select staging
dbt run --select intermediate
dbt run --select marts
dbt test
```

## How a metric maps to the Java SQL

| metric | source | channel via | upload-keyed | windows / pivots |
|---|---|---|---|---|
| salfo | t_salfo_confirm_d | distributor sub_id | yes (prev) | period + W1 |
| sta | t_omset | warehouse wh_id | no | period + 13w/5w + W1 |
| std | t_fdis_actual | warehouse wh_id | no | period + 13w/5w + W1 |
| stm | t_tmp_stm / _mt | source table (GT/MT) | no | period + 13w/5w + W1 |
| fdos_plan | t_fdos_h (+t_fdos_d2 for W1) | distributor | yes (prev) | period + W1 |
| fdos_upd | t_fdos_update_d | distributor | no | period + W1..W5 |
| fdis_plan | t_fdis_marketing_d + export.t_fdis_export_d | local: sls_div; export: none | yes (prev) | period + W1..W5 |
| fdis_upd | t_fdis_update_d | warehouse | no | period + W1..W5 |
| fdis_conf | t_fdis_confirm | none (agnostic) | yes (prev) | period + W1..W5 |
| fdis_conf_upd | t_fdis_confirm_update (Σ day1..6) | none | yes (prev) | period + W1..W5 |
| mps | t_upload_mps (flag_proc=1) | none | yes (prev) | period + W1..W5 |
| stock_dist | t_stock_dist (+mapping) | distributor | no | period last week |
| stock_ibn | t_stock_wh | warehouse | no | period last week |

"prev" = previous existing period (Java `util.getPrevYearAndPeriod`), modelled as
`prev_year/prev_period` in `int_period_window`.

## Deliberate design decisions / caveats (read before trusting parity)

1. **pcode grain + channel column.** The mart stores one row per
   (year, period, channel, pcode, ct_id). The API rolls up to div/brand/subbrand/parent
   with `GROUP BY` + `SUM`. Additive metrics are exact after roll-up.

2. **Moving averages use a fixed window denominator** (n13/n5 = number of weeks in the
   window per the cycle). Java divides by the number of weeks that actually had data at
   the *group* level. The two agree whenever the group has data in every window week
   (the normal case for div/brand), and the fixed form is what keeps averages additive
   across pcode/channel roll-ups. Expect tiny differences only for sparse SKUs.

3. **'ALL' channel = GT + MT.** Exact only if warehouses/distributors are channel-exclusive.
   Run `analyses/validate_channel_exclusivity.sql` — it must return zero rows.

4. **currentPeriod = 'N' semantics only.** The trailing window ends at the period's last
   week (historical branch). The live `currentPeriod='Y'` branch (m_cycle3, window shifted
   back one week, stock anchored to the latest loaded week) is **not** modelled — keep
   serving the in-progress period from the existing live query, or add a parallel
   `int_period_window_current`.

5. **Percentages are per-pcode.** `persen_*` and `scd_*` are ratios, not additive. When the
   API aggregates to a hierarchy level it must **recompute** them from the summed base
   metrics (re-apply the `computed_metrics` formulas in the API SELECT), exactly as Java's
   `setComputedValues()` runs on the aggregated row. The per-pcode values are correct only
   for the SKU-level view.

6. **Zero-activity products are omitted.** The spine is data-driven (keys present in the
   facts). Java starts from `distinct m_product` and LEFT JOINs, so it emits all-zero rows
   for inactive products/groups. Harmless for SUM roll-ups; if the SKU view must list
   inactive SKUs, cross join `int_product` with the period spine instead.

7. **fdis_upd is country-agnostic in Java** (joined without ct_id, which double-attaches a
   div total across countries at aggregated grain). Here it is carried at pcode grain and
   rolls up once per group — i.e. the intended total. This is intentionally *more* correct.

## API change (out of scope for dbt, for reference)

`viewDataMonitoringMonthly()` becomes, in effect:

```sql
select <group key> as ket,
       sum(salfo) as salfo, sum(sta) as sta, sum(fdos_plan) as fdos_plan, ...
from <schema>_mart.mart_monitoring_sff_monthly
where year = :year and period = :period and channel = :channel
  and ct_id in (:listCountry) and div_id in (:listDivisi) ...
group by <group key>
```

then re-apply the `computed_metrics` ratio formulas on the aggregated row (replacing
`setComputedValues()`).
