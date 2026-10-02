SELECT
    schemaname AS "Schema",
    relname AS "Table",
    --to_char(coalesce(seq_scan,0),'FM999G999G999G999') AS "Seq Scans",
    --to_char(coalesce(idx_scan,0) / reset_days,'FM999G999G999G999') AS "Idx Scans",
    lpad(to_char(n_live_tup,'FM999G999G999G999'), 16) AS "Rows",
    lpad(to_char(n_tup_ins, 'FM999G999G999G999'), 16) AS "INSERTs/Day",
    lpad(to_char(n_tup_del, 'FM999G999G999G999'), 16) AS "DELETEs/Day",
    lpad(to_char(n_tup_upd, 'FM999G999G999G999'), 16) AS "UPDATEs/Day",
    lpad(to_char((n_tup_ins + n_tup_upd + n_tup_del)            ,'FM999G999G999G999'), 16) AS "Changes",
    lpad(to_char((coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)),'FM999G999G999G999'), 16) AS "New rows",
    lpad(to_char(coalesce(seq_scan,0) + coalesce(idx_scan,0)    ,'FM999G999G999G999'), 16) AS "Reads",
    lpad(CASE 
        WHEN (coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) = 0 THEN NULL
	ELSE to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0))::numeric / ((coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0))),'FM999G990D0') END, 10) AS "R / W",
    lpad(to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0) + coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)),'FM999G999G999G999'), 16) AS "IOPS"
FROM pg_stat_user_tables
ORDER BY  n_tup_ins + n_tup_upd + n_tup_del DESC
LIMIT 20;
