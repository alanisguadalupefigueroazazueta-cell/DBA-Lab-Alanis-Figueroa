-- LAB-01 · Actividad 10 — Esquema y tabla de auditoría
-- Sesión de administrador.

CREATE SCHEMA auditoria;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;

CREATE TABLE auditoria.cambios_clientes (
    id_evento        BIGSERIAL PRIMARY KEY,                               -- identifica y ordena cada evento
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(),                  -- ¿cuándo?
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user,           -- ¿quién? (rol autenticado)
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user,           -- ¿con qué privilegios?
    aplicacion       TEXT        DEFAULT current_setting('application_name'), -- ¿desde qué aplicación?
    ip_cliente       INET        DEFAULT inet_client_addr(),              -- ¿desde qué equipo? (NULL por socket)
    operacion        TEXT        NOT NULL,                                -- ¿qué se hizo?
    id_cliente       BIGINT,                                              -- ¿sobre qué registro?
    valores_antes    JSONB,                                               -- ¿qué valor tenía antes? (NULL en INSERT)
    valores_despues  JSONB                                                -- ¿qué valor quedó? (NULL en DELETE)
);

SELECT nspname, nspowner::regrole AS propietario, nspacl
FROM pg_namespace WHERE nspname IN ('auditoria', 'dba');
