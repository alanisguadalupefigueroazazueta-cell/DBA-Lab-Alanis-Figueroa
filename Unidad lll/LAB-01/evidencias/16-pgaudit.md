# Evidencia 16 — pgaudit (Parte C)

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividades 18 y 19 |
| Fecha de ejecución | 2026-11-06 14:32:32 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## 24.1 El servidor ve la extensión

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, default_version FROM pg_available_extensions WHERE name = 'pgaudit';
  name   | default_version 
---------+-----------------
 pgaudit | 16.0
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
CREATE EXTENSION pgaudit;
psql:<stdin>:1: ERROR:  pgaudit must be loaded via shared_preload_libraries
```

## 24.2 Cargar la biblioteca al arrancar

*Sesión de administrador (entrada y salida de psql):*

```text
ALTER SYSTEM SET shared_preload_libraries = 'pgaudit';
ALTER SYSTEM
SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'shared_preload_libraries';
           name           | setting | pending_restart 
--------------------------+---------+-----------------
 shared_preload_libraries |         | t
(1 row)

```

*Reinicio del servicio:* `pg_ctlcluster 16 main restart`

## Después del reinicio

*Sesión de administrador (entrada y salida de psql):*

```text
SHOW shared_preload_libraries;
 shared_preload_libraries 
--------------------------
 pgaudit
(1 row)

CREATE EXTENSION pgaudit;
CREATE EXTENSION
SELECT extname, extversion FROM pg_extension WHERE extname = 'pgaudit';
 extname | extversion 
---------+------------
 pgaudit | 16.0
(1 row)

```

## Actividad 19 — Auditoría de objeto sobre columnas sensibles

*Sesión de administrador (entrada y salida de psql):*

```text
CREATE ROLE auditor_datos NOLOGIN;
CREATE ROLE
GRANT SELECT (rfc, telefono), UPDATE (rfc, telefono) ON clientes TO auditor_datos;
GRANT
ALTER SYSTEM SET pgaudit.log = 'role, ddl';
ALTER SYSTEM
ALTER SYSTEM SET pgaudit.role = 'auditor_datos';
ALTER SYSTEM
ALTER SYSTEM SET pgaudit.log_relation = on;
ALTER SYSTEM
SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

```

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT nombre, ciudad FROM clientes WHERE id = 2" -c "SELECT nombre, rfc FROM clientes WHERE id = 3" -c "SELECT * FROM clientes WHERE id = 4" -c "UPDATE clientes SET rfc = 'LOAA850315XXX' WHERE id = 1" -c "UPDATE clientes SET ciudad = 'Navolato' WHERE id = 2"
```

```text
    nombre    |  ciudad  
--------------+----------
 Carlos Pérez | Culiacán
(1 row)

    nombre    |      rfc      
--------------+---------------
 María García | GAMA780912GHI
(1 row)

 id |   nombre    |          correo          |  telefono  |      rfc      | edad |   ciudad   | codigo_postal | fecha_alta | segmento 
----+-------------+--------------------------+------------+---------------+------+------------+---------------+------------+----------
  4 | Luis Torres | luis.torres@example.test | 6674567890 | TOLU920201JKL |   34 | Los Mochis | 81200         | 2026-11-06 | regular
(1 row)

UPDATE 1
UPDATE 1
```

*Sesión de administrador (entrada y salida de psql):*

```text
GRANT SELECT ON clientes TO soporte_ana;
GRANT
```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%AUDIT:%';
                                                                                                               linea                                                                                                               
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:32:39.419 UTC [900] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,1,1,READ,SELECT,TABLE,public.clientes,"SELECT nombre, rfc FROM clientes WHERE id = 3",<not logged>
 2026-11-06 14:32:39.419 UTC [900] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,2,1,READ,SELECT,TABLE,public.clientes,SELECT * FROM clientes WHERE id = 4,<not logged>
 2026-11-06 14:32:39.419 UTC [900] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  AUDIT: OBJECT,3,1,WRITE,UPDATE,TABLE,public.clientes,UPDATE clientes SET rfc = 'LOAA850315XXX' WHERE id = 1,<not logged>
 2026-11-06 14:32:39.449 UTC [907] user=postgres db=comercial app=psql client=[local] LOG:  AUDIT: SESSION,1,1,ROLE,GRANT,TABLE,,GRANT SELECT ON clientes TO soporte_ana;,<not logged>
(4 rows)

```

## Verificación de la Parte C

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT extname, extversion FROM pg_extension WHERE extname = 'pgaudit';
 extname | extversion 
---------+------------
 pgaudit | 16.0
(1 row)

SHOW shared_preload_libraries;
 shared_preload_libraries 
--------------------------
 pgaudit
(1 row)

SELECT count(*) FILTER (WHERE linea ~ 'AUDIT: OBJECT,.*READ.*nombre, rfc')     AS lectura_rfc_registrada,
       count(*) FILTER (WHERE linea ~ 'AUDIT: .*SELECT nombre, ciudad')        AS lectura_ciudad_registrada
FROM dba.bitacora;
 lectura_rfc_registrada | lectura_ciudad_registrada 
------------------------+---------------------------
                      1 |                         0
(1 row)

```

## Interpretación y respuestas

`CREATE EXTENSION` falló con `pgaudit must be loaded via shared_preload_libraries` hasta que la biblioteca se cargó al arrancar. `pending_restart = t` muestra que el valor ya estaba guardado pero esperaba un reinicio. Las entradas `AUDIT:` no incluyen el usuario; este se obtiene del prefijo de línea (`user=… app=… client=…`).

1. **¿Por qué no apareció `SELECT nombre, ciudad …` y sí apareció `SELECT * …`?** En la auditoría de objeto, pgaudit registra una sentencia solo si toca columnas sobre las que el rol auditor (`auditor_datos`) tiene el privilegio correspondiente. `auditor_datos` solo tiene `SELECT` sobre `rfc` y `telefono`. La primera consulta no lee ninguna de esas columnas. `SELECT *` lee todas, incluidas `rfc` y `telefono`, y por eso se registró como `OBJECT,…,READ`.
2. **¿Por qué no apareció `UPDATE … ciudad …`?** Porque escribe en `ciudad` y lee `id`, y `auditor_datos` no tiene privilegios sobre ninguna de las dos. En cambio, `UPDATE … SET rfc = …` sí escribe en una columna auditada y apareció como `OBJECT,…,WRITE`.
3. **¿Qué diferencia de volumen esperarías frente a `log_statement = 'all'`?** Mucho menor. `all` registra todas las consultas de todas las tablas. pgaudit en modo objeto registra solo las que tocan las columnas sensibles elegidas, más las clases de sesión configuradas (`role` y `ddl`). Es auditoría dirigida: menos volumen, menos datos personales en la bitácora y señales más fáciles de revisar.
4. **pgaudit no puede auditar de forma confiable a los superusuarios. ¿Qué implica para la separación de funciones?** Un superusuario puede cambiar `pgaudit.log` en su propia sesión, modificar la configuración, quitar la biblioteca o leer y alterar los archivos de bitácora. Por eso la auditoría del administrador no puede descansar en mecanismos que él mismo controla. Implica cuatro medidas:
   - El trabajo diario se hace con roles nominativos sin `SUPERUSER`.
   - El uso del superusuario es excepcional, autorizado y revisado (cuenta de emergencia).
   - Las bitácoras se envían en tiempo real a un sistema externo custodiado por otra área.
   - La revisión la hace alguien distinto de quien administra.
