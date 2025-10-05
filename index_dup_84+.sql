SELECT 
    n.nspname AS "Schema", 
    c.relname AS "Table",
    array_agg(ic.relname) AS "Index"
FROM 
    pg_index i 
    JOIN pg_class ic    ON i.indexrelid = ic.oid
    JOIN pg_am a        ON a.oid = ic.relam 
    JOIN pg_class c     ON i.indrelid = c.oid 
    JOIN pg_namespace n ON n.oid = c.relnamespace
GROUP BY i.indrelid, c.relname, n.nspname, i.indkey, ic.relam, i.indclass, i.indoption, i.indexprs, i.indpred
HAVING COUNT(*) > 1;
