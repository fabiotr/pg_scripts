SELECT  usename, state, count(1), avg(current_timestamp - query_start) avg_query, max(current_timestamp - query_start) max_query, avg(current_timestamp - xact_start) avg_xact, max(current_timestamp - xact_start) max_xact
FROM pg_stat_activity
WHERE
    backend_type = 'client backend' AND
    pid != pg_backend_pid()
GROUP BY state, usename
ORDER BY 1,2;
