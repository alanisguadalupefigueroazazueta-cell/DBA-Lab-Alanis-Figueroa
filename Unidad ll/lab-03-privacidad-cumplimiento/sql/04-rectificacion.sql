-- Actividad 7 — Derecho de rectificación
-- Supongamos que un cliente informa:
-- "Mi correo electrónico registrado es incorrecto."
-- Actualiza únicamente el dato correspondiente:

UPDATE clientes
SET correo = 'nuevo-correo@example.com'
WHERE id = 1;

-- Verifica:

SELECT
    id,
    nombre,
    correo
FROM clientes
WHERE id = 1;
