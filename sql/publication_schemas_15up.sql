SELECT p.pubname AS "Publication", n.nspname AS "Schema"
FROM
	pg_publication_namespace AS pn
	JOIN pg_publication AS p ON p.oid = pn.pnpubid
	JOIN pg_namespace   AS n ON n.oid = pn.pnnspid
ORDER BY 1,2;
