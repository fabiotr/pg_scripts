SELECT
  client_addr AS "Client Address",
  state       AS "Status",
  count(1)    AS "Qt",
  avg(current_timestamp - query_start) AS "Avg query",
  max(current_timestamp - query_start) AS "Max query",
  avg(current_timestamp - xact_start)  AS "Avg xact",
  max(current_timestamp - xact_start)  AS "Max xact"
FROM pg_stat_activity
WHERE
    backend_type = 'client backend' AND
    pid != pg_backend_pid()
GROUP BY state, client_addr
ORDER BY 1,2;
