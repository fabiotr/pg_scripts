SELECT count(1) AS qt, ssl, version, cipher, bits, client_dn, client_serial, issuer_dn 
FROM pg_stat_ssl 
GROUP BY ssl, version, cipher, bits, client_dn, client_serial, issuer_dn 
ORDER BY ssl, qt DESC;
