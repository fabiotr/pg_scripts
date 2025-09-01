SELECT n.nspname AS "schema", c.relname AS "table"
     , array_agg(i.indexrelid::regclass) FILTER (WHERE indisprimary = false) AS index
	 , index_type.amname as index_type
	 ,array_agg(pg_size_pretty(pg_relation_size(i.indexrelid::regclass))) FILTER (WHERE indisprimary = false)  as idx_size
	,array_agg('DROP INDEX CONCURRENTLY ' ||(i.indexrelid::regclass)::text || ';') FILTER (WHERE indisprimary = false) as sql_drop
	 --,array_agg(pg_get_indexdef(i.indexrelid::regclass)) FILTER (WHERE indisprimary = false) as sql_create
	 --,array_agg(indisprimary)

  FROM pg_index i 
  JOIN pg_class c ON i.indrelid = c.oid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  INNER JOIN (
	SELECT a.amname, c2.relname,c2.oid, i2.indrelid, i2.indexrelid
	FROM pg_index i2
	JOIN pg_class c2 ON c2.oid = i2.indexrelid 
  	JOIN pg_am a ON a.oid = c2.relam ) index_type
  ON index_type.indrelid = i.indrelid AND i.indexrelid = index_type.indexrelid
  WHERE 1=1 
  --AND (pg_relation_size(i.indexrelid::regclass)) > 1000000 -- > indices com mais de 1 MB
 GROUP BY i.indrelid, c.relname, n.nspname,  indkey, index_type.amname
HAVING COUNT(*) > 1
