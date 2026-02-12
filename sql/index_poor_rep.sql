WITH table_scans AS (
    SELECT 
        relid,
        tables.idx_scan + tables.seq_scan                           AS all_scans,
        (tables.n_tup_ins + tables.n_tup_upd + tables.n_tup_del )   AS writes,
                pg_relation_size(relid)                             AS table_size
        FROM pg_stat_user_tables AS tables
),
all_writes AS (
    SELECT sum(writes) AS total_writes
    FROM table_scans
),
indexes as (
    SELECT 
        idx_stat.relid, 
        idx_stat.indexrelid,
        idx_stat.schemaname, 
        idx_stat.relname        AS tablename,
        idx_stat.indexrelname   AS indexname,
        GREATEST(idx_stat.idx_scan, idx_stat1.idx_scan, idx_stat5.idx_scan) AS idx_scan,
        pg_relation_size(idx_stat.indexrelid) AS index_bytes,
        indexdef ~* 'USING btree' AS idx_is_btree
    FROM 
        pg_stat_user_indexes AS idx_stat
        JOIN pg_stat_user_indexes_ro1 AS idx_stat1 USING (indexrelid)
        JOIN pg_stat_user_indexes_ro5 AS idx_stat5 USING (indexrelid)
        JOIN pg_index USING (indexrelid)
        JOIN pg_indexes AS indexes ON
                    idx_stat.schemaname = indexes.schemaname
                AND idx_stat.relname = indexes.tablename
                AND idx_stat.indexrelname = indexes.indexname
    WHERE pg_index.indisunique = FALSE
),
index_ratios AS (
SELECT schemaname, tablename, indexname, idx_scan, all_scans, writes, idx_is_btree, index_bytes,
    round(( CASE WHEN all_scans = 0 THEN 0.0::NUMERIC
        ELSE idx_scan::NUMERIC/all_scans * 100 END),2) AS index_scan_pct,
    round((CASE WHEN writes = 0 THEN idx_scan::NUMERIC ELSE idx_scan::NUMERIC/writes END),2) AS scans_per_write,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(table_size)  AS table_size
    FROM 
        indexes
        JOIN table_scans USING (relid)
),
index_groups AS (
SELECT 'Never Used Indexes' AS reason, *, 1 AS grp
FROM index_ratios
WHERE
        idx_scan = 0
    AND idx_is_btree
UNION ALL
SELECT 'Low Scans, High Writes' AS reason, *, 2 AS grp
FROM index_ratios
WHERE
        scans_per_write <= 1
    AND index_scan_pct < 10
    AND idx_scan > 0
    AND writes > 100
    AND idx_is_btree
UNION ALL
SELECT 'Seldom Used Large Indexes' AS reason, *, 3 AS grp
FROM index_ratios
WHERE
        index_scan_pct < 5
    AND scans_per_write > 1
    AND idx_scan > 0
    AND idx_is_btree
    AND index_bytes > 100000000
UNION ALL
SELECT 'High-Write Large Non-Btree' AS reason, index_ratios.*, 4 AS grp
FROM index_ratios, all_writes
WHERE
        (writes::NUMERIC / (total_writes + 1)) > 0.02
    AND NOT idx_is_btree
    AND index_bytes > 100000000
ORDER BY grp, index_bytes DESC, schemaname, tablename)

SELECT reason "Reason", schemaname "Schema", tablename "Table", indexname "Index",
    index_scan_pct "idx scan %", scans_per_write "scan/w", index_size , table_size
FROM index_groups
WHERE index_bytes > 1000000
ORDER BY grp, index_bytes DESC, tablename, indexname, schemaname;
