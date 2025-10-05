SELECT 
    n.nspname AS "Schema", 
    c.relname AS "Table",
    min(ic.relname) AS "Index_1",
    max(ic.relname) AS "Index_2"
FROM 
    pg_index i 
    JOIN pg_class ic    ON i.indexrelid = ic.oid
    JOIN pg_am a        ON a.oid = ic.relam 
    JOIN pg_class c     ON i.indrelid = c.oid 
    JOIN pg_namespace n ON n.oid = c.relnamespace
GROUP BY i.indrelid, c.relname, n.nspname, i.indkey, ic.relam, i.indclass, i.indexprs, i.indpred
HAVING COUNT(*) > 1;
