# Evidencia 13 — Intentos de manipular la auditoría

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 14 |
| Fecha de ejecución | 2026-11-06 14:32:31 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## Desde la cuenta de la aplicación

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "DELETE FROM auditoria.cambios_clientes" -c "ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes"
```

```text
ERROR:  permission denied for schema auditoria
LINE 1: DELETE FROM auditoria.cambios_clientes
                    ^
ERROR:  must be owner of table clientes
```

## Desde la cuenta de administrador

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT count(*) AS eventos_antes FROM auditoria.cambios_clientes;
 eventos_antes 
---------------
             3
(1 row)

ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
ALTER TABLE
UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
UPDATE 1
ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
ALTER TABLE
SELECT count(*) AS eventos_despues FROM auditoria.cambios_clientes;
 eventos_despues 
-----------------
               3
(1 row)

```

## Lo que registró la bitácora

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora
WHERE linea ~ 'statement: (ALTER TABLE clientes (DIS|EN)ABLE|UPDATE clientes SET rfc = .GAMA780912GHI)'
ORDER BY num;
                                                                                      linea                                                                                      
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:32:31.254 UTC [630] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes
 2026-11-06 14:32:31.281 UTC [637] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
 2026-11-06 14:32:31.281 UTC [637] user=postgres db=comercial app=psql client=[local] LOG:  statement: UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
 2026-11-06 14:32:31.281 UTC [637] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
(4 rows)

```

## Conciliación: valor actual frente al último valor auditado

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT c.id, c.rfc AS rfc_actual, u.valores_despues ->> 'rfc' AS rfc_ultimo_auditado, u.id_evento
FROM clientes c
CROSS JOIN LATERAL (
    SELECT a.id_evento, a.valores_despues FROM auditoria.cambios_clientes a
    WHERE a.id_cliente = c.id AND a.operacion IN ('INSERT', 'UPDATE')
    ORDER BY a.id_evento DESC LIMIT 1) u
WHERE c.rfc IS DISTINCT FROM u.valores_despues ->> 'rfc';
 id |  rfc_actual   | rfc_ultimo_auditado | id_evento 
----+---------------+---------------------+-----------
  3 | GAMA780912GHI | GAMA780912ZZZ       |         1
(1 row)

```

## Interpretación y respuestas

`app_ventas` no pudo borrar la auditoría (`permission denied for schema auditoria`) ni desactivar el disparador (`must be owner of table clientes`). En cambio, el administrador lo desactivó, cambió el RFC y lo reactivó, y el conteo de la auditoría no cambió. La bitácora registró ambas cosas:
- El intento de `app_ventas`: con `ddl` o `mod`, la sentencia se registra antes de ejecutarse, aunque después falle.
- La secuencia completa del administrador: `DISABLE TRIGGER`, `UPDATE` y `ENABLE TRIGGER`.

1. **¿Qué evidencia permite detectar que hubo un cambio sin auditar?** Hay dos fuentes:
   - *Bitácora del servidor:* las líneas `ALTER TABLE clientes DISABLE TRIGGER` y `ENABLE TRIGGER` de `postgres`, con el `UPDATE` entre ellas.
   - *Conciliación:* la consulta de la última sección compara el valor actual de cada registro con el último valor auditado. El RFC actual (`GAMA780912GHI`) no coincide con el último `valores_despues` (`GAMA780912ZZZ`), así que hubo un cambio que la auditoría no vio.
2. **¿Qué control administrativo, no técnico, reduciría este riesgo?** Varios:
   - Gestión de cambios: toda desactivación de un disparador de auditoría requiere una solicitud aprobada y documentada.
   - Doble control para operaciones privilegiadas.
   - Revisión periódica de la bitácora por un área independiente del DBA.
   - Cuentas de administrador nominativas en lugar del `postgres` compartido.
   - Envío de las bitácoras a un sistema externo custodiado por otra área.
   - Conciliaciones periódicas como la anterior.
3. **Relación con la separación de funciones de la Unidad II.** La misma persona no debería operar la base y custodiar la evidencia de esa operación. `app_ventas` no puede tocar la auditoría gracias a sus privilegios. El propietario de la tabla y el superusuario sí pueden, así que el control debe trasladarse fuera de su alcance: otra área revisa y conserva la evidencia, y el DBA no puede borrarla ni alterarla sin que se note.
