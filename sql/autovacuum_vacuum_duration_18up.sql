WITH stats_age AS (
    SELECT GREATEST(
        EXTRACT(EPOCH FROM (now() - COALESCE(sd.stats_reset, pg_postmaster_start_time()))) / 86400.0,
        1.0 / 86400.0
    ) AS days_since_reset
    FROM pg_stat_database sd
    WHERE sd.datname = current_database()
)
SELECT
    t.schemaname AS "Schema",
    t.relname    AS "Table",
    pg_size_pretty(pg_relation_size(t.relid)) AS "Size",
    to_char(t.last_vacuum,     'YYYY-MM-DD HH24:MI:SS') AS "V Last",
    to_char(t.last_autovacuum, 'YYYY-MM-DD HH24:MI:SS') AS "AV Last",
    to_char(t.vacuum_count     / sa.days_since_reset, 'FM999G990D00') AS "V Count/Day",
    to_char(t.autovacuum_count / sa.days_since_reset, 'FM999G990D00') AS "AV Count/Day",
    to_char((t.total_vacuum_time / sa.days_since_reset) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "V Time/Day",
    to_char((t.total_autovacuum_time / sa.days_since_reset) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "AV Time/Day",
    CASE t.vacuum_count WHEN 0 THEN NULL
        ELSE to_char((t.total_vacuum_time / t.vacuum_count) * INTERVAL '1 millisecond', 'HH24:MI:SS.MS') END AS "V Avg Time",
    CASE t.autovacuum_count WHEN 0 THEN NULL
        ELSE to_char((t.total_autovacuum_time / t.autovacuum_count) * INTERVAL '1 millisecond', 'HH24:MI:SS.MS') END AS "AV Avg Time",
    COALESCE(cd.option_value, current_setting('autovacuum_vacuum_cost_delay')) AS "Cost Delay",
    COALESCE(cl.option_value, current_setting('autovacuum_vacuum_cost_limit')) AS "Cost Limit"
FROM
    pg_stat_user_tables t
    CROSS JOIN stats_age sa
    JOIN pg_class c ON c.oid = t.relid
    LEFT JOIN pg_options_to_table(c.reloptions) cd ON cd.option_name = 'autovacuum_vacuum_cost_delay'
    LEFT JOIN pg_options_to_table(c.reloptions) cl ON cl.option_name = 'autovacuum_vacuum_cost_limit'
WHERE
    t.vacuum_count > 0 OR t.autovacuum_count > 0
ORDER BY t.total_vacuum_time + t.total_autovacuum_time DESC
LIMIT 20;
