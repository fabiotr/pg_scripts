SELECT
    s.schemaname AS "Schema",
    s.relname AS "Table",
    lpad(to_char(c.reltuples, 'FM999G999G999G999'),15) AS "Rows",
    lpad(to_char((coalesce(s.seq_tup_read,0) + coalesce(s.idx_tup_fetch,0)) / reset_days,'FM999G999G999G999'),15)
        || lpad(' (' || round(100 * (coalesce(s.seq_tup_read,0) + coalesce(s.idx_tup_fetch,0)) /
        nullif(sum(coalesce(s.seq_tup_read,0) + coalesce(s.idx_tup_fetch,0)) OVER (),0),1) || ' %)',9) AS "SELECT Rows/Day"
FROM
    pg_stat_all_tables s JOIN
	pg_class c ON relid = oid,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days
        FROM pg_stat_database
        WHERE datname = current_database()) AS r
WHERE
	s.schemaname != 'pg_toast' AND
    coalesce(s.seq_tup_read,0) + coalesce(s.idx_tup_fetch,0) > 0
ORDER BY coalesce(s.seq_tup_read,0) + coalesce(s.idx_tup_fetch,0) DESC
LIMIT 10;
