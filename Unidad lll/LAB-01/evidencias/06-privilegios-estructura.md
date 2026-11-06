# Evidencia 06 — Cambios de privilegios y de estructura

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 6 |
| Fecha de ejecución | 2026-11-06 14:30:55 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión de administrador (entrada y salida de psql):*

```text
REVOKE UPDATE ON clientes FROM soporte_ana;
REVOKE
GRANT UPDATE ON clientes TO app_ventas;
GRANT
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
ALTER TABLE
```

## 12.1 La bitácora también puede filtrar secretos

*Sesión de administrador (entrada y salida de psql):*

```text
CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
CREATE ROLE
DROP ROLE rol_temporal;
DROP ROLE
```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;
                                                                                  linea                                                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:55.485 UTC [426] user=postgres db=comercial app=psql client=[local] LOG:  statement: REVOKE UPDATE ON clientes FROM soporte_ana;
 2026-11-06 14:30:55.486 UTC [426] user=postgres db=comercial app=psql client=[local] LOG:  statement: GRANT UPDATE ON clientes TO app_ventas;
 2026-11-06 14:30:55.486 UTC [426] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
 2026-11-06 14:30:55.512 UTC [433] user=postgres db=comercial app=psql client=[local] LOG:  statement: CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
 2026-11-06 14:30:55.515 UTC [433] user=postgres db=comercial app=psql client=[local] LOG:  statement: DROP ROLE rol_temporal;
(5 rows)

```

**Comprobación:** en el archivo de bitácora original, **1 línea(s)** contienen la contraseña de `rol_temporal` en texto claro. En esta evidencia se sustituyó por `<REDACTED>`; en el servidor sigue visible aunque el rol ya se eliminó.

## Interpretación y respuestas

1. **¿Qué tipo de evento es cada una de las tres primeras sentencias?** `REVOKE UPDATE … FROM soporte_ana` es de privilegio, `GRANT UPDATE … TO app_ventas` también es de privilegio y `ALTER TABLE … ADD COLUMN segmento` es de estructura. `CREATE ROLE` y `DROP ROLE` también son eventos de privilegio, porque cambian quién puede autenticarse.
2. **¿Por qué `GRANT` y `REVOKE` quedan registrados con `log_statement = 'ddl'`?** PostgreSQL clasifica cada sentencia en una categoría. La categoría `ddl` abarca todo lo que define o controla objetos, no solo `CREATE`, `ALTER` y `DROP`: también incluye `GRANT`, `REVOKE`, `COMMENT`, las sentencias de roles y `ALTER SYSTEM`. Para la auditoría tiene sentido, porque un cambio de privilegios modifica la superficie de acceso tanto como un cambio de estructura.
3. **Si la bitácora contiene contraseñas, ¿quién debería poder leerla?** Solo el DBA y el área de seguridad o auditoría, con acceso controlado y registrado. La bitácora debe clasificarse como información confidencial. Esto se relaciona con la gestión de secretos de la Unidad II en cuatro puntos:
   - Las contraseñas no se escriben en sentencias SQL. Se usa `\password`, que calcula el verificador SCRAM en el cliente y envía solo ese resumen, o un gestor de secretos.
   - Una contraseña expuesta en una bitácora se considera comprometida y debe rotarse. Eliminar el rol no borra la línea.
   - La bitácora debe sanearse antes de compartirla, como se hace en la Actividad 16.
   - Con `log_statement` activo, incluso `\password` deja en la bitácora el verificador SCRAM. No es la contraseña, pero sí material sensible.
