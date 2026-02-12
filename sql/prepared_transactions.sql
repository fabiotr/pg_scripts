\set QUIET on
\timing off
SELECT owner, database, transaction, gid, prepared
FROM pg_prepared_xacts 
ORDER BY owner, database;
\timing on
\set QUIET off
