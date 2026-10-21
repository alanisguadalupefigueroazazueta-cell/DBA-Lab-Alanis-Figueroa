-- LAB-02 | Actividad 2: Cifrado de información sensible
-- La clave NO se escribe en el script: se pide por psql y se usa como variable.
-- Ejecutar en psql (las variables \set no funcionan en el Query Tool de pgAdmin):
--   \prompt 'Clave de prueba: ' clave
-- Para el laboratorio se usó una clave ficticia; nunca subir claves reales.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS clientes_protegidos (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(120) NOT NULL,
    rfc_cifrado BYTEA        NOT NULL
);

-- RFC ficticio cifrado con clave simétrica
INSERT INTO clientes_protegidos (nombre, rfc_cifrado)
VALUES ('Luis Ortega', pgp_sym_encrypt('LOPA900101ABC', :'clave'));

-- Consulta: el RFC aparece como [binary data]
SELECT id, rfc_cifrado, nombre FROM clientes_protegidos;

-- Recuperar el dato con la clave correcta
SELECT id, nombre,
       pgp_sym_decrypt(rfc_cifrado, :'clave') AS rfc_descifrado
FROM clientes_protegidos;
