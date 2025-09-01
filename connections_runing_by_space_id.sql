with cte as (
  select count(*) over () as total_db
        , pid
        , client_addr
        , age(now()
        , xact_start) as age_tx
        , age(now(), state_change) age_state
        , state
        , pg_blocking_pids(pid) as block_pids
        , application_name
        , usename
        , leader_pid
        , (select unnest(regexp_match(query, '(?:space\_id\"|"space"\."id") \= ([0-9]+)'))) as space_id
  from pg_stat_activity where pid != pg_backend_pid() order by case state when 'idle in transaction' then '0' when 'active'  then '0' else state end, 3 desc nulls last
)
-- TOP 7 APPS
(select client_addr::text ip
     , ((count(*) / total_db::numeric) * 100)::numeric(15, 2) || ' %' as "%"
     , count(*) as cnt
     , count(*) filter (where state = 'active') as "active"
     , count(*) filter (where state = 'idle in transaction')::text || ' (PID: ' || array_agg(pid) filter (where state = 'idle in transaction')::text || ')' as "idleT."
     , count(*) filter (where state = 'idle') as "idle"
     , count(*) filter (where leader_pid is not null) as child
     , max(age_tx) as "age_tx"
     , null AS space_id
  from cte
  group by client_addr, total_db
 order by 3 desc nulls first
 limit 7)
 union all 
-- TOP 20 SPACES 
(select
       null
     , ((count(*) / total_db::numeric) * 100)::numeric(15, 2) || ' %' as "%"
     , count(*) as cnt
     , count(*) filter (where state = 'active') as "active"
     , count(*) filter (where state = 'idle in transaction')::text || ' (PID: ' || array_agg(pid) filter (where state = 'idle in transaction')::text || ')' as "idleT."
     , count(*) filter (where state = 'idle') as "idle"
     , count(*) filter (where leader_pid is not null) as child
     , max(age_tx) as "age_tx"
     , space_id "space_id"
  from cte
 where space_id is not null
 group by space_id, total_db
 order by "%" desc nulls first
 limit 20)
 union all 
select null
     , '100 %' as "%"
     , count(*) as cnt
     , count(*) filter (where state = 'active') as "active"
     , count(*) filter (where state = 'idle in transaction')::text || ' (PID: ' || array_agg(pid) filter (where state = 'idle in transaction')::text || ')' as "idleT."
     , count(*) filter (where state = 'idle') as "idle"
     , count(*) filter (where leader_pid is not null) as child
     , max(age_tx) as "age_tx"
     , null
  from cte
 order by cnt desc
 ;
