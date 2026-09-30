SELECT
  client_addr AS "Client Address",
  state       AS "Status",
  count(1)    AS "Qt",
  avg(CURRENT_TIMESTAMP - query_start) AS "Avg query",
  max(CURRENT_TIMESTAMP - query_start) AS "Max query",
  avg(CURRENT_TIMESTAMP - xact_start)  AS "Avg xact",
  max(CURRENT_TIMESTAMP - xact_start)  AS "Max xact"
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY state, client_addr
ORDER BY 1,2;
