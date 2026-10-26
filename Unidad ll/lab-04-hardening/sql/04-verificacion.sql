-- LAB-04: verificaciones de solo lectura. Comparar con la baseline.
SELECT version();
SHOW port;
SHOW listen_addresses;
SHOW ssl;
SHOW ssl_min_protocol_version;
SHOW password_encryption;
SHOW log_connections;
SHOW log_disconnections;
SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

SELECT pid, usename, datname, client_addr, client_port, application_name
FROM pg_stat_activity
ORDER BY usename, datname;

SELECT rolname, rolcanlogin, rolsuper, rolcreaterole, rolcreatedb
FROM pg_roles
ORDER BY rolname;

SELECT extname, extversion
FROM pg_extension
ORDER BY extname;

SELECT a.pid, a.usename, a.client_addr, s.ssl, s.version, s.cipher
FROM pg_stat_activity AS a
LEFT JOIN pg_stat_ssl AS s USING (pid)
WHERE a.pid = pg_backend_pid();

