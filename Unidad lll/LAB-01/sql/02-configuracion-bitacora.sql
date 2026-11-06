-- LAB-01 · Actividades 4 y 7 — Parámetros de registro (todos con RECARGA)
-- Sesión de administrador.

-- Actividad 4
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();

-- La recarga es asíncrona: verificar en una consulta posterior.
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;

-- Actividad 7: registrar también INSERT, UPDATE, DELETE, TRUNCATE y COPY FROM.
ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();

SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;
