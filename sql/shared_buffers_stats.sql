\ir variables.sql

\if :svp_pg_13
  \if :svp_shmem_allocations
    \ir shared_buffers_stats_13up.sql
  \else
    \qecho - Needs SELECT on pg_shmem_allocations: pg_read_all_stats or pg_monitor on PG 15+, superuser before
  \endif
\else
  \qecho - Not supported on version :svp_server_version
\endif
\timing on
\set QUIET off
