\ir variables.sql

\prompt 'Type the query ID: ' qid
SELECT
    regexp_replace(query, E'[\\f\\v\\n\\r\\t\\u2028\\u0020\\u00A0]+',' ','g')
FROM
    :svp_pgss.pg_stat_statements
WHERE
    queryid = :qid ;
\timing on
\set QUIET off
