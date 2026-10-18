
-- LAB-01 · Actividad 02 — Enmascaramiento (masking)

-- 1) Crear el rol de soporte (sin capacidad de login)
CREATE ROLE soporte_alanis NOLOGIN;

-- 2) Vista de acceso restringido con datos enmascarados
--    correo   : 2 primeras letras + ***** + dominio (desde la @)
--    telefono : ****** + últimos 4 dígitos
--    rfc      : ********* + últimos 4 caracteres
CREATE VIEW v_clientes_soporte AS
SELECT
    id,
    nombre,
    CONCAT(
        LEFT(correo, 2),
        '*****',
        SUBSTRING(correo FROM POSITION('@' IN correo))
    ) AS correo,
    CONCAT(
        '******',
        RIGHT(telefono, 4)
    ) AS telefono,
    CONCAT(
        '*********',
        RIGHT(rfc, 4)
    ) AS rfc
FROM clientes;

-- 3) Conceder acceso solo a la vista y retirar acceso a la tabla
GRANT USAGE
ON SCHEMA public
TO soporte_alanis;

GRANT SELECT
ON v_clientes_soporte
TO soporte_alanis;

REVOKE ALL
ON clientes
FROM soporte_alanis;

-- 4) Verificación
--    (a) Como propietario: la tabla original sigue completa
SELECT * FROM clientes;

--    (b) Como soporte: ver solo la vista enmascarada
SET ROLE soporte_alanis;
SELECT current_user;

SELECT * FROM v_clientes_soporte;   -- OK: devuelve 5 filas enmascaradas

--    (c) Como soporte: el acceso directo debe ser rechazado
SELECT * FROM clientes;             -- ERROR: permission denied for table clientes (SQLSTATE 42501)

RESET ROLE;