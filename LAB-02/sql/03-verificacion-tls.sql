-- LAB-02 | Actividades 4-6: Verificación de TLS en PostgreSQL

-- Configuración del servidor
SHOW ssl;
SHOW ssl_min_protocol_version;
SHOW port;
SHOW listen_addresses;

-- Conexión actual
SELECT inet_client_addr(), inet_client_port();

-- ¿La sesión actual usa TLS?
SELECT ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();

