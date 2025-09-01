SELECT schemaname, relname, 
    to_char(CASE blks_hit WHEN 0 THEN 0 ELSE 100 * blks_hit::NUMERIC / (blks_read + blks_hit) END, '990d99') || ' %' AS "Sequence hit",
    to_char(CASE blks_hit WHEN 0 THEN 0 ELSE 100 * (blks_hit + blks_read) / (SUM (blks_hit + blks_read) OVER ()) END,'990D99') || ' %' AS "Sequence weight"
FROM pg_statio_all_sequences 
ORDER BY blks_hit + blks_read DESC NULLS LAST
LIMIT 10;
