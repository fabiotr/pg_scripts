--Referência: https://wiki.postgresql.org/wiki/Locale_data_changes
--Debian check: dpkg -s libc-bin
--Red Hat check: rpm -qa | grep glibc

--glibc >= 2.28
SET maintenance_work_mem = '8GB';
SELECT 
    --indrelid::regclass::text, 
    --indexrelid::regclass::text, 
    'REINDEX INDEX ' || s.indexrelid::regclass::text || '; --' ,
    --'DROP INDEX ' || s.indexrelid::regclass::text || ';' || pg_get_indexdef(s.indexrelid) || '; --' AS "DROP",
    c.collname
FROM 
    (SELECT 
            indexrelid, 
            indrelid, 
            indcollation[i] coll 
        FROM 
            pg_index i,
            generate_subscripts(indcollation, 1) g(i)) s
    JOIN pg_collation c ON s.coll = c.oid
WHERE 
    --collprovider IN ('d', 'c') AND 
    c.collname NOT IN ('C', 'POSIX')
GROUP BY s.indexrelid, s.indrelid, c.collname;
