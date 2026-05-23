SELECT count(1) AS qt, ssl, version, cipher, bits, compression, clientdn 
FROM pg_stat_ssl 
GROUP BY ssl, version, cipher, bits, compression, clientdn 
ORDER BY ssl, qt DESC;
