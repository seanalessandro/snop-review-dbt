{# ----------------------------------------------------------------------------
   Channel multiplexing helpers used by the marts.

   The assembled intermediate stores each channel-specific metric as separate
   _gt / _mt columns. The mart cross joins a channel list aliased `ch` (values
   'GT','MT','ALL') and these macros pick the right value per output channel.

   ASSUMPTION (channel exclusivity): 'ALL' = GT + MT. This holds when no
   distributor/warehouse belongs to both channels (see int_warehouse_channel).
---------------------------------------------------------------------------- #}

{# Additive channel-specific metric: GT->gt, MT->mt, ALL->gt+mt #}
{% macro channel_pick(gt, mt) -%}
case ch.channel
    when 'GT' then coalesce({{ gt }}, 0)
    when 'MT' then coalesce({{ mt }}, 0)
    else coalesce({{ gt }}, 0) + coalesce({{ mt }}, 0)
end
{%- endmacro %}

{# FDIS plan: local leg is channel-specific, export leg is added to every channel.
   GT->gt+exp, MT->mt+exp, ALL->gt+mt+exp (export counted once). #}
{% macro fdis_plan_pick(gt, mt, exp) -%}
case ch.channel
    when 'GT' then coalesce({{ gt }}, 0) + coalesce({{ exp }}, 0)
    when 'MT' then coalesce({{ mt }}, 0) + coalesce({{ exp }}, 0)
    else coalesce({{ gt }}, 0) + coalesce({{ mt }}, 0) + coalesce({{ exp }}, 0)
end
{%- endmacro %}
