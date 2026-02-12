SELECT
    schemaname AS "Schema",
    relname AS "Table",
    --to_char(coalesce(seq_scan,0) / reset_days,'999G999G999G999') AS "Seq Scans/Day",
    --to_char(coalesce(idx_scan,0) / reset_days,'999G999G999G999') AS "Idx Scans/Day",
    to_char(n_live_tup,            '999G999G999G999') AS "Rows",
    to_char(n_tup_ins / reset_days,'999G999G999G999') AS "INSERTs/Day",
    to_char(n_tup_del / reset_days,'999G999G999G999') AS "DELETEs/Day",
    to_char(n_tup_upd / reset_days,'999G999G999G999') AS "UPDATEs/Day",
    to_char((n_tup_ins + n_tup_upd + n_tup_del)             / reset_days,'999G999G999G999') AS "Changes/Day",
    to_char((coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)) / reset_days,'999G999G999G999') AS "New rows/Day",
    to_char(coalesce(seq_scan,0) + coalesce(idx_scan,0)     / reset_days,'999G999G999G999') AS "Reads/Day",
    CASE 
        WHEN (coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) = 0 THEN NULL
	ELSE to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0))::numeric / ((coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0))),'999G990D9') END AS "R / W",
    to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0) + coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) / reset_days,'999G999G999G999') AS "IOPS / Day"
FROM
    pg_stat_user_tables,
    (SELECT EXTRACT(EPOCH FROM current_timestamp - stats_reset)::numeric/(60*60*24) AS reset_days
    	FROM pg_stat_database
    	WHERE datname = current_database()) AS r
ORDER BY  n_tup_ins + n_tup_upd + n_tup_del desc
LIMIT 20;
