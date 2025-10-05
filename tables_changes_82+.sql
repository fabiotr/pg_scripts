SELECT
    schemaname AS "Schema",
    relname AS "Table",
    --to_char(coalesce(seq_scan,0),'999G999G999G999') AS "Seq Scans",
    --to_char(coalesce(idx_scan,0) / reset_days,'999G999G999G999') AS "Idx Scans",
    to_char(n_tup_ins,'999G999G999G999') AS "INSERTs/Day",
    to_char(n_tup_del,'999G999G999G999') AS "DELETEs/Day",
    to_char(n_tup_upd,'999G999G999G999') AS "UPDATEs/Day",
    to_char((n_tup_ins + n_tup_upd + n_tup_del)            ,'999G999G999G999') AS "Changes",
    to_char((coalesce(n_tup_ins,0) - coalesce(n_tup_del,0)),'999G999G999G999') AS "New rows",
    to_char(coalesce(seq_scan,0) + coalesce(idx_scan,0)    ,'999G999G999G999') AS "Reads",
    CASE 
        WHEN (coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)) = 0 THEN NULL
	ELSE to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0))::numeric / ((coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0))),'999G990D9') END AS "R / W",
    to_char((coalesce(seq_scan,0) + coalesce(idx_scan,0) + coalesce(n_tup_ins,0) + coalesce(n_tup_upd,0) + coalesce(n_tup_del,0)),'999G999G999G999') AS "IOPS"
FROM pg_stat_user_tables
ORDER BY  n_tup_ins + n_tup_upd + n_tup_del desc
LIMIT 20;
