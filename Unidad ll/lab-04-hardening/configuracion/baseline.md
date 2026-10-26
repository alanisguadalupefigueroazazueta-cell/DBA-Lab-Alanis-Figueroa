# Línea base de seguridad — PostgreSQL 16 (Comercializadora Norte S.A. de C.V.)

Versión del baseline: 1.0 · Fecha: 2026-10-25 · Alcance: instancia de laboratorio `16/main`
(los valores marcados *(prod)* son los que se aplicarían en un entorno real).

## 1. Red

| Control | Valor del baseline | Estado en el laboratorio |
|---|---|---|
| Interfaces de escucha | Solo la(s) interfaz(ces) necesarias; **nunca** `*` por defecto | `listen_addresses = 'localhost'` |
| Puerto | `5432/TCP` documentado (cambiarlo **no** es control de seguridad) | 5432, escuchando en `127.0.0.1:5432` |
| Firewall | Política por defecto *deny*; solo Red DBA y hosts de aplicación | Diseñado en el Anexo A (no aplicado) |
| Redes permitidas | `10.10.10.0/24` (DBA) *(prod)* + host(s) de aplicación documentados | `127.0.0.1/32` |
| Segmentación | BD en red privada, sin ruta desde Internet | N/A (host único) |
| Verificación | `ss -lntp \| grep 5432` y prueba de conexión desde un origen no autorizado | Evidencia `02-listen-addresses.png` |

## 2. Autenticación

| Control | Valor del baseline |
|---|---|
| Método | `scram-sha-256` (no `md5`, **nunca** `trust`) |
| `password_encryption` | `scram-sha-256` |
| Política de credenciales | Contraseñas únicas por cuenta, ≥ 16 caracteres, almacenadas en gestor de secretos; rotación al menos cada 90 días o ante sospecha de compromiso; **no** se guardan en repositorios ni scripts |
| Cuentas administrativas | Solo `postgres` (socket local, `peer`) y `dba_lab` (personal, desde Red DBA, con TLS). Sin uso por aplicaciones |
| Conexiones locales | `peer` solo para `postgres`; el resto rechazado |
| Cifrado en tránsito | `hostssl` en todas las reglas de acceso remoto |

## 3. Autorización

| Rol | LOGIN | Privilegios | Límite de conexiones |
|---|---|---|---|
| `dba_lab` (DBA) | Sí | SUPERUSER / CREATEROLE / CREATEDB (administración) | sin límite |
| `app_comercial` (aplicación) | Sí | `CONNECT` en `comercial_norte`; `SELECT, INSERT, UPDATE` en `clientes`, `pedidos`; sin `DELETE`, sin DDL | 20 |
| `consulta_norte` (consulta) | Sí | `CONNECT`; `SELECT` en `clientes`, `pedidos` | 5 |

Reglas: ninguna aplicación usa `SUPERUSER`; `PUBLIC` sin `CONNECT` en la BD ni `CREATE`/`USAGE`
implícito en el esquema `public`; el propietario de los objetos es el DBA, no la cuenta de la aplicación.

## 4. Configuración (`postgresql.conf` / `postgresql.auto.conf`)

| Parámetro | Valor | Propósito |
|---|---|---|
| `listen_addresses` | `'localhost'` | Reducir exposición de red |
| `ssl` | `on` | Cifrado en tránsito |
| `ssl_min_protocol_version` | `TLSv1.2` | Descartar TLS/SSL obsoletos |
| `password_encryption` | `scram-sha-256` | Hash de contraseñas robusto |
| `max_connections` | `50` | Acotar consumo de recursos |
| `superuser_reserved_connections` | `3` | Garantizar acceso del DBA bajo saturación |
| `idle_in_transaction_session_timeout` | `60s` | Evitar transacciones abiertas que retienen locks |
| `idle_session_timeout` | `30min` | Liberar conexiones inactivas |
| `statement_timeout` | `0` global; `30s` (app) y `15s` (consulta) **por rol** | Evitar consultas eternas sin afectar tareas administrativas |
| `log_connections` / `log_disconnections` | `on` / `on` | Trazabilidad de accesos |
| `log_line_prefix` | `'%m [%p] %q%u@%d (%h) '` | Contexto en cada línea de log |
| `log_statement` | `ddl` | Auditoría mínima de cambios de estructura |

**Extensiones permitidas:** `plpgsql` (base), `pgcrypto` (requerida para funciones criptográficas del LAB-02).
**Retiradas:** `dblink`, `file_fdw` (acceso saliente / a archivos del servidor desde SQL; no necesarias).
Toda extensión nueva requiere justificación escrita y revisión.

## 5. Sistema operativo

| Objeto | Propietario:grupo | Permisos | Observación |
|---|---|---|---|
| `/var/lib/postgresql/16/main` (datos) | `postgres:postgres` | `0700` | Solo la cuenta de servicio |
| `/etc/postgresql/16/main` (directorio) | `postgres:postgres` | `0750` | |
| `postgresql.conf`, `pg_hba.conf`, `pg_ident.conf` | `postgres:postgres` | `0640` | Sin lectura para "otros" |
| `postgresql.auto.conf` | `postgres:postgres` | `0600` | Gestionado por `ALTER SYSTEM` |
| Clave privada TLS | `root:ssl-cert` | `0640` | Certificado de laboratorio *snakeoil*; en producción usar certificado de CA |
| Cuenta de servicio | `postgres` | sin shell interactivo para uso diario | Acceso administrativo vía `sudo` auditado |

## 6. Cifrado

| Control | Valor |
|---|---|
| TLS | Obligatorio para acceso remoto (`hostssl`); verificado TLSv1.3 / `TLS_AES_256_GCM_SHA384` |
| Certificados | *(prod)* Certificado emitido por la CA institucional y `sslmode=verify-full` en clientes |
| Credenciales | Gestor de secretos / variables de entorno; nunca en código ni en el repositorio |
| Datos sensibles | Cifrado por columna con `pgcrypto` y controles de privacidad definidos en LAB-01..03 |

## 7. Mantenimiento

| Actividad | Frecuencia | Responsable |
|---|---|---|
| Aplicar parches menores de PostgreSQL 16 | Mensual (urgente si hay CVE crítico) | DBA |
| Revisar `pg_hba.conf` y redes permitidas | Trimestral | DBA + Seguridad |
| Revisar roles, privilegios y cuentas sin uso | Trimestral | DBA |
| Revisar extensiones | Semestral | DBA |
| Verificar permisos de archivos y directorio de datos | Trimestral | DBA / SysAdmin |
| Revisar logs de conexión y autenticaciones fallidas | Semanal | DBA / SOC |
| Revisar vigencia de certificados TLS | Mensual | DBA |
| Re-ejecutar `sql/04-verificacion.sql` y actualizar este baseline | Con cada cambio y al menos semestral | DBA |

**Política de actualización:** parches menores dentro de la versión mayor soportada; plan de migración
antes del fin de soporte de la versión mayor; todo cambio probado primero en un entorno no productivo y
registrado en [`cambios.md`](cambios.md).

---

## Anexo A — Política de firewall (Actividad 14)

> **Diseño conceptual.** No se modificó ningún firewall institucional. En el entorno de laboratorio
> (un solo host, contenedor sin `ufw`/`nftables` activos) esta política **no se aplicó**; se documenta
> para que pueda implementarse y auditarse en un entorno real.

### Supuestos

| Elemento | Valor |
|---|---|
| Servidor PostgreSQL | `10.10.10.20` |
| Puerto | `5432/TCP` |
| Red DBA autorizada | `10.10.10.0/24` |

### Reglas (política por defecto: **denegar**)

| # | Origen | Destino | Puerto | Acción | Nota |
|---|---|---|---|---|---|
| 1 | `10.10.10.0/24` (Red DBA) | PostgreSQL `10.10.10.20` | 5432/TCP | **Permitir** | Solo administración |
| 2 | *(Host/segmento de la aplicación, p. ej. `10.10.20.15/32`)* | PostgreSQL `10.10.10.20` | 5432/TCP | **Permitir** | Solo si la aplicación está en otro host; documentar y justificar |
| 3 | Cualquier otro origen | PostgreSQL | 5432/TCP | **Denegar** (y registrar) | Allowlist |

### Ejemplo de implementación (referencia, no aplicado)

```bash
# nftables (ejemplo)
nft add rule inet filter input ip saddr 10.10.10.0/24 ip daddr 10.10.10.20 tcp dport 5432 accept
nft add rule inet filter input tcp dport 5432 log prefix "pg-deny " drop

# ufw (ejemplo equivalente)
ufw default deny incoming
ufw allow from 10.10.10.0/24 to 10.10.10.20 port 5432 proto tcp
```

### ¿Por qué `pg_hba.conf` y el firewall NO son controles equivalentes?

| | Firewall | `pg_hba.conf` |
|---|---|---|
| Capa | Red / transporte (L3-L4) | Aplicación (PostgreSQL) |
| Cuándo actúa | **Antes** de que el paquete llegue a PostgreSQL | **Después** de aceptar el socket TCP |
| Qué ve | IP origen/destino, puerto, protocolo | Base de datos, **usuario**, origen, TLS, método de autenticación |
| Si falla el otro | Si `pg_hba` es laxo, el firewall aún corta el tráfico | Si el firewall es laxo, `pg_hba` aún rechaza al cliente no autorizado |

Son **capas complementarias** (defensa en profundidad): el firewall reduce quién puede *llegar*;
`pg_hba.conf` decide quién puede *autenticarse* y *cómo*. Ninguno sustituye a los privilegios (`GRANT`).
