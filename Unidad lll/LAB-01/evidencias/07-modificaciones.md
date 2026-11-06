# Evidencia 07 — Modificaciones de datos: ddl frente a mod

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 7 |
| Fecha de ejecución | 2026-11-06 14:30:55 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## Con log_statement = 'ddl'

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3"
```

```text
UPDATE 1
```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%user=app_ventas%' ORDER BY num DESC LIMIT 3;
                                                                                                                                 linea                                                                                                                                 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:55.600 UTC [455] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.009 user=app_ventas database=comercial host=127.0.0.1 port=50340
 2026-11-06 14:30:55.599 UTC [455] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
 2026-11-06 14:30:55.599 UTC [455] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="app_ventas" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
(3 rows)

```

## Cambio a log_statement = 'mod'

*Sesión de administrador (entrada y salida de psql):*

```text
ALTER SYSTEM SET log_statement = 'mod';
ALTER SYSTEM
SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

```

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"
```

```text
UPDATE 1
    nombre    |      rfc      
--------------+---------------
 María García | GAMA780912XYZ
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;
                                                                                    linea                                                                                     
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:52.239 UTC [291] user= db= app= client= LOG:  parameter "log_statement" changed to "ddl"
 2026-11-06 14:30:56.655 UTC [470] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER SYSTEM SET log_statement = 'mod';
 2026-11-06 14:30:56.657 UTC [291] user= db= app= client= LOG:  parameter "log_statement" changed to "mod"
 2026-11-06 14:30:58.694 UTC [477] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3
(4 rows)

```

## Interpretación y respuestas

**Análisis.**
- Con `ddl`, el cambio del RFC a `GAMA780912XYZ` deja solo la conexión y la desconexión de `app_ventas`; la sentencia no aparece.
- Con `mod`, el `UPDATE` del teléfono queda con quién, cuándo, desde qué IP, con qué aplicación y qué sentencia.
- El `SELECT` que leyó el RFC no aparece, porque `mod` no registra lecturas.
- Esta vez el `ALTER SYSTEM SET log_statement = 'mod'` sí se registró, porque `log_statement` ya valía `ddl` cuando se ejecutó.

1. **¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría?** `all`. Con miles de consultas por minuto, el registro escribiría una línea por consulta, y eso tiene varios costos:
   - gigabytes de bitácora al día y escritura adicional en disco que compite con la base;
   - rotaciones frecuentes y búsquedas más lentas;
   - sobre todo, la bitácora pasaría a contener los valores consultados (filtros por RFC o por nombre) y se convertiría en otra copia de datos personales.
2. **¿Qué le falta a esta bitácora para revertir el cambio con certeza?** El valor anterior. La sentencia dice qué se escribió (`telefono = '6679990000'`), pero no qué se sobrescribió. Tampoco dice qué filas cambiaron cuando el `WHERE` es amplio. Para revertir con certeza hace falta el estado previo de cada registro afectado, que es lo que resuelve la tabla de auditoría de la Parte B.
