# Evidencia 05 — Accesos exitosos y fallidos

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 5 |
| Fecha de ejecución | 2026-11-06 14:30:54 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=incorrecta psql "postgresql://app_ventas@127.0.0.1/comercial" -c "SELECT 1"
```

```text
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "app_ventas"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "app_ventas"
```

*Sesión por red como `usuario_inexistente`:*

```bash
PGPASSWORD=x psql "postgresql://usuario_inexistente@127.0.0.1/comercial" -c "SELECT 1"
```

```text
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "usuario_inexistente"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "usuario_inexistente"
```

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
```

```text
 count 
-------
     5
(1 row)

```

## Líneas de la bitácora de las conexiones por red

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora WHERE linea ~ ' client=[0-9A-Fa-f:.]+ ' ORDER BY num;
                                                                                                                                 linea                                                                                                                                 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:54.324 UTC [387] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=50296
 2026-11-06 14:30:54.332 UTC [387] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
 2026-11-06 14:30:54.332 UTC [387] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
 2026-11-06 14:30:54.333 UTC [388] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=50302
 2026-11-06 14:30:54.336 UTC [388] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
 2026-11-06 14:30:54.336 UTC [388] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
 2026-11-06 14:30:54.359 UTC [394] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=50316
 2026-11-06 14:30:54.366 UTC [394] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "usuario_inexistente"
 2026-11-06 14:30:54.366 UTC [394] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Role "usuario_inexistente" does not exist.
 2026-11-06 14:30:54.367 UTC [395] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=50330
 2026-11-06 14:30:54.370 UTC [395] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "usuario_inexistente"
 2026-11-06 14:30:54.370 UTC [395] user=usuario_inexistente db=comercial app=[unknown] client=127.0.0.1 DETAIL:  Role "usuario_inexistente" does not exist.
 2026-11-06 14:30:54.392 UTC [401] user=[unknown] db=[unknown] app=[unknown] client=127.0.0.1 LOG:  connection received: host=127.0.0.1 port=50338
 2026-11-06 14:30:54.399 UTC [401] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authenticated: identity="app_ventas" method=scram-sha-256 (/etc/postgresql/16/main/pg_hba.conf:125)
 2026-11-06 14:30:54.399 UTC [401] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 LOG:  connection authorized: user=app_ventas database=comercial application_name=app-ventas-web SSL enabled (protocol=TLSv1.3, cipher=TLS_AES_256_GCM_SHA384, bits=256)
 2026-11-06 14:30:54.400 UTC [401] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.008 user=app_ventas database=comercial host=127.0.0.1 port=50338
(16 rows)

```

## Consulta para detectar fuerza bruta: intentos fallidos por usuario y origen

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT substring(linea FROM 'failed for user "([^"]+)"') AS usuario,
       substring(linea FROM ' client=(\S+) ')            AS cliente,
       count(*)                                          AS intentos_fallidos,
       min(substring(linea FROM '^(\S+ \S+)'))           AS primero,
       max(substring(linea FROM '^(\S+ \S+)'))           AS ultimo
FROM dba.bitacora
WHERE linea LIKE '%FATAL:  password authentication failed%'
GROUP BY 1, 2
ORDER BY intentos_fallidos DESC;
       usuario       |  cliente  | intentos_fallidos |         primero         |         ultimo          
---------------------+-----------+-------------------+-------------------------+-------------------------
 app_ventas          | 127.0.0.1 |                 2 | 2026-11-06 14:30:54.332 | 2026-11-06 14:30:54.336
 usuario_inexistente | 127.0.0.1 |                 2 | 2026-11-06 14:30:54.366 | 2026-11-06 14:30:54.370
(2 rows)

```

## Interpretación y respuestas

> **Nota sobre intentos duplicados.** Si el servidor tiene SSL activo, `psql` (con `sslmode=prefer`) reintenta automáticamente sin SSL cuando falla la autenticación. Por eso cada intento fallido puede aparecer **dos veces**, con PID y puerto distintos. Son dos conexiones reales, pero corresponden a una sola orden del usuario. Si tu servidor no usa SSL, verás una sola.

### 11.1 Lectura de una línea campo por campo (intento fallido de `app_ventas`)

| Campo | Significado |
|---|---|
| Fecha y hora | Momento en que el servidor escribió la línea, con milisegundos y zona (`%m`) |
| PID | Proceso del servidor que atendió ese intento. Agrupa todas las líneas de la misma conexión (`%p`) |
| Usuario | Rol que el cliente *declaró* al conectarse (`%u`). En un intento fallido no está autenticado |
| Base de datos | Base solicitada (`%d`) |
| Aplicación | `application_name` (`%a`). Vale `[unknown]` porque la conexión no llegó a la etapa en que se aplica |
| Cliente | Dirección IP de origen de la conexión TCP (`%h`) |
| Severidad | `FATAL`: el error terminó el proceso y la conexión fue rechazada |
| Mensaje | La contraseña no coincidió con el verificador SCRAM almacenado para el rol |
| Regla aplicada | Línea de `pg_hba.conf` que eligió el método de autenticación (`scram-sha-256`) |

1. **¿El intento fallido prueba que la aplicación de ventas intentó entrar?** No. `user=app_ventas` es el nombre que declaró el cliente. La línea prueba que, a esa hora y desde esa IP, alguien intentó autenticarse como `app_ventas` con una contraseña incorrecta, y que se aplicó esa regla de `pg_hba.conf`. Pudo ser la aplicación con una contraseña desactualizada o un tercero.
2. **¿Qué información adicional se registra cuando el rol no existe?** La línea `DETAIL: Role "usuario_inexistente" does not exist.` El cliente recibe el mismo mensaje genérico que con una contraseña incorrecta, para no revelar qué roles existen; así se evita la enumeración de usuarios. El motivo real solo queda en la bitácora, que lee el administrador.
3. **¿Por qué `app=[unknown]` en el intento fallido y `app=app-ventas-web` en la desconexión?** `application_name` viaja en el paquete de inicio de la conexión, pero el servidor lo aplica como parámetro de la sesión *después* de autenticar y autorizar. Por eso incluso la línea `connection authorized` muestra `app=[unknown]`, aunque su mensaje ya contiene `application_name=app-ventas-web`. Los intentos fallidos nunca llegaron a esa etapa, y en esta actividad tampoco declararon `application_name` en la cadena de conexión.
4. **¿Qué patrón haría sospechar fuerza bruta?** Muchas líneas `FATAL: password authentication failed` desde la misma IP en poco tiempo, contra uno o varios roles (incluidos roles inexistentes). Cada intento tiene un PID distinto precedido de `connection received`. Es especialmente grave si la serie termina en un `connection authenticated`, porque indica que el ataque tuvo éxito. La consulta de la sección anterior agrupa los fallos por usuario y origen con su primer y último intento; un umbral razonable de alerta sería, por ejemplo, más de 5 fallos en 10 minutos.
