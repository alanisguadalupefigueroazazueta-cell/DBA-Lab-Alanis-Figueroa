-- LAB-04 | 02-roles.sql
-- Hardening de roles (Actividades 8 y 9): separar DBA / APP / CONSULTA,

--Obtén los roles:
SELECT
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
ORDER BY rolname;

-- 1) Cuentas nuevas con privilegios minimos
CREATE ROLE app_comercial  LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT
       CONNECTION LIMIT 20 PASSWORD :'app_pw';
CREATE ROLE consulta_norte LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT
       CONNECTION LIMIT 5  PASSWORD :'ro_pw';



