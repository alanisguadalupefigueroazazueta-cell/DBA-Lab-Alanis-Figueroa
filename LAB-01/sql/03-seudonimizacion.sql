--crear los esquemas 
CREATE SCHEMA pii;

CREATE SCHEMA analitica;

-- crear una tabal correspondiente 
CREATE TABLE pii.mapa_cliente (
    token UUID PRIMARY KEY,
    cliente_id BIGINT UNIQUE
        REFERENCES public.clientes(id)
);


-- verificar que se creo la tabla
SELECT *
FROM pii.mapa_cliente;


--Generar los tokens
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- token para cada cliente 
INSERT INTO pii.mapa_cliente
(token, cliente_id)
SELECT
    gen_random_uuid(),
    id
FROM public.clientes;

--verificar 
SELECT *
FROM pii.mapa_cliente;

--10. Crear el conjunto de datos para analítica
CREATE TABLE analitica.clientes AS
SELECT
    m.token AS cliente_token,
    c.edad,
    c.ciudad,
    c.codigo_postal,
    c.fecha_alta
FROM pii.mapa_cliente m
JOIN clientes c
    ON c.id = m.cliente_id;
--verificar 
SELECT * FROM analitica.clientes;

--Crear tu rol
CREATE ROLE analista_alanis_figueroa NOLOGIN;

--1. Darle los permisos necesarios
GRANT USAGE
ON SCHEMA analitica
TO analista_alanis_figueroa;

GRANT SELECT
ON analitica.clientes
TO analista_alanis_figueroa;

--2. Comprobar los permisos
SELECT
    has_schema_privilege('analista_alanis_figueroa', 'analitica', 'USAGE') AS acceso_esquema,
    has_table_privilege('analista_alanis_figueroa', 'analitica.clientes', 'SELECT') AS acceso_analitica,
    has_table_privilege('analista_alanis_figueroa', 'pii.mapa_cliente', 'SELECT') AS acceso_mapa,
    has_table_privilege('analista_alanis_figueroa', 'public.clientes', 'SELECT') AS acceso_clientes;


--Cambiar al rol de analista
SET ROLE analista_alanis_figueroa;
SELECT current_user;
GRANT analista_alanis_figueroa TO u_19409168_alanis_figueroa;


-- pro
SELECT *
FROM analitica.clientes;