SELECT
    os.roident        AS "Ident",
    os.roname         AS "Name",
	ol.local_id       AS "Local",
	oe.external_id    AS "External",
	COALESCE (ol.local_lsn,  oe.local_lsn)  AS "Local LSN",
    COALESCE (ol.remote_lsn, oe.remote_lsn) AS "Remote LSN"
FROM
	pg_replication_origin os
	LEFT JOIN pg_replication_origin_status ol ON os.roident = ol.local_id
	LEFT JOIN pg_replication_origin_status oe ON os.roname  = oe.external_id
;
