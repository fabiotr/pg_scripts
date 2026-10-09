-- Temporary files per backend, from every tablespace. pg_ls_tmpdir() lists only
-- the files at the top of pgsql_tmp: the shared filesets of parallel builds live
-- in subdirectories, so a parallel build shows no temporary files.
WITH tmp AS (
\if :svp_ls_tmpdir
  SELECT
    substring(f.name FROM '^pgsql_tmp([0-9]+)[.]')::int AS pid,
    sum(f.size) AS bytes
  FROM
    pg_tablespace t,
    pg_ls_tmpdir(t.oid) f
  WHERE f.name ~ '^pgsql_tmp[0-9]+[.]'
  GROUP BY 1
\else
  SELECT NULL::int AS pid, NULL::numeric AS bytes
\endif
)
SELECT
    --p.datname AS "DB", 
    p.pid,
    now() - a.xact_start AS duration,
    coalesce(wait_event_type ||'.'|| wait_event, 'f') AS waiting,
    c.relnamespace::regnamespace || '.' || c.relname AS table,
    command,
    phase,
    CASE WHEN :'svp_ls_tmpdir'::boolean
      THEN lpad(pg_size_pretty(coalesce(tmp.bytes, 0)), 11)
      ELSE 'needs pg_monitor' END AS "Temp size",
    -- reltuples is 0 when the table was analyzed empty and -1 (PG 14+) when it was never analyzed
    nullif(c.reltuples, -1) AS "Total tuples",
    trunc(heap_tuples_scanned::numeric * 100 / nullif(greatest(c.reltuples, 0), 0)::numeric,1) AS "% Rows scanned",
    trunc(heap_tuples_written::numeric * 100 / nullif(greatest(c.reltuples, 0), 0)::numeric,1) AS "% Rows written",
    -- heap_blks_* are only reported by a seq scan of the heap; cluster_index_relid is set only by an index scan
    CASE WHEN cluster_index_relid = 0
      THEN lpad(pg_size_pretty(heap_blks_total   * current_setting('block_size')::int), 11)
      ELSE lpad('n/a', 11) END AS "Total Bytes",
    CASE WHEN cluster_index_relid = 0
      THEN lpad(pg_size_pretty(heap_blks_scanned * current_setting('block_size')::int), 11)
      ELSE lpad('n/a', 11) END AS "Scanned Bytes",
    (SELECT count(1) FROM pg_index AS i WHERE i.indrelid = p.relid)        AS "Total indexes",
    index_rebuild_count                                                    AS "Rebuilt indexes"
FROM  
    pg_stat_progress_cluster AS p
    JOIN pg_stat_activity AS a USING (pid)
    LEFT JOIN tmp ON tmp.pid = p.pid
    JOIN pg_class AS c ON c.oid = p.relid
ORDER BY now() - a.xact_start DESC;
