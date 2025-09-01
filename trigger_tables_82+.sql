SELECT 
	n.nspname       AS "Schema", 
	c.relname       AS "Table", 
	t.tgname        AS "Trigger", 
	p.proname       AS "Function",
	CASE 
		WHEN (tgtype::int::bit(7) & b'0000001')::int = 0 THEN 'STATEMENT' 
		ELSE 'EACH ROW' 
	END             AS cond_row,
	COALESCE(
		CASE WHEN (tgtype::int::bit(7) & b'0000010')::int = 0 THEN NULL ELSE 'BEFORE' END,
		CASE WHEN (tgtype::int::bit(7) & b'0000010')::int = 0 THEN 'AFTER' ELSE NULL END,
		CASE WHEN (tgtype::int::bit(7) & b'1000000')::int = 0 THEN NULL ELSE 'INSTEAD' END,
    '')::text       AS cond_timing, 
    (CASE WHEN (tgtype::int::bit(7) & b'0000100')::int = 0 THEN '' ELSE ' INSERT' END) ||
    (CASE WHEN (tgtype::int::bit(7) & b'0001000')::int = 0 THEN '' ELSE ' DELETE' END) ||
    (CASE WHEN (tgtype::int::bit(7) & b'0010000')::int = 0 THEN '' ELSE ' UPDATE' END) ||
    (CASE WHEN (tgtype::int::bit(7) & b'0100000')::int = 0 THEN '' ELSE ' TRUNCATE' END)
                        AS cond_event,
	t.tgenabled     AS "Enabled?",
	CASE 
		WHEN tgdeferrable IS TRUE AND tginitdeferred IS TRUE  THEN 'initially deferred'
		WHEN tgdeferrable IS TRUE AND tginitdeferred IS FALSE THEN 'deferred'
	ELSE NULL 
	END             AS "Defer"
FROM 
	pg_trigger t
	JOIN pg_proc p ON t.tgfoid = p.oid
	JOIN pg_class c ON c.oid = t.tgrelid
	JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
	tgisconstraint = FALSE 
GROUP BY n.nspname, c.relname, t.tgname, p.proname, t.tgtype, t.tgenabled, t.tgdeferrable, t.tginitdeferred;
