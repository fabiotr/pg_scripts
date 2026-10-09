SELECT 
    --string_agg(datname,', ') db, 
    lpad(to_char(sum(calls),'FM999G999G999G999'), 16) AS calls, 
    -- min_time / max_time / mean_time only exist from 9.5
    to_char(sum(total_time) / nullif(sum(calls), 0) * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(sum(total_time)      * INTERVAL '1 millisecond', 'HH24:MI:SS') AS total,
    array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ')
FROM 
    :svp_pgss.pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
GROUP BY array_to_string(regexp_split_to_array(substr(query,1,50),E'\\s+'),' ')
ORDER BY sum(total_time) DESC
LIMIT 20;
