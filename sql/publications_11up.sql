SELECT 
	pubname 		AS "Name", 
	pubowner::regrole 	AS "Owner", 
	puballtables 		AS "All tables?", 
	pubinsert 		AS "Insert?",
	pubupdate 		AS "Update?",
	pubdelete 		AS "Delete?",
	pubtruncate  		AS "Truncate?"
FROM pg_publication
ORDER BY 1
;
