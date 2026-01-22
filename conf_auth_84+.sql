SELECT
    --category,
    name AS "conf",
    setting AS "value",
    boot_val AS "default",
    unit
FROM pg_settings
WHERE
    source = 'configuration file' AND
    setting != boot_val AND
    name IN ('authentication_timeout', 'password_encryption', 'scram_iterations', 'md5_password_warnings', 'krb_server_keyfile', 'krb_caseins_users', 'gss_accept_delegation', 
             'oauth_validator_libraries')
ORDER BY category, name;
