{# ----------------------------------------------------------------------------
   Emits the 10 percentage columns + 2 SCD columns, a 1:1 port of
   SnopReviewMonthlyDto.setComputedValues() / SnopReviewWeeklyDto.setComputedValues().

   Expects these columns to already exist in the surrounding SELECT scope with
   these exact names: salfo, stm, fdis_plan, sta, fdos_plan, fdos_upd, std,
   fdis_upd, fdis_conf, stock_ibn, stock_subdist, avg5sta, avg5stm.

   The weekly mart binds Week-1 values to the base names (salfo, sta, ...), so the
   same macro yields the Week-1-consistent percentages the Java weekly view shows.

   Each guard reproduces the Java ternary exactly (note the zero-checks differ per
   formula, e.g. persen_salfo_vs_stm_gap only guards the denominator fdis_plan).
---------------------------------------------------------------------------- #}
{% macro computed_metrics() -%}
    case when salfo_base.fdis_plan = 0 then 0.0
         else ((salfo_base.stm - salfo_base.salfo) / salfo_base.fdis_plan) * 100 end
        as persen_salfo_vs_stm_gap,

    case when salfo_base.stm = 0 or salfo_base.salfo = 0 then 0.0
         else (salfo_base.stm / salfo_base.salfo) * 100 end
        as persen_sl_salfo,

    case when salfo_base.fdis_plan = 0 then 0.0
         else ((salfo_base.sta - salfo_base.fdos_plan) / salfo_base.fdis_plan) * 100 end
        as persen_fdos_vs_sta_gap,

    case when salfo_base.fdos_plan = 0 or salfo_base.sta = 0 then 0.0
         else (salfo_base.sta / salfo_base.fdos_plan) * 100 end
        as persen_sl_fdos,

    case when salfo_base.fdos_upd = 0 or salfo_base.sta = 0 then 0.0
         else (salfo_base.sta / salfo_base.fdos_upd) * 100 end
        as persen_fdos_upd_vs_sta,

    case when salfo_base.fdis_plan = 0 then 0.0
         else ((salfo_base.std - salfo_base.fdis_plan) / salfo_base.fdis_plan) * 100 end
        as persen_fdis_vs_std_gap,

    case when salfo_base.fdis_plan = 0 or salfo_base.std = 0 then 0.0
         else (salfo_base.std / salfo_base.fdis_plan) * 100 end
        as persen_sl_fdis,

    case when salfo_base.fdis_upd = 0 or salfo_base.std = 0 then 0.0
         else (salfo_base.std / salfo_base.fdis_upd) * 100 end
        as persen_fdis_upd_vs_std,

    case when salfo_base.std = 0 or salfo_base.fdis_conf = 0 then 0.0
         else (salfo_base.std / salfo_base.fdis_conf) * 100 end
        as persen_fdis_conf_vs_std,

    case when salfo_base.fdis_conf = 0 or salfo_base.fdis_plan = 0 then 0.0
         else (salfo_base.fdis_conf / salfo_base.fdis_plan) * 100 end
        as persen_fdis_plan_vs_fdis_conf,

    case when salfo_base.stock_ibn = 0 or salfo_base.avg5sta = 0 then 0.0
         else salfo_base.stock_ibn / salfo_base.avg5sta * 6 end
        as scd_ibn,

    case when salfo_base.stock_subdist = 0 or salfo_base.avg5stm = 0 then 0.0
         else salfo_base.stock_subdist / salfo_base.avg5stm * 6 end
        as scd_subdist
{%- endmacro %}
