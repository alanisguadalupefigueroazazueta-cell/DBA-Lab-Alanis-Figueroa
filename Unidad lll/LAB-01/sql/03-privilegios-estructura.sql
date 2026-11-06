-- LAB-01 · Actividad 6 — Cambios de privilegios y de estructura (log_statement = 'ddl')
-- Sesión de administrador.

REVOKE UPDATE ON clientes FROM soporte_ana;          -- privilegio (revocación preventiva)
GRANT UPDATE ON clientes TO app_ventas;              -- privilegio
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20); -- estructura

-- 12.1 La bitácora también puede filtrar secretos.
-- La contraseña se pide con \prompt para no dejarla escrita en este archivo;
-- aun así, el servidor la recibe dentro de la sentencia y la escribe en la bitácora.
\prompt 'Contraseña para rol_temporal: ' pass_temporal
CREATE ROLE rol_temporal LOGIN PASSWORD :'pass_temporal';
DROP ROLE rol_temporal;

SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;

-- Forma segura: \password <rol> calcula el verificador SCRAM en el cliente
-- y envía solo ese resumen.
