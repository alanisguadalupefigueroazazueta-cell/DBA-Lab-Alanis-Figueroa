-- LAB-04: parámetros y reglas de configuración. Solo lectura.
SELECT name, setting, source, pending_restart
FROM pg_settings
WHERE name IN (
  'listen_addresses', 'port', 'ssl', 'ssl_min_protocol_version',
  'password_encryption', 'log_connections', 'log_disconnections',
  'max_connections', 'superuser_reserved_connections',
  'statement_timeout', 'idle_in_transaction_session_timeout'
)
ORDER BY name;

-- Puede requerir permisos para leer pg_hba_file_rules:
SELECT type, database, user_name, address, auth_method, error
FROM pg_hba_file_rules
ORDER BY rule_number;

-- Extensiones instaladas:
SELECT extname, extversion
FROM pg_extension
ORDER BY extname;

-- TLS de la sesión actual:
SELECT a.pid, a.usename, a.client_addr, s.ssl, s.version, s.cipher
FROM pg_stat_activity AS a
LEFT JOIN pg_stat_ssl AS s USING (pid)
WHERE a.pid = pg_backend_pid();
