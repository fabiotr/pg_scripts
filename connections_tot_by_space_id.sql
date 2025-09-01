with cte as (
  select count(*) over () as total_db
        , pid
        , age(now()
        , xact_start) as age_tx
        , age(now(), state_change) age_state
        , state
        , pg_blocking_pids(pid) as block_pids
        , application_name
        , usename
        , leader_pid
        , unnest(regexp_match(query, '[space\_id\"|"space"\."id"] \= ([0-9]+)')) as where_space_id
  from pg_stat_activity where pid != pg_backend_pid() order by case state when 'idle in transaction' then '0' when 'active'  then '0' else state end, 3 desc nulls last
)
select ((count(*) / total_db::numeric) * 100)::numeric(15, 2) || ' %' as "%"
     , count(*) as cnt
     , count(*) filter (where state = 'active') as "active"
     , count(*) filter (where state = 'idle in transaction') as "idleT."
     , count(*) filter (where state = 'idle') as "idle"
     , count(*) filter (where leader_pid is not null) as child
     , max(age_tx) as "age_tx"
     , where_space_id "space_id"
  from cte
 group by where_space_id, total_db
 order by cnt desc nulls first
 limit 10;
