\prompt 'Type the query ID: ' qid
SELECT
    regexp_replace(query, '[\f\v\n\r\t\u2028\u0020\u00A0]+',' ','g')
FROM
    pg_stat_statements
WHERE
    queryid = :qid ;
