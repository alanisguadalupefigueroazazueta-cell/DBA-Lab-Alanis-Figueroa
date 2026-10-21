-- Actividad 3 — Separación por finalidad
-- Ahora el área de analítica solicita información para obtener estadísticas.
-- Diseña una consulta que proporcione información agregada:

SELECT
    ciudad,
    COUNT(*) AS cantidad_clientes
FROM clientes
GROUP BY ciudad
ORDER BY cantidad_clientes DESC;

-- Ahora crea rangos de edad:

SELECT
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad,
    COUNT(*) AS cantidad
FROM clientes
GROUP BY
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END
ORDER BY rango_edad;
-- Actividad 4 — Control de acceso relacionado con la finalidad
-- Crea un rol:

CREATE ROLE analista_alanis_figueroa NOLOGIN;

-- Otorga únicamente acceso a la información preparada para analítica.
-- Por ejemplo, crea una vista:

CREATE VIEW v_analitica_clientes AS
SELECT
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad
FROM clientes;

-- Otorga permisos:

GRANT USAGE ON SCHEMA public
TO analista_alanis_figueroa;

GRANT SELECT ON v_analitica_clientes
TO analista_alanis_figueroa;

-- Verificación
-- Comprueba los privilegios:

SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analista_alanis_figueroa';