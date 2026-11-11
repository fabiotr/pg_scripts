--Reference: https://wiki.postgresql.org/wiki/Locale_data_changes
--Debian check: dpkg -s libc-bin
--Red Hat check: rpm -qa | grep glibc

--glibc >= 2.28
SET maintenance_work_mem = '8GB';
SELECT 
    'REINDEX INDEX ' || quote_ident(n.nspname) || '.' || quote_ident(ci.relname) || '; --' ,
    c.collname
FROM 
    (SELECT indexrelid, indrelid, indcollation[i] AS coll
        FROM (SELECT indexrelid, indrelid, indcollation, generate_subscripts(indcollation, 1) AS i
              FROM pg_index) AS ix) s
    JOIN pg_collation c ON s.coll = c.oid
    JOIN pg_class ci ON ci.oid = s.indexrelid
    JOIN pg_namespace n ON n.oid = ci.relnamespace
WHERE 
    --collprovider IN ('d', 'c') AND 
    c.collname NOT IN ('C', 'POSIX')
GROUP BY s.indexrelid, s.indrelid, n.nspname, ci.relname, c.collname;
