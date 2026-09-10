WITH RECURSIVE roots AS (
    SELECT
        c.oid       AS relid,
        n.nspname   AS schema_name,
        c.relname   AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'p'
      AND c.relispartition = false
),
part_tree AS (
    SELECT
        r.relid       AS relid,
        r.relid       AS root_relid,
        c.relkind     AS relkind,
        0             AS level
    FROM roots r
    JOIN pg_class c ON c.oid = r.relid

    UNION ALL

    SELECT
        ch.oid,
        pt.root_relid,
        ch.relkind,
        pt.level + 1
    FROM pg_inherits i
    JOIN part_tree pt ON i.inhparent = pt.relid
    JOIN pg_class ch  ON ch.oid = i.inhrelid
),
leaves AS (
    SELECT relid, root_relid
    FROM part_tree
    WHERE level > 0
      AND relkind IN ('r', 'f')
),
leaf_sizes AS (
    SELECT
        l.root_relid,
        l.relid,
        pg_relation_size(l.relid)                                       AS data_bytes,
        COALESCE(pg_relation_size(c.reltoastrelid), 0)                  AS toast_bytes,
        pg_table_size(l.relid)                                          AS table_bytes,
        pg_indexes_size(l.relid)                                        AS indexes_bytes,
        pg_total_relation_size(l.relid)                                 AS total_bytes,
        (SELECT count(*) FROM pg_index ix WHERE ix.indrelid = l.relid)  AS index_count
    FROM leaves l
    JOIN pg_class c ON c.oid = l.relid
),
leaf_statio AS (
    SELECT
        l.root_relid,
        l.relid,
        COALESCE(s.heap_blks_hit, 0)  + COALESCE(s.idx_blks_hit, 0)
            + COALESCE(s.toast_blks_hit, 0)  + COALESCE(s.tidx_blks_hit, 0)  AS cache_blks,
        COALESCE(s.heap_blks_read, 0) + COALESCE(s.idx_blks_read, 0)
            + COALESCE(s.toast_blks_read, 0) + COALESCE(s.tidx_blks_read, 0) AS disk_blks
    FROM leaves l
    LEFT JOIN pg_statio_user_tables s ON s.relid = l.relid
),
stats_age AS (
    SELECT GREATEST(
        EXTRACT(EPOCH FROM (now() - COALESCE(sd.stats_reset, pg_postmaster_start_time()))) / 86400.0,
        1.0 / 86400.0
    ) AS days_since_reset
    FROM pg_stat_database sd
    WHERE sd.datname = current_database()
),
ranked AS (
    SELECT
        r.schema_name                                                         AS parent_schema,
        r.table_name                                                          AS parent_table,
        pn.nspname                                                            AS part_schema,
        pc.relname                                                            AS part_name,
        pg_get_expr(pc.relpartbound, pc.oid)                                  AS part_bound,
        ls.data_bytes,
        ls.toast_bytes,
        ls.table_bytes,
        ls.indexes_bytes,
        ls.total_bytes,
        ls.index_count,
        COALESCE(st.cache_blks, 0)                                            AS cache_blks,
        COALESCE(st.disk_blks, 0)                                             AS disk_blks,
        ROW_NUMBER() OVER (PARTITION BY r.relid ORDER BY ls.total_bytes DESC) AS part_rank
    FROM roots r
    JOIN leaf_sizes ls ON ls.root_relid = r.relid
    LEFT JOIN leaf_statio st ON st.relid = ls.relid
    JOIN pg_class pc ON pc.oid = ls.relid
    JOIN pg_namespace pn ON pn.oid = pc.relnamespace
)
SELECT
    parent_schema AS "Schema",
    parent_table  AS "Table",
    part_name     AS "Partition",
    part_bound    AS "Bound",
    index_count   AS "Index Count",
    pg_size_pretty(data_bytes)                                                AS "Heap size",
    pg_size_pretty(toast_bytes)                                               AS "Toast size",
    pg_size_pretty(table_bytes)                                               AS "Table size",
    pg_size_pretty(indexes_bytes)                                             AS "Index size",
    pg_size_pretty(total_bytes)                                               AS "Total size",
    pg_size_pretty( ROUND(cache_blks * current_setting('block_size')::bigint
        / sa.days_since_reset)::bigint )                                      AS "Hit / Day",
    pg_size_pretty( ROUND(disk_blks  * current_setting('block_size')::bigint
        / sa.days_since_reset)::bigint )                                      AS "Reads / Day",
    ROUND(cache_blks::numeric / NULLIF(cache_blks + disk_blks, 0) * 100, 2)   AS "Hit %"
FROM
    ranked,
    stats_age sa
WHERE part_rank <= 5
ORDER BY parent_schema, parent_table, part_rank;
