SELECT 
    --string_agg(datname,', ') db, 
    to_char(sum(calls),'999G999G999G999') AS calls, 
    to_char(min(min_time)        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max(max_time)        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(avg(mean_time)       * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(sum(total_time)      * INTERVAL '1 millisecond', 'HH24:MI:SS') AS total,
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ')
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
GROUP BY array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ')
ORDER BY sum(total_time) DESC
LIMIT 20;
