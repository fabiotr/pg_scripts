create table orfaos_story_id ("table" text, total_rows int, orphan int, "%" numeric, fk boolean);

SELECT format($$
    INSERT INTO orfaos_story_id 
    SELECT %1$L as table
      , count(*) as total_rows
      , count(*) FILTER (WHERE s.id IS NULL) orphan
      , ((count(*) FILTER (WHERE s.id IS NULL)::numeric / count(*)) * 100)::numeric(15, 2) as "%%"
      , (pc.oid is not null) FK
    FROM %1$s 
    LEFT JOIN stories s ON s.id = %1$s.story_id
    LEFT JOIN pg_constraint pc ON pc.contype = 'f' AND pc.conrelid = %1$L::regclass AND confrelid = 'stories'::regclass 
   WHERE story_id IS NOT NULL 
   GROUP BY (pc.oid is not null)
     $$, table_name) 
  FROM information_schema.columns 
 WHERE column_name = 'story_id' 
 ;

\gexec
