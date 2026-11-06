# Evidencia 09 — Sesiones activas con pg_stat_activity

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 9 |
| Fecha de ejecución | 2026-11-06 14:30:59 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Segunda terminal (reporte de larga duración):*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://soporte_ana@127.0.0.1/comercial?application_name=reporte-mensual" -c "SELECT pg_sleep(90)"
```

## Mientras se ejecuta el reporte

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
 pid |   usename   | application_name | client_addr |         backend_start         | state  |             query              
-----+-------------+------------------+-------------+-------------------------------+--------+--------------------------------
 522 | postgres    | psql             |             | 2026-11-06 14:31:02.858106+00 | active | SELECT pid, usename, applicati
 515 | soporte_ana | reporte-mensual  | 127.0.0.1   | 2026-11-06 14:30:59.849969+00 | active | SELECT pg_sleep(90)
(2 rows)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%[515]%' ORDER BY num;
                                                                                                                                  linea                                                                                                                                   
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:59.850 UTC [515] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=52942
 2026-11-06 14:30:59.857 UTC [515] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="soporte_ana" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
 2026-11-06 14:30:59.857 UTC [515] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=soporte_ana database=comercial application_name=reporte-mensual SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
(3 rows)

```

## Salida del reporte

```text
 pg_sleep 
----------
 
(1 row)

```

## Después de que terminó el reporte

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
 pid | usename  | application_name | client_addr |         backend_start         | state  |             query              
-----+----------+------------------+-------------+-------------------------------+--------+--------------------------------
 551 | postgres | psql             |             | 2026-11-06 14:32:30.924066+00 | active | SELECT pid, usename, applicati
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%[515]%' ORDER BY num;
                                                                                                                                  linea                                                                                                                                   
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:59.850 UTC [515] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=52942
 2026-11-06 14:30:59.857 UTC [515] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="soporte_ana" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
 2026-11-06 14:30:59.857 UTC [515] user=soporte_ana db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=soporte_ana database=comercial application_name=reporte-mensual SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
 2026-11-06 14:32:29.888 UTC [515] user=soporte_ana db=comercial app=reporte-mensual client=127.0.0.1 LOG:  disconnection: session time: 0:01:30.038 user=soporte_ana database=comercial host=127.0.0.1 port=52942
(4 rows)

```

## Interpretación y respuestas

1. **¿Qué columna relaciona una sesión con sus líneas de bitácora?** `pid` en `pg_stat_activity`, que corresponde al `[%p]` del prefijo de cada línea.
2. **Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?** Solo la bitácora: la conexión recibida, autenticada y autorizada, y la desconexión con la duración de la sesión. `pg_stat_activity` ya no tiene esa fila, porque solo muestra los procesos vivos. Con `log_statement = mod`, la bitácora tampoco guarda qué consulta ejecutó el reporte; eso solo se vio mientras estaba activo.
3. **¿Por qué `client_addr` aparece vacío en la sesión del administrador?** Porque esa sesión entra por el socket Unix local, no por TCP, así que no hay dirección IP de cliente: `client_addr` es `NULL` y la bitácora muestra `client=[local]`.

En resumen, `pg_stat_activity` da el estado actual: qué se está ejecutando, desde cuándo, en qué estado y con qué consulta. La bitácora da la historia: lo que ya terminó.
