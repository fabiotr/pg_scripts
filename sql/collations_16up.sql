SELECT
  n.nspname       AS "Schema",
  c.collname      AS "Name",
  CASE c.collprovider 
    WHEN 'd' THEN 'default' 
    WHEN 'c' THEN 'libc' 
    WHEN 'i' THEN 'icu' 
    END           AS "Provider",
  c.collcollate   AS "Collate",
  c.collctype     AS "Ctype",
  c.colliculocale AS "ICU Locale",
  c.collicurules  AS "ICU Rules",
  CASE 
    WHEN c.collisdeterministic THEN 'yes' 
    ELSE 'no' END AS "Deterministic?"
FROM 
    pg_collation c, 
    pg_namespace n
WHERE 
    n.oid = c.collnamespace AND 
    n.nspname <> 'pg_catalog' AND 
    n.nspname <> 'information_schema' AND 
    c.collencoding IN (-1, pg_char_to_encoding(getdatabaseencoding())) AND 
    pg_collation_is_visible(c.oid)
ORDER BY 1, 2;

