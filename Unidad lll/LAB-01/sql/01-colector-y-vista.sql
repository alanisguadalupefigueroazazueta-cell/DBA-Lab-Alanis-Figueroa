-- LAB-01 · Actividad 2 — Colector de bitácora y vista dba.bitacora
-- Sesión de administrador.

-- 1) Activar el colector (requiere REINICIO del servicio).
ALTER SYSTEM SET logging_collector = on;
SELECT pg_reload_conf();
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';

-- >>> Reiniciar el servicio (Anexo A, tabla A.1) y abrir una sesión nueva <<<

-- 2) Comprobar.
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();

-- 3) Leer el archivo vigente desde el motor.
SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;

-- 4) Vista de uso exclusivo del administrador.
CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';

-- 5) Consultas de uso.
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';
SELECT * FROM pg_ls_logdir();
