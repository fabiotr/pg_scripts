\prompt 'space_id to kill its sessions:'  v_space_id
WITH to_kill AS (
  SELECT pid
       , unnest(regexp_match(query, '[space\_id\"|"space"\."id"] \= ([0-9]+)')) as where_space_id
  FROM pg_stat_activity 
  WHERE pid != pg_backend_pid() 
)
SELECT format('select pg_terminate_backend(%s);', pid)
FROM to_kill 
WHERE where_space_id::integer = (:v_space_id)::integer ;
