SELECT *, CASE calls WHEN 0 THEN 0 ELSE  TRUNC(self_time/calls) END "t/c" 
FROM pg_stat_user_functions 
ORDER BY self_time desc 
LIMIT 20;
