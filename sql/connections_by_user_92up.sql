SELECT  usename, state, count(1), avg(CURRENT_TIMESTAMP - query_start) avg_query, max(CURRENT_TIMESTAMP - query_start) max_query, avg(CURRENT_TIMESTAMP - xact_start) avg_xact, max(CURRENT_TIMESTAMP - xact_start) max_xact
FROM pg_stat_activity
WHERE
    pid != pg_backend_pid()
GROUP BY state, usename
ORDER BY 1,2;
