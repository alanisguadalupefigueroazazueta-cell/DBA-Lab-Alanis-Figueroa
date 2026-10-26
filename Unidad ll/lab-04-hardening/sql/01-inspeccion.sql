-- LAB-04 | 01-inspeccion.sql
-- Solo lectura. Cubre Actividades 1, 2, 3, 4, 7, 8, 10, 11 y 15.
-- Se ejecuta ANTES y DESPUES del hardening para comparar.

-- ACT 1 | Superficie de ataque
SELECT version();
SHOW port;
SHOW listen_addresses;
SHOW ssl;
SHOW password_encryption;

--conexiones activas (solo sesiones de cliente) 
SELECT pid, usename, datname, client_addr, client_port, application_name
FROM pg_stat_activity
WHERE backend_type = 'client backend'
ORDER BY pid;

--ACT 2 | Archivos de configuracion y directorios 
SHOW config_file;
SHOW hba_file;
SHOW ident_file;
SHOW data_directory;
SHOW log_directory;
SHOW log_connections;
SHOW log_disconnections;

-- ACT 3 | listen_addresses
SHOW listen_addresses;

-- ACT 4 | Reglas de pg_hba.conf 
SELECT line_number AS linea, type, database, user_name, address, netmask, auth_method
FROM pg_hba_file_rules
ORDER BY line_number;

-- ACT 7 | Autenticacion: algoritmo de almacenamiento de contrasenas 
SHOW password_encryption;
SELECT rolname,
       CASE WHEN rolpassword LIKE 'SCRAM-SHA-256$%' THEN 'SCRAM-SHA-256'
            WHEN rolpassword LIKE 'md5%'            THEN 'md5 (heredado)'
            WHEN rolpassword IS NULL                THEN '(sin password)'
            ELSE 'otro' END AS formato_hash
FROM pg_authid
WHERE rolcanlogin
ORDER BY rolname;

-- ACT 8 | Roles y privilegios 
SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin, rolconnlimit
FROM pg_roles
ORDER BY rolname;

-- ACT 10 | Extensiones 
SELECT
    extname,
    extversion
FROM pg_extension
ORDER BY extname;


-- ACT 11 | Parametros de conexion 
SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;
SHOW idle_session_timeout;

-- ACT 12 | Revision de permisos del istema operativo 
SHOW data_directory;
SHOW config_file;
SHOW hba_file;

-- ACT 15 | TLS
SHOW ssl;
SHOW ssl_min_protocol_version;

SELECT s.pid, a.usename, a.client_addr, s.ssl, s.version, s.cipher
FROM pg_stat_ssl s
JOIN pg_stat_activity a USING (pid)
WHERE s.pid = pg_backend_pid();
