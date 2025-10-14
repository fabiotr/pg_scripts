SELECT
    d.datname AS "Database",
    d.conflicts      AS "Total",
    confl_tablespace AS "Tablespace",
    confl_lock       AS "Lock",
    confl_deadlock   AS "Deadlock",
    confl_snapshot   AS "Snapshot",
    confl_bufferpin  AS "Bufferpin",
    age(now(),stats_reset) AS "Age" 
FROM 
	pg_stat_database d
	JOIN pg_stat_database_conflicts c ON d.datid = c.datid
ORDER BY d.datname;
