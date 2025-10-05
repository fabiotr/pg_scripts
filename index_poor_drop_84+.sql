SELECT '/*** SIZE: ' || pg_size_pretty(pg_relation_size(indexrelid::regclass)) || '  ***/ DROP INDEX CONCURRENTLY IF EXISTS ' || indexes.schemaname || '.' || idx_stat.indexrelname || ';'
FROM pg_stat_user_indexes as idx_stat
	JOIN pg_index
		USING (indexrelid)
	JOIN pg_indexes as indexes
		ON idx_stat.schemaname = indexes.schemaname
			AND idx_stat.relname = indexes.tablename
			AND idx_stat.indexrelname = indexes.indexname
WHERE 
	pg_index.indisunique = FALSE AND
	pg_index.indisprimary = FALSE AND
	idx_scan = 0 AND
	indexdef ~* 'USING btree'
	--AND pg_relation_size(indexrelid::regclass) > 1000000 -- > indices com mais de 1 MB
	;
