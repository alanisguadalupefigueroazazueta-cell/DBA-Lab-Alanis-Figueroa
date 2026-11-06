# Evidencia 15 — Cronología y respuestas a Dirección

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 17 y verificación final (sección 26) |
| Fecha de ejecución | 2026-11-06 14:32:32 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## Consulta utilizada

```sql
-- LAB-01 · Actividad 17 — Cronología unificada (bitácora + tabla de auditoría)
-- Lee TODOS los archivos del colector (no solo el vigente), clasifica cada evento
-- por tipo y produce filas de tabla Markdown. Sesión de administrador.
WITH archivos AS (
    SELECT name FROM pg_ls_logdir() WHERE name LIKE '%.log'
),
lineas AS (
    SELECT a.name AS archivo, t.n AS num, t.linea
    FROM archivos a
    CROSS JOIN LATERAL regexp_split_to_table(
        pg_read_file(current_setting('log_directory') || '/' || a.name), E'\n'
    ) WITH ORDINALITY AS t(linea, n)
    WHERE t.linea ~ '^\d{4}-\d{2}-\d{2} '
),
p AS (
    SELECT archivo, num, linea,
           substring(linea FROM '^(\S+ \S+ \S+)')::timestamptz      AS ts,
           substring(linea FROM '^\S+ \S+ \S+ \[(\d+)\]')           AS pid,
           substring(linea FROM '^\S+ \S+ \S+ \[\d+\] user=(\S*)')  AS usuario,
           substring(linea FROM ' client=(\S*) ')                   AS cliente,
           substring(linea FROM ' (?:LOG|ERROR|FATAL):  (.*)$')     AS mensaje,
           substring(linea FROM ' LOG:  statement: (.*)$')          AS sentencia
    FROM lineas
),
c AS (
    SELECT p.*,
           CASE
             WHEN mensaje ~ '^parameter ".+" changed to'                    THEN 'Configuración'
             WHEN sentencia ~* '^ALTER SYSTEM'                              THEN 'Configuración'
             WHEN mensaje ~ '^password authentication failed'               THEN 'Acceso'
             WHEN mensaje ~ '^connection authorized' AND usuario <> 'postgres' THEN 'Acceso'
             WHEN sentencia ~* '^(GRANT|REVOKE|CREATE ROLE|DROP ROLE|ALTER ROLE|CREATE USER|ALTER USER|DROP USER)' THEN 'Privilegio'
             WHEN sentencia ~* '^(CREATE|ALTER|DROP|COMMENT)'               THEN 'Estructura'
             WHEN sentencia ~* '^(INSERT|UPDATE|DELETE|TRUNCATE|COPY)'      THEN 'Datos'
             WHEN linea ~ ' ERROR:  '                                       THEN 'Error'
           END AS tipo
    FROM p
),
eventos_log AS (
    SELECT c.ts, c.archivo, c.num,
           coalesce(nullif(c.usuario, ''), '(servidor)')                    AS usuario,
           coalesce(nullif(c.cliente, ''), '—')                             AS cliente,
           c.tipo,
           left(coalesce(c.sentencia, c.mensaje), 110)                      AS que,
           CASE
             WHEN c.tipo = 'Error' OR c.mensaje ~ '^password authentication failed' THEN 'No'
             WHEN c.sentencia IS NOT NULL AND EXISTS (
                  SELECT 1 FROM p e
                  WHERE e.archivo = c.archivo AND e.pid = c.pid
                    AND e.num BETWEEN c.num + 1 AND c.num + 6
                    AND substring(e.linea FROM ' STATEMENT:  (.*)$') = c.sentencia) THEN 'No'
             ELSE 'Sí'
           END                                                              AS exito,
           'bitácora ' || c.archivo || ':' || c.num                         AS fuente
    FROM c
    WHERE c.tipo IS NOT NULL
),
eventos_aud AS (
    SELECT a.momento, '', a.id_evento,
           a.usuario_sesion,
           coalesce(host(a.ip_cliente), '[local]'),
           'Datos (auditoría)',
           left(a.operacion || ' id_cliente=' || a.id_cliente || ' ' ||
                CASE a.operacion
                  WHEN 'UPDATE' THEN coalesce((
                       SELECT string_agg(d.key || ': ' || coalesce(a.valores_antes ->> d.key, 'NULL')
                                         || ' → ' || coalesce(d.value #>> '{}', 'NULL'), '; ')
                       FROM jsonb_each(a.valores_despues) d
                       WHERE a.valores_antes -> d.key IS DISTINCT FROM d.value), 'sin cambios')
                  WHEN 'INSERT' THEN 'alta: ' || coalesce(a.valores_despues ->> 'nombre', '')
                                     || ', rfc ' || coalesce(a.valores_despues ->> 'rfc', '')
                  WHEN 'DELETE' THEN 'baja: ' || coalesce(a.valores_antes ->> 'nombre', '')
                                     || ', rfc ' || coalesce(a.valores_antes ->> 'rfc', '')
                  ELSE ''
                END, 110),
           'Sí',
           'auditoría id_evento=' || a.id_evento
    FROM auditoria.cambios_clientes a
),
todos AS (
    SELECT * FROM eventos_log
    UNION ALL
    SELECT * FROM eventos_aud
)
SELECT '| ' || row_number() OVER (ORDER BY ts, archivo, num) || ' | '
       || to_char(ts AT TIME ZONE current_setting('log_timezone'), 'YYYY-MM-DD HH24:MI:SS.MS') || ' | '
       || usuario || ' | ' || cliente || ' | ' || tipo || ' | `'
       || replace(que, '|', '\|') || '` | ' || exito || ' | ' || fuente || ' |'
FROM todos
ORDER BY ts, archivo, num;
```

## Cronología reconstruida desde la bitácora y la tabla de auditoría

Horas en la zona `Etc/UTC` (log_timezone). Se omiten las conexiones del administrador para no saturar la tabla.

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-06 14:30:52.239 | (servidor) | — | Configuración | `parameter "log_connections" changed to "on"` | Sí | bitácora postgresql-2026-11-06_143049.log:7 |
| 2 | 2026-11-06 14:30:52.239 | (servidor) | — | Configuración | `parameter "log_disconnections" changed to "on"` | Sí | bitácora postgresql-2026-11-06_143049.log:8 |
| 3 | 2026-11-06 14:30:52.239 | (servidor) | — | Configuración | `parameter "log_line_prefix" changed to "%m [%p] user=%u db=%d app=%a client=%h "` | Sí | bitácora postgresql-2026-11-06_143049.log:9 |
| 4 | 2026-11-06 14:30:52.239 | (servidor) | — | Configuración | `parameter "log_statement" changed to "ddl"` | Sí | bitácora postgresql-2026-11-06_143049.log:10 |
| 5 | 2026-11-06 14:30:54.332 | app_ventas | 127.0.0.1 | Acceso | `password authentication failed for user "app_ventas"` | No | bitácora postgresql-2026-11-06_143049.log:20 |
| 6 | 2026-11-06 14:30:54.336 | app_ventas | 127.0.0.1 | Acceso | `password authentication failed for user "app_ventas"` | No | bitácora postgresql-2026-11-06_143049.log:23 |
| 7 | 2026-11-06 14:30:54.366 | usuario_inexistente | 127.0.0.1 | Acceso | `password authentication failed for user "usuario_inexistente"` | No | bitácora postgresql-2026-11-06_143049.log:26 |
| 8 | 2026-11-06 14:30:54.370 | usuario_inexistente | 127.0.0.1 | Acceso | `password authentication failed for user "usuario_inexistente"` | No | bitácora postgresql-2026-11-06_143049.log:30 |
| 9 | 2026-11-06 14:30:54.399 | app_ventas | 127.0.0.1 | Acceso | `connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protoco` | Sí | bitácora postgresql-2026-11-06_143049.log:35 |
| 10 | 2026-11-06 14:30:55.485 | postgres | [local] | Privilegio | `REVOKE UPDATE ON clientes FROM soporte_ana;` | Sí | bitácora postgresql-2026-11-06_143049.log:48 |
| 11 | 2026-11-06 14:30:55.486 | postgres | [local] | Privilegio | `GRANT UPDATE ON clientes TO app_ventas;` | Sí | bitácora postgresql-2026-11-06_143049.log:49 |
| 12 | 2026-11-06 14:30:55.486 | postgres | [local] | Estructura | `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);` | Sí | bitácora postgresql-2026-11-06_143049.log:50 |
| 13 | 2026-11-06 14:30:55.512 | postgres | [local] | Privilegio | `CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';` | Sí | bitácora postgresql-2026-11-06_143049.log:55 |
| 14 | 2026-11-06 14:30:55.515 | postgres | [local] | Privilegio | `DROP ROLE rol_temporal;` | Sí | bitácora postgresql-2026-11-06_143049.log:56 |
| 15 | 2026-11-06 14:30:55.599 | app_ventas | 127.0.0.1 | Acceso | `connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protoco` | Sí | bitácora postgresql-2026-11-06_143049.log:68 |
| 16 | 2026-11-06 14:30:56.655 | postgres | [local] | Configuración | `ALTER SYSTEM SET log_statement = 'mod';` | Sí | bitácora postgresql-2026-11-06_143049.log:77 |
| 17 | 2026-11-06 14:30:56.657 | (servidor) | — | Configuración | `parameter "log_statement" changed to "mod"` | Sí | bitácora postgresql-2026-11-06_143049.log:79 |
| 18 | 2026-11-06 14:30:58.693 | app_ventas | 127.0.0.1 | Acceso | `connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protoco` | Sí | bitácora postgresql-2026-11-06_143049.log:83 |
| 19 | 2026-11-06 14:30:58.694 | app_ventas | 127.0.0.1 | Datos | `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` | Sí | bitácora postgresql-2026-11-06_143049.log:84 |
| 20 | 2026-11-06 14:30:59.767 | soporte_ana | 127.0.0.1 | Acceso | `connection authorized: user=soporte_ana database=comercial application_name=psql SSL enabled (protocol=TLSv1.3` | Sí | bitácora postgresql-2026-11-06_143049.log:92 |
| 21 | 2026-11-06 14:30:59.768 | soporte_ana | 127.0.0.1 | Datos | `DELETE FROM clientes WHERE id = 5` | No | bitácora postgresql-2026-11-06_143049.log:93 |
| 22 | 2026-11-06 14:30:59.769 | soporte_ana | 127.0.0.1 | Error | `permission denied for table clientes` | No | bitácora postgresql-2026-11-06_143049.log:94 |
| 23 | 2026-11-06 14:30:59.795 | postgres | [local] | Privilegio | `DROP ROLE soporte_ana;` | No | bitácora postgresql-2026-11-06_143049.log:100 |
| 24 | 2026-11-06 14:30:59.795 | postgres | [local] | Error | `role "soporte_ana" cannot be dropped because some objects depend on it` | No | bitácora postgresql-2026-11-06_143049.log:101 |
| 25 | 2026-11-06 14:30:59.857 | soporte_ana | 127.0.0.1 | Acceso | `connection authorized: user=soporte_ana database=comercial application_name=reporte-mensual SSL enabled (proto` | Sí | bitácora postgresql-2026-11-06_143049.log:111 |
| 26 | 2026-11-06 14:32:30.993 | postgres | [local] | Estructura | `CREATE SCHEMA auditoria;` | Sí | bitácora postgresql-2026-11-06_143049.log:136 |
| 27 | 2026-11-06 14:32:30.994 | postgres | [local] | Privilegio | `REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;` | Sí | bitácora postgresql-2026-11-06_143049.log:137 |
| 28 | 2026-11-06 14:32:30.994 | postgres | [local] | Estructura | `CREATE TABLE auditoria.cambios_clientes (` | Sí | bitácora postgresql-2026-11-06_143049.log:138 |
| 29 | 2026-11-06 14:32:31.038 | postgres | [local] | Estructura | `CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()` | Sí | bitácora postgresql-2026-11-06_143049.log:154 |
| 30 | 2026-11-06 14:32:31.040 | postgres | [local] | Privilegio | `REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC;` | Sí | bitácora postgresql-2026-11-06_143049.log:177 |
| 31 | 2026-11-06 14:32:31.040 | postgres | [local] | Estructura | `CREATE TRIGGER trg_auditoria_clientes` | Sí | bitácora postgresql-2026-11-06_143049.log:178 |
| 32 | 2026-11-06 14:32:31.101 | app_ventas | 127.0.0.1 | Acceso | `connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protoco` | Sí | bitácora postgresql-2026-11-06_143049.log:188 |
| 33 | 2026-11-06 14:32:31.101 | app_ventas | 127.0.0.1 | Datos | `UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3` | Sí | bitácora postgresql-2026-11-06_143049.log:189 |
| 34 | 2026-11-06 14:32:31.101 | app_ventas | 127.0.0.1 | Datos (auditoría) | `UPDATE id_cliente=3 rfc: GAMA780912XYZ → GAMA780912ZZZ` | Sí | auditoría id_evento=1 |
| 35 | 2026-11-06 14:32:31.135 | app_ventas | 127.0.0.1 | Acceso | `connection authorized: user=app_ventas database=comercial application_name=psql SSL enabled (protocol=TLSv1.3,` | Sí | bitácora postgresql-2026-11-06_143049.log:193 |
| 36 | 2026-11-06 14:32:31.136 | app_ventas | 127.0.0.1 | Error | `permission denied for schema auditoria at character 15` | No | bitácora postgresql-2026-11-06_143049.log:194 |
| 37 | 2026-11-06 14:32:31.219 | postgres | [local] | Datos | `INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)` | Sí | bitácora postgresql-2026-11-06_143049.log:208 |
| 38 | 2026-11-06 14:32:31.219 | postgres | [local] | Datos (auditoría) | `INSERT id_cliente=6 alta: Pedro Ruiz, rfc RUPE950101AAA` | Sí | auditoría id_evento=2 |
| 39 | 2026-11-06 14:32:31.221 | postgres | [local] | Datos | `DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';` | Sí | bitácora postgresql-2026-11-06_143049.log:210 |
| 40 | 2026-11-06 14:32:31.221 | postgres | [local] | Datos (auditoría) | `DELETE id_cliente=6 baja: Pedro Ruiz, rfc RUPE950101AAA` | Sí | auditoría id_evento=3 |
| 41 | 2026-11-06 14:32:31.254 | app_ventas | 127.0.0.1 | Acceso | `connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protoco` | Sí | bitácora postgresql-2026-11-06_143049.log:214 |
| 42 | 2026-11-06 14:32:31.254 | app_ventas | 127.0.0.1 | Datos | `DELETE FROM auditoria.cambios_clientes` | No | bitácora postgresql-2026-11-06_143049.log:215 |
| 43 | 2026-11-06 14:32:31.254 | app_ventas | 127.0.0.1 | Error | `permission denied for schema auditoria at character 13` | No | bitácora postgresql-2026-11-06_143049.log:216 |
| 44 | 2026-11-06 14:32:31.254 | app_ventas | 127.0.0.1 | Estructura | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` | No | bitácora postgresql-2026-11-06_143049.log:218 |
| 45 | 2026-11-06 14:32:31.255 | app_ventas | 127.0.0.1 | Error | `must be owner of table clientes` | No | bitácora postgresql-2026-11-06_143049.log:219 |
| 46 | 2026-11-06 14:32:31.281 | postgres | [local] | Estructura | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;` | Sí | bitácora postgresql-2026-11-06_143049.log:225 |
| 47 | 2026-11-06 14:32:31.281 | postgres | [local] | Datos | `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;` | Sí | bitácora postgresql-2026-11-06_143049.log:226 |
| 48 | 2026-11-06 14:32:31.281 | postgres | [local] | Estructura | `ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;` | Sí | bitácora postgresql-2026-11-06_143049.log:227 |
| 49 | 2026-11-06 14:32:31.368 | soporte_ana | 127.0.0.1 | Acceso | `connection authorized: user=soporte_ana database=comercial application_name=psql SSL enabled (protocol=TLSv1.3` | Sí | bitácora postgresql-2026-11-06_143049.log:239 |
| 50 | 2026-11-06 14:32:32.400 | postgres | [local] | Datos | `UPDATE clientes SET segmento = 'regular';` | Sí | bitácora postgresql-2026-11-06_143049.log:244 |
| 51 | 2026-11-06 14:32:32.400 | postgres | [local] | Datos (auditoría) | `UPDATE id_cliente=1 segmento: NULL → regular` | Sí | auditoría id_evento=4 |
| 52 | 2026-11-06 14:32:32.400 | postgres | [local] | Datos (auditoría) | `UPDATE id_cliente=2 segmento: NULL → regular` | Sí | auditoría id_evento=5 |
| 53 | 2026-11-06 14:32:32.400 | postgres | [local] | Datos (auditoría) | `UPDATE id_cliente=4 segmento: NULL → regular` | Sí | auditoría id_evento=6 |
| 54 | 2026-11-06 14:32:32.400 | postgres | [local] | Datos (auditoría) | `UPDATE id_cliente=5 segmento: NULL → regular` | Sí | auditoría id_evento=7 |
| 55 | 2026-11-06 14:32:32.400 | postgres | [local] | Datos (auditoría) | `UPDATE id_cliente=3 segmento: NULL → regular` | Sí | auditoría id_evento=8 |

## Respuestas a Dirección (solo con evidencia)

La tabla anterior cumple el mínimo de ocho eventos y cubre los seis tipos. Las referencias de la columna *Fuente* (`bitácora archivo:línea` o `auditoría id_evento=N`) permiten citar cada evento.

### 1. ¿Quién hizo cada cambio del RFC?

| Cambio | Valor nuevo | Evidencia disponible | Conclusión |
|---|---|---|---|
| Actividad 3 | `GAMA780912XXX` | Ninguna. Sin conexiones ni sentencias registradas y sin tabla de auditoría | **No hay evidencia.** Es un hueco: no puede fecharse ni atribuirse |
| Actividad 7 | `GAMA780912XYZ` | Con `log_statement = ddl` solo hay líneas de conexión y desconexión de `app_ventas` en ese momento; el `UPDATE` no está | **No hay evidencia directa del `UPDATE`.** Solo consta que existió una sesión de `app_ventas` a esa hora. El valor `XYZ` se confirma después como `valores_antes` del primer evento de auditoría |
| Actividad 12 | `GAMA780912ZZZ` | Bitácora (`statement: UPDATE … rfc`) y auditoría (`UPDATE`, `id_cliente = 3`) | **`app_ventas`**, desde la IP registrada, con `application_name = app-ventas-web`, a la hora indicada en la tabla |
| Actividad 14 | `GAMA780912GHI` | Bitácora: `postgres` por socket local (`[local]`, `psql`), entre `DISABLE TRIGGER` y `ENABLE TRIGGER`. Sin fila de auditoría | **`postgres`**, con el disparador desactivado. Las filas de auditoría del `UPDATE … segmento` (Actividad 15) muestran `GHI` en `valores_antes`, lo que confirma el cambio no auditado |

### 2. ¿Quién cambió el teléfono?

**`app_ventas`**, en la Actividad 7, desde la IP y con la aplicación `app-ventas-web` que registra la línea `statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3`. **Su valor anterior: no hay evidencia.** La tabla de auditoría aún no existía y la bitácora no guarda valores previos.

### 3. ¿Cuándo, y desde qué aplicación o equipo?

Las horas, aplicaciones y direcciones de cada evento registrado están en la tabla de cronología. Para los cambios de las Actividades 3 y 7 no hay hora, aplicación ni equipo registrados, y no se estiman.

### 4. ¿Hubo intentos de acceso fallidos?

**Sí, en la Actividad 5:** uno con contraseña incorrecta para `app_ventas` y uno para el rol inexistente `usuario_inexistente`, ambos desde la IP del cliente que muestra la tabla.

**Antes del primer cambio del RFC (Actividad 3):** no se registró ningún intento fallido contra `app_ventas`. La búsqueda de la Actividad 3 no encontró ninguna línea con `app_ventas`, y un rechazo de autenticación se escribe como `FATAL` aunque `log_connections` esté apagado. Pero con el prefijo `%m [%p]` no se habría sabido desde qué equipo. Además, antes de activar el colector (Actividad 2), la salida dependía del mecanismo de despliegue. Para ese periodo: **no hay evidencia.**

### 5. ¿Qué valor tenía el RFC antes de cada cambio?

| Cambio | Valor anterior | Fuente |
|---|---|---|
| Actividad 3 | `GAMA780912GHI` según el script de carga | **No hay evidencia en el servidor**: la carga inicial no se registró |
| Actividad 7 | `GAMA780912XXX` | **No hay evidencia en el servidor**: se conoce solo porque lo escribimos en la Actividad 3 |
| Actividad 12 | `GAMA780912XYZ` | Auditoría, `valores_antes` del evento `UPDATE` de `app_ventas` |
| Actividad 14 | `GAMA780912ZZZ` | Inferido: es el último `valores_despues` auditado y la bitácora no muestra otro cambio intermedio. El cambio mismo no tiene fila de auditoría |

### Huecos declarados

| Hueco | Por qué no hay evidencia |
|---|---|
| `UPDATE` del RFC de la Actividad 3 | `log_connections = off`, `log_statement = none` y no existía la auditoría |
| `UPDATE` del RFC de la Actividad 7 | `log_statement = ddl` no registra sentencias de datos |
| Valor anterior del teléfono | La auditoría se creó después (Actividad 10) |
| Lectura del RFC en las Actividades 7 y 15 | `mod` no registra `SELECT` y no hay disparador para lecturas |
| Valor anterior en la Actividad 14 dentro de la auditoría | El disparador estaba desactivado |

## Verificación final (sección 26)

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, setting, source FROM pg_settings
WHERE name IN ('logging_collector', 'log_connections', 'log_disconnections', 'log_statement', 'log_line_prefix');
        name        |                 setting                 |       source       
--------------------+-----------------------------------------+--------------------
 log_connections    | on                                      | configuration file
 log_disconnections | on                                      | configuration file
 log_line_prefix    | %m [%p] user=%u db=%d app=%a client=%h  | configuration file
 log_statement      | mod                                     | configuration file
 logging_collector  | on                                      | configuration file
(5 rows)

SELECT 'acceso fallido: contraseña incorrecta' AS verificacion, count(*) FROM dba.bitacora WHERE linea LIKE '%FATAL:  password authentication failed for user "app_ventas"%'
UNION ALL SELECT 'acceso fallido: usuario inexistente', count(*) FROM dba.bitacora WHERE linea LIKE '%Role "usuario_inexistente" does not exist%'
UNION ALL SELECT 'acceso exitoso', count(*) FROM dba.bitacora WHERE linea LIKE '%connection authorized: user=app_ventas%'
UNION ALL SELECT 'desconexión', count(*) FROM dba.bitacora WHERE linea LIKE '%disconnection:%user=app_ventas%'
UNION ALL SELECT 'GRANT', count(*) FROM dba.bitacora WHERE linea LIKE '%statement: GRANT%'
UNION ALL SELECT 'REVOKE', count(*) FROM dba.bitacora WHERE linea LIKE '%statement: REVOKE%'
UNION ALL SELECT 'ALTER TABLE', count(*) FROM dba.bitacora WHERE linea LIKE '%statement: ALTER TABLE clientes ADD COLUMN%'
UNION ALL SELECT 'UPDATE con usuario, IP y aplicación', count(*) FROM dba.bitacora WHERE linea ~ 'user=app_ventas .*app=app-ventas-web client=[0-9A-Fa-f:.]+ LOG:  statement: UPDATE'
UNION ALL SELECT 'error de permisos con su sentencia', count(*) FROM dba.bitacora WHERE linea LIKE '%STATEMENT:  DELETE FROM clientes WHERE id = 5%'
UNION ALL SELECT 'cambio de configuración', count(*) FROM dba.bitacora WHERE linea LIKE '%parameter "%" changed to%'
UNION ALL SELECT 'desactivación del disparador', count(*) FROM dba.bitacora WHERE linea LIKE '%user=postgres%statement: ALTER TABLE clientes DISABLE TRIGGER%'
UNION ALL SELECT 'reactivación del disparador', count(*) FROM dba.bitacora WHERE linea LIKE '%statement: ALTER TABLE clientes ENABLE TRIGGER%';
             verificacion              | count 
---------------------------------------+-------
 acceso fallido: contraseña incorrecta |     2
 acceso fallido: usuario inexistente   |     2
 acceso exitoso                        |     6
 desconexión                           |     6
 GRANT                                 |     1
 REVOKE                                |     3
 ALTER TABLE                           |     1
 UPDATE con usuario, IP y aplicación   |     2
 error de permisos con su sentencia    |     1
 cambio de configuración               |     5
 desactivación del disparador          |     1
 reactivación del disparador           |     1
(12 rows)

SELECT nspname, nspacl FROM pg_namespace WHERE nspname = 'auditoria';
  nspname  |         nspacl         
-----------+------------------------
 auditoria | {postgres=UC/postgres}
(1 row)

SELECT tgname, tgenabled, tgrelid::regclass FROM pg_trigger WHERE NOT tgisinternal;
         tgname         | tgenabled | tgrelid  
------------------------+-----------+----------
 trg_auditoria_clientes | O         | clientes
(1 row)

SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;
 operacion | count 
-----------+-------
 DELETE    |     1
 INSERT    |     1
 UPDATE    |     6
(3 rows)

SELECT id_evento, usuario_sesion, aplicacion, operacion FROM auditoria.cambios_clientes
WHERE operacion = 'UPDATE' AND usuario_sesion = 'app_ventas';
 id_evento | usuario_sesion |   aplicacion   | operacion 
-----------+----------------+----------------+-----------
         1 | app_ventas     | app-ventas-web | UPDATE
(1 row)

```
