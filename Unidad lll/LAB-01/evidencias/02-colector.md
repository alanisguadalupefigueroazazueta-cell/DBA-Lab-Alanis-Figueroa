# Evidencia 02 — Colector de bitácora y vista dba.bitacora

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 2 |
| Fecha de ejecución | 2026-11-06 14:30:47 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## Activación del colector

*Sesión de administrador (entrada y salida de psql):*

```text
ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM
SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';
       name        | setting | pending_restart 
-------------------+---------+-----------------
 logging_collector | off     | t
(1 row)

```

*Reinicio del servicio:* `pg_ctlcluster 16 main restart`

## Comprobación

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
       name        | setting |       source       
-------------------+---------+--------------------
 logging_collector | on      | configuration file
(1 row)

SELECT pg_current_logfile();
          pg_current_logfile          
--------------------------------------
 log/postgresql-2026-11-06_143049.log
(1 row)

```

## Lectura del archivo vigente desde el motor

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;
                                                                                           linea                                                                                           
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:49.929 UTC [291] LOG:  starting PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
 2026-11-06 14:30:49.929 UTC [291] LOG:  listening on IPv4 address "127.0.0.1", port 5432
 2026-11-06 14:30:49.930 UTC [291] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
 2026-11-06 14:30:49.933 UTC [295] LOG:  database system was shut down at 2026-11-06 14:30:49 UTC
 2026-11-06 14:30:49.951 UTC [291] LOG:  database system is ready to accept connections
 
(6 rows)

```

## Vista dba.bitacora y consultas de prueba

*Sesión de administrador (entrada y salida de psql):*

```text
CREATE SCHEMA dba;
CREATE SCHEMA
REVOKE ALL ON SCHEMA dba FROM PUBLIC;
REVOKE
CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';
CREATE VIEW
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;
 num |                                                                                           linea                                                                                           
-----+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   5 | 2026-11-06 14:30:49.951 UTC [291] LOG:  database system is ready to accept connections
   4 | 2026-11-06 14:30:49.933 UTC [295] LOG:  database system was shut down at 2026-11-06 14:30:49 UTC
   3 | 2026-11-06 14:30:49.930 UTC [291] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
   2 | 2026-11-06 14:30:49.929 UTC [291] LOG:  listening on IPv4 address "127.0.0.1", port 5432
   1 | 2026-11-06 14:30:49.929 UTC [291] LOG:  starting PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
(5 rows)

SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';
 linea 
-------
(0 rows)

SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';
 linea 
-------
(0 rows)

SELECT * FROM pg_ls_logdir();
               name               | size |      modification      
----------------------------------+------+------------------------
 postgresql-2026-11-06_143049.log |  560 | 2026-11-06 14:30:49+00
(1 row)

```

## Interpretación y respuestas

La ruta que devuelve `pg_current_logfile()` es relativa al directorio de datos. La vista `dba.bitacora` permite filtrar la bitácora con SQL, pero solo lee el archivo vigente. Cuando el colector rota el archivo o el servidor se reinicia, empieza uno nuevo; `pg_ls_logdir()` muestra todos.

1. **¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?** El colector es un proceso auxiliar que el proceso principal crea al arrancar. Al arrancar también le redirige la salida de error de todos los demás procesos. Esa estructura no puede montarse ni desmontarse con el servidor en marcha, y por eso el parámetro tiene contexto `postmaster`. `log_statement`, en cambio, lo consulta cada proceso en el momento de ejecutar una sentencia, así que basta con que vuelvan a leer la configuración. Su contexto es `superuser`; el de los demás parámetros de la Actividad 4 es `sighup`. La columna `context` de `pg_settings` muestra el contexto de cada parámetro.
2. **¿Qué ventaja tiene leer la bitácora con SQL? ¿Qué riesgo introduce?**
   - *Ventaja:* la misma consulta funciona en Linux, macOS, Windows o un contenedor. No requiere cuenta ni privilegios en el sistema operativo, puede hacerse remotamente y se filtra con `LIKE`, expresiones regulares o agregaciones.
   - *Riesgo:* `pg_read_file` lee cualquier archivo al que el proceso del servidor tenga acceso, como `pg_hba.conf`, las claves TLS o los propios datos. Quien pueda usarla tiene la bitácora completa, con las contraseñas y los datos personales que contenga. Además, el acceso a la evidencia queda en la misma cuenta que administra la base.
3. **¿Quién debería poder consultar `dba.bitacora`?** Solo el DBA y, como mucho, un rol de seguridad o auditoría designado; el esquema `dba` no tiene acceso para `PUBLIC`. Otorgar `SELECT` sobre la vista no bastaría. Las funciones que usa una vista se verifican con los privilegios de quien la consulta, así que también habría que otorgar `EXECUTE` sobre `pg_read_file`, y eso abre la lectura de cualquier archivo. Si otra área necesita la bitácora, se le entrega una copia exportada o centralizada, no ese privilegio.
