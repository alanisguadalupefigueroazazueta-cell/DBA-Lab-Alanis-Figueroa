# Evidencia 10 — Diseño del registro de auditoría

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 10 |
| Fecha de ejecución | 2026-11-06 14:32:30 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión de administrador (entrada y salida de psql):*

```text
CREATE SCHEMA auditoria;
CREATE SCHEMA
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;
REVOKE
CREATE TABLE auditoria.cambios_clientes (
    id_evento        BIGSERIAL PRIMARY KEY,
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(),
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user,
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user,
    aplicacion       TEXT        DEFAULT current_setting('application_name'),
    ip_cliente       INET        DEFAULT inet_client_addr(),
    operacion        TEXT        NOT NULL,
    id_cliente       BIGINT,
    valores_antes    JSONB,
    valores_despues  JSONB
);
CREATE TABLE
SELECT nspname, nspowner::regrole AS propietario, nspacl
FROM pg_namespace WHERE nspname IN ('auditoria', 'dba');
  nspname  | propietario |         nspacl         
-----------+-------------+------------------------
 dba       | postgres    | {postgres=UC/postgres}
 auditoria | postgres    | {postgres=UC/postgres}
(2 rows)

```

## Interpretación y respuestas

### Diseño del registro de auditoría

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
|---|---|---|---|
| `id_evento` | BIGSERIAL | Identifica cada evento para citarlo y da su orden de inserción | No: es la llave primaria |
| `momento` | TIMESTAMPTZ | ¿Cuándo? | No: todo evento ocurre en un instante. Se llena con `now()` |
| `usuario_sesion` | TEXT | ¿Quién hizo el cambio? Es el rol que se autenticó | No: siempre hay una sesión autenticada |
| `usuario_efectivo` | TEXT | ¿Con qué privilegios se ejecutó? Distingue `SECURITY DEFINER` y `SET ROLE` | No: siempre hay un rol vigente |
| `aplicacion` | TEXT | ¿Desde qué aplicación? | Sí: el cliente puede no declararla (queda vacía) |
| `ip_cliente` | INET | ¿Desde qué equipo? | Sí: es `NULL` en conexiones por socket local |
| `operacion` | TEXT | ¿Qué se hizo? (`INSERT`, `UPDATE`, `DELETE`) | No: todo evento tiene una operación |
| `id_cliente` | BIGINT | ¿Sobre qué registro? | Sí: un evento a nivel de sentencia, como `TRUNCATE`, no tiene un registro concreto |
| `valores_antes` | JSONB | ¿Qué valor tenía antes? Sirve para revertir | Sí: es `NULL` en un `INSERT`, porque no había registro previo |
| `valores_despues` | JSONB | ¿Qué valor quedó? | Sí: es `NULL` en un `DELETE`, porque el registro ya no existe |

Las columnas `aplicacion` e `ip_cliente` responden a la pregunta de Dirección "¿desde qué aplicación o equipo?". La pregunta "¿hubo intentos de acceso fallidos?" no la responde esta tabla, sino la bitácora del servidor.

### Preguntas

1. **¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?** `TIMESTAMPTZ` guarda un instante absoluto, normalizado a UTC, y lo muestra en la zona de quien consulta. `TIMESTAMP` guarda una hora sin zona, que es ambigua si el servidor, la aplicación o el analista están en zonas distintas o si cambia la configuración. Para correlacionar con la bitácora del servidor, que también usa una zona declarada, hace falta un instante sin ambigüedad.
2. **¿Por qué se guarda el registro completo en JSONB y no solo la columna que cambió?** Por cuatro razones:
   - Conserva el contexto completo de cada evento.
   - Permite reconstruir el registro entero tras un `DELETE`.
   - Una misma función sirve para cualquier cambio, sin programar columna por columna.
   - La auditoría sigue funcionando aunque `clientes` cambie de estructura, como pasó al agregar `segmento`.

   Qué campos cambiaron se calcula después comparando `valores_antes` con `valores_despues`.
3. **La auditoría también contiene RFC. ¿Qué implica para su clasificación y control de acceso?** Que es al menos tan sensible como `clientes`, y probablemente más, porque guarda el historial completo de datos personales, incluidos valores que ya se corrigieron o se eliminaron. Necesita la misma clasificación o una superior, un esquema sin acceso para `PUBLIC` y lectura solo para el custodio de la auditoría. También necesita su propia política de retención y debe incluirse en los respaldos y en el cifrado del mismo modo que los datos originales.
