SELECT name AS "Name", pg_size_pretty(size) AS "Size"
FROM pg_shmem_allocations 
ORDER BY size DESC
LIMIT 10;
