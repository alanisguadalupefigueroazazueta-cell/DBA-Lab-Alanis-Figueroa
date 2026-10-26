# Registro de cambios — LAB-04

Fecha: 2026-10-25 · Servidor: PostgreSQL 16.15 (Ubuntu 24.04), clúster `16/main` · Ejecutado como `root` / `dba_lab`
Respaldo previo: `/root/lab04-backup-20261025-204622/` (`postgresql.conf`, `pg_hba.conf`, `pg_ident.conf`, `postgresql.auto.conf`)

> El estado inicial se **sembró deliberadamente** para reproducir el escenario del enunciado
> (`listen_addresses='*'`, reglas `0.0.0.0/0` y `::/0`, aplicación con `SUPERUSER`, extensiones extra,
> archivos de configuración legibles por cualquier usuario). Esto no es el estado por defecto de Ubuntu.

| # | Cambio | Antes | Después | Riesgo mitigado | Cómo se aplicó | Verificación |
|---|---|---|---|---|---|---|
| 1 | Interfaces de escucha | `listen_addresses='*'` → `0.0.0.0:5432` | `'localhost'` → `127.0.0.1:5432` | Exposición de red | `03-configuracion.sql` + reinicio | `ss -lntp`; conexión a `192.0.2.2` → *Connection refused* |
| 2 | Reglas `pg_hba.conf` | `host all all 0.0.0.0/0` y `::/0` (`scram-sha-256`) | Allowlist `hostssl` por BD + usuario + origen; `reject` explícitos | Acceso desde cualquier origen, a cualquier BD, con cualquier usuario | edición de `pg_hba.conf` + `reload`/reinicio | `pg_hba_file_rules`; pruebas de rechazo |
| 3 | TLS obligatorio | Conexión sin TLS aceptada | `hostssl`; sin TLS → `pg_hba.conf rejects connection ... no encryption` | Intercepción / credenciales en claro | `pg_hba.conf` | Prueba `sslmode=disable` |
| 4 | Cuenta de aplicación | `app_web` (**SUPERUSER**), propietaria de BD y tablas | `app_comercial` (sin privilegios administrativos, `SELECT/INSERT/UPDATE`, límite 20) | Compromiso total del servidor vía SQL injection / credencial filtrada | `02-roles.sql` | `DELETE` y `CREATE ROLE` → *permission denied* |
| 5 | Cuenta de consulta | No existía | `consulta_norte` (solo `SELECT`, límite 5) | Uso de cuentas con más privilegios para leer | `02-roles.sql` | Tabla de roles |
| 6 | Cuenta heredada | `reporte_old` (`CREATEDB`, sin responsable) | Eliminada | Cuenta innecesaria | `02-roles.sql` | `pg_roles` |
| 7 | Propiedad de objetos | BD y tablas propiedad de `app_web` | Propiedad de `dba_lab` | La aplicación podía alterar/borrar estructura | `REASSIGN OWNED` | `\l`, `\dt` |
| 8 | Acceso por defecto | `PUBLIC` con `CONNECT` y uso del esquema `public` | `REVOKE ALL ... FROM PUBLIC` + `GRANT` explícitos | Acceso no intencionado | `02-roles.sql` | Verificación #12 |
| 9 | Extensiones | `dblink`, `file_fdw`, `pgcrypto`, `plpgsql` | `pgcrypto`, `plpgsql` | Funcionalidad innecesaria (conexiones salientes, lectura de archivos) | `DROP EXTENSION` | `pg_extension` |
| 10 | Logging | `log_connections=off`, `log_disconnections=off` | `on` / `on`, `log_line_prefix` con usuario/BD/host, `log_statement='ddl'` | Falta de trazabilidad | `03-configuracion.sql` | Líneas *connection authorized* en el log |
| 11 | Recursos | `max_connections=100`; `idle_in_transaction_session_timeout=0`; `idle_session_timeout=0` | `50`; `60s`; `30min`; `statement_timeout` por rol (30 s / 15 s) | Agotamiento de conexiones, bloqueos prolongados | `ALTER SYSTEM` / `ALTER ROLE` | `SHOW ...` |
| 12 | Permisos de SO | `/etc/postgresql/16/main` `0755`; `.conf` `0644` (legibles por todos) | directorio `0750`; `.conf` `0640` | Lectura de configuración por usuarios del SO | `chmod` | `labuser`: `Permission denied` |
| 13 | Directorio de datos | `0700` (ya correcto) | `0700` (reafirmado) | — | `chmod 700` | `ls -ld` |

## Elementos revisados sin cambio

| Elemento | Resultado |
|---|---|
| `ssl` | Ya estaba en `on` (certificado *snakeoil* del paquete Debian) → solo se hizo **obligatorio** en `pg_hba` |
| `ssl_min_protocol_version` | Ya `TLSv1.2`; se fijó explícitamente en la configuración |
| `password_encryption` / hashes | Ya `scram-sha-256` y sin hashes `md5` |
| Puerto 5432 | Se mantiene; cambiarlo no aporta seguridad real |
| Firewall | No modificado (política documentada en `baseline.md`, Anexo A) |

## Desviaciones y observaciones del enunciado

1. **Actividad 15:** la consulta `SELECT pid, usename, client_addr, ... FROM pg_stat_ssl` falla porque `pg_stat_ssl`
   no tiene `usename` ni `client_addr`. Se corrigió con `JOIN pg_stat_activity USING (pid)` (`01-inspeccion.sql`).
   La sección TLS del estado "antes" (imagen `05`) se obtuvo con esa consulta corregida **después** del
   hardening (los parámetros TLS no cambiaron); la diferencia real de TLS antes/después está en las pruebas de conexión.
2. **Actividad 7:** `SHOW password_encryption` solo indica el algoritmo para **nuevas** contraseñas; por eso se
   agregó la consulta a `pg_authid` para comprobar el formato de los hashes ya almacenados.
3. Las contraseñas de laboratorio **no** están en los scripts: se pasan como variables de psql
   (`-v app_pw=... -v ro_pw=...`).

## Reversión

```bash
# Restaurar configuración previa (el estado inseguro original) -- solo en el laboratorio
sudo cp -a /root/lab04-backup-20261025-204622/{postgresql.conf,pg_hba.conf,pg_ident.conf} /etc/postgresql/16/main/
sudo cp -a /root/lab04-backup-20261025-204622/postgresql.auto.conf /var/lib/postgresql/16/main/
sudo pg_ctlcluster 16 main restart
# Los cambios de roles/extensiones (02-roles.sql) son transaccionales pero ya confirmados:
# revertirlos requiere recrear las cuentas y extensiones manualmente.
```

## Reproducción

```bash
# 1) Respaldo
sudo mkdir -p /root/lab04-backup && sudo cp -a /etc/postgresql/16/main/{postgresql.conf,pg_hba.conf,pg_ident.conf} /root/lab04-backup/

# 2) Roles y privilegios, y 3) parámetros
psql "host=127.0.0.1 dbname=comercial_norte user=dba_lab sslmode=require" -v app_pw='<secreto>' -v ro_pw='<secreto>' -f sql/02-roles.sql
psql "host=127.0.0.1 dbname=comercial_norte user=dba_lab sslmode=require" -f sql/03-configuracion.sql

# 4) pg_hba.conf (contenido final abajo) y 5) permisos del SO
sudo chown -R postgres:postgres /etc/postgresql/16/main
sudo chmod 750 /etc/postgresql/16/main
sudo chmod 640 /etc/postgresql/16/main/{postgresql.conf,pg_hba.conf,pg_ident.conf}
sudo chmod 700 /var/lib/postgresql/16/main

# 6) Reinicio (listen_addresses y max_connections lo requieren) y verificación
sudo pg_ctlcluster 16 main restart
psql "host=127.0.0.1 dbname=comercial_norte user=dba_lab sslmode=require" -f sql/04-verificacion.sql
```

`pg_hba.conf` final:

```
# pg_hba.conf endurecido - LAB-04 (Comercializadora Norte S.A. de C.V.)
# Principio: allowlist. Todo lo que no coincide con una regla es DENEGADO.
# Las reglas se evaluan de arriba hacia abajo; gana la primera coincidencia.
#
# TYPE     DATABASE         USER             ADDRESS          METHOD

# --- Socket local: solo el superusuario del SO "postgres" (administracion) ---
local      all              postgres                          peer

# --- Aplicacion: BD y usuario especificos, origen explicito, TLS obligatorio ---
# En produccion: reemplazar 127.0.0.1/32 por el host/red de la aplicacion
# (ejemplo del laboratorio: 10.10.10.0/24).
hostssl    comercial_norte  app_comercial    127.0.0.1/32     scram-sha-256

# --- Consulta: solo lectura, mismo criterio ---
hostssl    comercial_norte  consulta_norte   127.0.0.1/32     scram-sha-256

# --- DBA: acceso administrativo solo desde la red de administracion ---
# En produccion: Red DBA 10.10.10.0/24 (ver baseline.md, Anexo A).
hostssl    all              dba_lab          127.0.0.1/32     scram-sha-256

# --- Denegaciones explicitas (documentan la intencion; el default ya niega) ---
local      all              all                               reject
host       all              all              0.0.0.0/0        reject
host       all              all              ::/0             reject
```
