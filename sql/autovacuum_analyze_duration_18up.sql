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
    to_char(t.last_analyze,     'YYYY-MM-DD HH24:MI:SS') AS "A Last",
    to_char(t.last_autoanalyze, 'YYYY-MM-DD HH24:MI:SS') AS "AA Last",
    to_char(t.analyze_count     / sa.days_since_reset, 'FM999G990D00') AS "A Count/Day",
    to_char(t.autoanalyze_count / sa.days_since_reset, 'FM999G990D00') AS "AA Count/Day",
    to_char((t.total_analyze_time / sa.days_since_reset) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "A Time/Day",
    to_char((t.total_autoanalyze_time / sa.days_since_reset) * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "AA Time/Day",
    CASE t.analyze_count WHEN 0 THEN NULL
        ELSE to_char((t.total_analyze_time / t.analyze_count) * INTERVAL '1 millisecond', 'HH24:MI:SS.MS') END AS "A Avg Time",
    CASE t.autoanalyze_count WHEN 0 THEN NULL
        ELSE to_char((t.total_autoanalyze_time / t.autoanalyze_count) * INTERVAL '1 millisecond', 'HH24:MI:SS.MS') END AS "AA Avg Time"
FROM
    pg_stat_user_tables t
    CROSS JOIN stats_age sa
WHERE
    t.analyze_count > 0 OR t.autoanalyze_count > 0
ORDER BY t.total_analyze_time + t.total_autoanalyze_time DESC
LIMIT 20;
