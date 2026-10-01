SELECT name AS "Name", lpad(pg_size_pretty(size), 11) AS "Size"
FROM pg_shmem_allocations 
ORDER BY size DESC
LIMIT 10;
