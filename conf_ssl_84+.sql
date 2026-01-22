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
    name IN ('ssl', 'ssl_ca_file', 'ssl_cert_file', 'ssl_crl_file', 'ssl_crl_dir', 'ssl_key_file', 'ssl_tls13_ciphers', 'ssl_prefer_server_ciphers', 'ssl_groups', 
             'ssl_min_protocol_version', 'ssl_max_protocol_version', 'ssl_dh_params_file', 'ssl_passphrase_command', 'ssl_passphrase_command_supports_reload')
ORDER BY category, name;
-- excluded ssl_ciphers
