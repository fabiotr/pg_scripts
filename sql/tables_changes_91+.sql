SELECT
    schemaname AS "Schema",
    relname AS "Table",
    lpad(to_char(n_live_tup,            'FM999G999G999G999'),15) AS "Rows",
    lpad(to_char(n_tup_ins / reset_days,'FM999G999G999G999'),15) AS "INSERTs/Day",
    lpad(to_char(n_tup_del / reset_days,'FM999G999G999G999'),15)  AS "DELETEs/Day",
    lpad(to_char(n_tup_upd / reset_days,'FM999G999G999G999'),15)  AS "UPDATEs/Day",
    lpad(to_char((n_tup_ins + n_tup_upd + n_tup_del)             / reset_days,'FM999G999G999G999'),15) AS "Changes/Day",
    lpad(to_char((coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)) / reset_days,'FM999G999G999G999'),15) AS "New rows/Day",
    lpad(to_char(coalesce(seq_scan,0) + coalesce(idx_scan,0)     / reset_days,'FM999G999G999G999'),15) AS "Reads/Day",
    CASE
        WHEN (coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) = 0 THEN NULL
	ELSE lpad(to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0))::numeric / ((coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0))),'FM999G990D0'),9) END AS "R / W",
    lpad(to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0) + coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) / reset_days,'FM999G999G999G999'),15) AS "IOPS / Day"
FROM
    pg_stat_user_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days
    	FROM pg_stat_database
    	WHERE datname = current_database()) AS r
ORDER BY  n_tup_ins + n_tup_upd + n_tup_del desc
LIMIT 20;
