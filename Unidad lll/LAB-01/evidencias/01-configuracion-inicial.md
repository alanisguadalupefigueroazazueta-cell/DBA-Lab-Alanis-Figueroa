# Evidencia 01 — Configuración inicial de registro

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Secciones 6.3 y 6.4, Actividad 1 |
| Fecha de ejecución | 2026-11-06 14:30:47 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## 6.3 Identificación de la instalación desde el motor

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT version();
                                                                 version                                                                  
------------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
(1 row)

SHOW data_directory;
       data_directory        
-----------------------------
 /var/lib/postgresql/16/main
(1 row)

SHOW config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

SHOW hba_file;
              hba_file               
-------------------------------------
 /etc/postgresql/16/main/pg_hba.conf
(1 row)

```

## 6.4 Reglas de autenticación vigentes

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT line_number, type, database, user_name, address, auth_method
FROM pg_hba_file_rules
WHERE database = '{all}';
 line_number | type  | database | user_name  |  address  |  auth_method  
-------------+-------+----------+------------+-----------+---------------
         118 | local | {all}    | {postgres} |           | peer
         123 | local | {all}    | {all}      |           | peer
         125 | host  | {all}    | {all}      | 127.0.0.1 | scram-sha-256
         127 | host  | {all}    | {all}      | ::1       | scram-sha-256
(4 rows)

```

Ninguna regla `host` usaba `trust`, así que no fue necesario modificar `pg_hba.conf`.

## Actividad 1 — Configuración de registro por defecto

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT name, setting, source
FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
               'log_connections', 'log_disconnections', 'log_line_prefix',
               'log_statement', 'log_min_error_statement', 'log_timezone')
ORDER BY name;
          name           |            setting             |       source       
-------------------------+--------------------------------+--------------------
 log_connections         | off                            | default
 log_destination         | stderr                         | default
 log_directory           | log                            | default
 log_disconnections      | off                            | default
 log_filename            | postgresql-%Y-%m-%d_%H%M%S.log | default
 log_line_prefix         | %m [%p] %q%u@%d                | configuration file
 log_min_error_statement | error                          | default
 log_statement           | none                           | default
 log_timezone            | Etc/UTC                        | configuration file
 logging_collector       | off                            | default
(10 rows)

```

## Interpretación y respuestas

### Sección 6.4 — ¿Por qué una regla `trust` afecta lo que la bitácora puede demostrar sobre la identidad?

Con `trust`, PostgreSQL acepta sin verificación el nombre de rol que declara el cliente. La bitácora escribiría `user=app_ventas`, pero cualquiera que abriera una conexión TCP desde el propio equipo podría haber declarado ese nombre. La línea solo diría quién *dijo ser*, no quién *se autenticó*. Además, ningún intento puede fallar por contraseña, así que nunca habría evidencia de accesos fallidos.

El endurecimiento de la Unidad II es lo que da valor probatorio al campo de usuario. Ese endurecimiento consistió en sustituir `trust` por `scram-sha-256` y en limitar cada regla por base, rol y red. La regla `local … trust` que se conserva para la sesión de administrador tiene el mismo problema: cualquier cuenta del sistema operativo con acceso al socket puede entrar como `postgres`. En ese caso la atribución depende del control de cuentas del sistema operativo; `peer` sería preferible.

### Actividad 1

1. **¿Se registra quién se conecta?** No, porque `log_connections = off`. Solo un rechazo de autenticación llegaría a la bitácora, como mensaje `FATAL`. Las conexiones exitosas no quedan.
2. **¿Se registran las sentencias `UPDATE`?** No, porque `log_statement = none`. Un `UPDATE` solo aparecería si fallara, gracias a `log_min_error_statement = error`.
3. **¿La línea incluye el usuario o la IP del cliente?** Con el valor por defecto de PostgreSQL (`%m [%p]`), no: solo aporta fecha, hora y PID, y faltan `%u`, `%d`, `%a` y `%h`. Algunas distribuciones cambian el prefijo en su `postgresql.conf`; los paquetes de Debian y Ubuntu, por ejemplo, usan `%m [%p] %q%u@%d` (con `source = configuration file`). En ese caso aparecen el usuario y la base, pero siguen faltando la aplicación y la IP del cliente.
4. **¿En qué zona horaria?** En la que indica `log_timezone` en la salida anterior. Importa porque una cronología combina fuentes que pueden estar en zonas distintas: la bitácora del servidor, la de la aplicación y el reporte de facturación en hora local. Culiacán usa UTC−7 todo el año (`America/Mazatlan`), así que una hora en UTC aparece 7 horas adelantada. Sin declarar la zona, los eventos pueden ordenarse mal o atribuirse a un turno equivocado.
5. **¿Quién decide dónde termina la bitácora con el colector apagado?** El mecanismo de despliegue. PostgreSQL solo escribe en *stderr*. Hacia dónde va esa salida y cuánto tiempo se conserva lo decide quien lanzó el proceso: el script de arranque, el journal, Homebrew o el motor de contenedores. Si el contenedor se recrea, por ejemplo, esa salida se pierde.
