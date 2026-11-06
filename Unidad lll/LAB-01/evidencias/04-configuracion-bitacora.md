# Evidencia 04 — Configuración de la bitácora

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 4 |
| Fecha de ejecución | 2026-11-06 14:30:52 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión de administrador (entrada y salida de psql):*

```text
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM
ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM
SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');
      name       |                 setting                 |       source       |                    sourcefile                    
-----------------+-----------------------------------------+--------------------+--------------------------------------------------
 log_connections | on                                      | configuration file | /var/lib/postgresql/16/main/postgresql.auto.conf
 log_line_prefix | %m [%p] user=%u db=%d app=%a client=%h  | configuration file | /var/lib/postgresql/16/main/postgresql.auto.conf
 log_statement   | ddl                                     | configuration file | /var/lib/postgresql/16/main/postgresql.auto.conf
(3 rows)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;
 num |                                                                                                linea                                                                                                
-----+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  17 | 2026-11-06 14:30:54.298 UTC [378] user=postgres db=comercial app=[unknown] client=[local] LOG:  connection authorized: user=postgres database=comercial application_name=psql
  16 | 2026-11-06 14:30:54.298 UTC [378] user=postgres db=comercial app=[unknown] client=[local] LOG:  connection authenticated: identity="postgres" method=peer (/etc/postgresql/16/main/pg_hba.conf:118)
  15 | 2026-11-06 14:30:54.297 UTC [378] user=[unknown] db=[unknown] app=[unknown] client=[local] LOG:  connection received: host=[local]
  14 | 2026-11-06 14:30:54.276 UTC [371] user=postgres db=comercial app=psql client=[local] LOG:  disconnection: session time: 0:00:00.006 user=postgres database=comercial host=[local]
  13 | 2026-11-06 14:30:54.271 UTC [371] user=postgres db=comercial app=[unknown] client=[local] LOG:  connection authorized: user=postgres database=comercial application_name=psql
  12 | 2026-11-06 14:30:54.271 UTC [371] user=postgres db=comercial app=[unknown] client=[local] LOG:  connection authenticated: identity="postgres" method=peer (/etc/postgresql/16/main/pg_hba.conf:118)
(6 rows)

```

## Interpretación y respuestas

**Análisis.** Los cuatro parámetros provienen ahora de `postgresql.auto.conf` (`source = configuration file`). Las sentencias `ALTER SYSTEM` no aparecen en la bitácora, porque al ejecutarse `log_statement` todavía valía `none`. Sí aparecen las líneas `parameter … changed to …`, que corresponden al cambio de configuración. También aparece la propia sesión de administrador que consultó la bitácora: consultar la bitácora también deja rastro.

1. **¿Por qué el proceso que registra el cambio es el principal y no tu sesión?** `pg_reload_conf()` solo envía una señal (SIGHUP) al proceso principal. Ese proceso relee `postgresql.conf` y `postgresql.auto.conf`, detecta qué valores cambiaron, escribe `parameter … changed to …` y reenvía la señal a los procesos hijos. Por eso la línea lleva el PID del proceso principal y campos de usuario vacíos: no pertenece a ninguna sesión. Consecuencia: esa línea no dice *quién* pidió el cambio. Para eso se necesita la sentencia `ALTER SYSTEM` registrada por la sesión.
2. **¿Qué pasaría con `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?** Sí, si `log_statement` valía `ddl` o `mod`. La sentencia se registra antes de ejecutarse, con usuario, base, aplicación y cliente. Después, al recargar, el proceso principal escribe `parameter "log_statement" changed to "none"`. Lo que se pierde es todo lo posterior: se sabe que alguien apagó el registro, pero no qué hizo después. Hay un caso peor: un superusuario puede ejecutar `SET log_statement = 'none'` solo para su sesión. `SET` no es DDL, así que no se registra con `ddl` ni con `mod`, y tampoco produce mensaje del proceso principal.
3. **¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?** Hay cuatro razones:
   - El archivo lo administra el servidor: cada `ALTER SYSTEM` lo reescribe completo y puede borrar las ediciones manuales. El propio archivo advierte que no se edite.
   - Un error de sintaxis puede impedir que el servidor recargue o arranque.
   - Una edición manual no deja ninguna sentencia en la bitácora.
   - `ALTER SYSTEM`, en cambio, valida el nombre y el valor del parámetro antes de guardarlo.
