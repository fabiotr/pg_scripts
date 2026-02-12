SELECT count(1) AS qt, gss_authenticated, principal, encrypted 
FROM pg_stat_gssapi 
GROUP BY gss_authenticated, principal, encrypted 
ORDER BY gss_authenticated, qt DESC;
