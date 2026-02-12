SELECT 
    --string_agg(datname,', ') db, 
    row_number() over(order by sum(total_exec_time) desc) "N",
    queryid,
    to_char(sum(calls),'999G999G999G999') AS "Calls", 
    to_char(min(min_exec_time)        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS min,
    to_char(max(max_exec_time)        * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS max,
    to_char(avg(mean_exec_time)       * INTERVAL '1 millisecond', 'HH24:MI:SS,US') AS avg,
    to_char(sum(total_exec_time)      * INTERVAL '1 millisecond', 'HH24:MI:SS') AS "Total",
    array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ')
FROM 
    pg_stat_statements s 
    JOIN pg_database d ON d.oid = s.dbid 
GROUP BY queryid, array_to_string(regexp_split_to_array(substr(query,1,50),'\s+'),' ')
ORDER BY sum(total_exec_time) DESC
LIMIT 20;
