SELECT n.nspname as "Schema",
  c.relname as "Name",
  pg_get_userbyid(c.relowner) as "Owner",
  CASE c.relkind WHEN 'p' THEN 'partitioned table' WHEN 'I' THEN 'partitioned index' END as "Type",
  inh.inhparent::regclass as "Parent name",
 c2.oid::regclass as "Table",
  s.dps as "Leaf partition size",
  s.tps as "Total size",
  obj_description(c.oid, 'pg_class') as "Description"
FROM pg_class c
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_index i ON i.indexrelid = c.oid
     LEFT JOIN pg_class c2 ON i.indrelid = c2.oid
     LEFT JOIN pg_inherits inh ON c.oid = inh.inhrelid,
     LATERAL (SELECT pg_size_pretty(sum(
                 CASE WHEN ppt.isleaf AND ppt.level = 1
                      THEN pg_table_size(ppt.relid) ELSE 0 END)) AS dps,
                     pg_size_pretty(sum(pg_table_size(ppt.relid))) AS tps
              FROM pg_partition_tree(c.oid) ppt) s
WHERE c.relkind IN ('p','I','')
      AND n.nspname <> 'pg_catalog'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
  AND pg_table_is_visible(c.oid)
ORDER BY "Schema", "Type" DESC, "Parent name" NULLS FIRST, "Name";
