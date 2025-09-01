CREATE EXTENSION IF NOT EXISTS amcheck;
SELECT 'SELECT bt_index_check(' || c.oid || '); -- ' || to_char(row_number() OVER (ORDER BY c.relpages),'0000') || ' | ' || c.relname || ', TAMANHO:' || pg_size_pretty(pg_relation_size(c.oid))
    FROM 
             pg_index i
        JOIN pg_opclass op ON i.indclass[0] = op.oid
        JOIN pg_am am ON op.opcmethod = am.oid
        JOIN pg_class c ON i.indexrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE 
            am.amname = 'btree'
        AND c.relpersistence != 't'
        AND i.indisready 
        AND i.indisvalid
    ORDER BY c.relpages;
