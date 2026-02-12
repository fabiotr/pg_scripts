\prompt 'Type the query ID: ' qid
SELECT
    regexp_replace(query, '[\n\r\t\u2028\u0020]+',' ','g')
FROM
    pg_stat_statements
WHERE
    queryid = :qid ;
