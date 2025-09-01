SELECT l "recovery.conf"
FROM (SELECT  row_number() OVER () AS n, unnest(string_to_array(pg_read_file(name),chr(10))) AS l
        FROM pg_ls_dir('.') AS name
        WHERE name LIKE 'recovery.conf') AS cat
WHERE 
    l NOT LIKE '#%' AND 
    l NOT LIKE CHR(9) ||'%' AND
    l != '';
