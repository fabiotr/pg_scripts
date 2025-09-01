SELECT 
    count(name) AS "Count",
    pg_size_pretty(sum(size)) AS "Size", 
    max(modification) - min(modification) AS "Interval Avaliable",
    pg_size_pretty(sum(size) * 60 * 60 * 24 / EXTRACT(EPOCH FROM max(modification) - min(modification))::BIGINT) AS "Size / day"
FROM pg_ls_logdir();
