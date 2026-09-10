SELECT
    a.pid,
    a.state,
    a.wait_event_type,
    a.wait_event,
    a.datname AS db,
    host(a.client_addr) AS host,
    a.usename AS "user",
    to_char(current_timestamp - a.backend_start ,'HH24:MI:SS') AS "Q Conn",
    to_char(current_timestamp - a.xact_start    ,'HH24:MI:SS') AS "Q Xact",
    to_char(current_timestamp - a.query_start   ,'HH24:MI:SS') AS "Q Start",
    round(io.reads / t.secs, 2)                       AS reads_per_sec,
    pg_size_pretty(round(io.read_bytes / t.secs))  || '/s' AS read_bytes_per_sec,
    round(io.writes / t.secs, 2)                      AS writes_per_sec,
    pg_size_pretty(round(io.write_bytes / t.secs)) || '/s' AS write_bytes_per_sec,
    round(io.extends / t.secs, 2)                     AS extends_per_sec,
    round(io.hits / t.secs, 2)                        AS hits_per_sec,
    round(io.evictions / t.secs, 2)                   AS evictions_per_sec,
    round(wal.wal_records / t.secs, 2)                AS wal_records_per_sec,
    pg_size_pretty(round(wal.wal_bytes / t.secs))  || '/s' AS wal_bytes_per_sec,
    a.query_id,
    array_to_string(regexp_split_to_array(substr(a.query,1,50),'\s+'),' ') || CASE WHEN length(a.query) > 50 THEN '...' ELSE '' END AS query
FROM pg_stat_activity a
LEFT JOIN LATERAL (
    SELECT NULLIF(EXTRACT(EPOCH FROM (current_timestamp - a.backend_start)),0)::numeric AS secs
) t ON true
LEFT JOIN LATERAL (
    SELECT
        sum(reads)       AS reads,
        sum(read_bytes)  AS read_bytes,
        sum(writes)      AS writes,
        sum(write_bytes) AS write_bytes,
        sum(extends)     AS extends,
        sum(hits)        AS hits,
        sum(evictions)   AS evictions
    FROM pg_stat_get_backend_io(a.pid)
) io ON true
LEFT JOIN LATERAL (
    SELECT wal_records, wal_bytes
    FROM pg_stat_get_backend_wal(a.pid)
) wal ON true
WHERE
    a.pid != pg_backend_pid()
ORDER BY (io.read_bytes / t.secs + io.write_bytes / t.secs) DESC NULLS LAST
LIMIT 20;
