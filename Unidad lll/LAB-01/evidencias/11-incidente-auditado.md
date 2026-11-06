# Evidencia 11 — Función, disparador e incidente auditado

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividades 11 y 12 |
| Fecha de ejecución | 2026-11-06 14:32:31 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

## Actividad 11 — Función y disparador

*Sesión de administrador (entrada y salida de psql):*

```text
CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria.cambios_clientes (operacion, id_cliente, valores_despues)
        VALUES (TG_OP, NEW.id, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria.cambios_clientes (operacion, id_cliente, valores_antes, valores_despues)
        VALUES (TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria.cambios_clientes (operacion, id_cliente, valores_antes)
        VALUES (TG_OP, OLD.id, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;
CREATE FUNCTION
REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC;
REVOKE
CREATE TRIGGER trg_auditoria_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION auditoria.registrar_cambio_cliente();
CREATE TRIGGER
SELECT tgname, tgenabled, tgrelid::regclass FROM pg_trigger WHERE NOT tgisinternal;
         tgname         | tgenabled | tgrelid  
------------------------+-----------+----------
 trg_auditoria_clientes | O         | clientes
(1 row)

```

## ¿Quedó registrada la creación de los objetos?

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora
WHERE linea ~ 'statement: (CREATE|REVOKE)' AND linea ~ '(auditoria|trg_auditoria)'
ORDER BY num;
                                                                                     linea                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:32:30.993 UTC [568] user=postgres db=comercial app=psql client=[local] LOG:  statement: CREATE SCHEMA auditoria;
 2026-11-06 14:32:30.994 UTC [568] user=postgres db=comercial app=psql client=[local] LOG:  statement: REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;
 2026-11-06 14:32:30.994 UTC [568] user=postgres db=comercial app=psql client=[local] LOG:  statement: CREATE TABLE auditoria.cambios_clientes (
 2026-11-06 14:32:31.038 UTC [578] user=postgres db=comercial app=psql client=[local] LOG:  statement: CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()
 2026-11-06 14:32:31.040 UTC [578] user=postgres db=comercial app=psql client=[local] LOG:  statement: REVOKE ALL ON FUNCTION auditoria.registrar_cambio_cliente() FROM PUBLIC;
 2026-11-06 14:32:31.040 UTC [578] user=postgres db=comercial app=psql client=[local] LOG:  statement: CREATE TRIGGER trg_auditoria_clientes
(6 rows)

```

## Actividad 12 — La aplicación cambia el RFC e intenta revisar la auditoría

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"
```

```text
UPDATE 1
```

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial" -c "SELECT * FROM auditoria.cambios_clientes"
```

```text
ERROR:  permission denied for schema auditoria
LINE 1: SELECT * FROM auditoria.cambios_clientes
                      ^
```

## Registro de auditoría

*Sesión de administrador (entrada y salida de psql):*

```text
\x
Expanded display is on.
SELECT id_evento, momento, usuario_sesion, usuario_efectivo, aplicacion, ip_cliente, operacion, id_cliente
FROM auditoria.cambios_clientes ORDER BY id_evento;
-[ RECORD 1 ]----+------------------------------
id_evento        | 1
momento          | 2026-11-06 14:32:31.101863+00
usuario_sesion   | app_ventas
usuario_efectivo | postgres
aplicacion       | app-ventas-web
ip_cliente       | 127.0.0.1
operacion        | UPDATE
id_cliente       | 3

\x
Expanded display is off.
```

## Campo modificado: valor anterior y nuevo

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
       d.key                     AS campo,
       a.valores_antes ->> d.key AS antes,
       d.value #>> '{}'          AS despues
FROM auditoria.cambios_clientes a
CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE'
  AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;
 id_evento |            momento            | usuario_sesion | ip_cliente | campo |     antes     |    despues    
-----------+-------------------------------+----------------+------------+-------+---------------+---------------
         1 | 2026-11-06 14:32:31.101863+00 | app_ventas     | 127.0.0.1  | rfc   | GAMA780912XYZ | GAMA780912ZZZ
(1 row)

```

## Interpretación y respuestas

### Actividad 11

1. **¿Por qué `REVOKE ALL ON FUNCTION … FROM PUBLIC` si el disparador sigue funcionando para `app_ventas`?** Al ejecutar un disparador, PostgreSQL no verifica el privilegio `EXECUTE` del usuario que provocó el cambio. Ese privilegio solo se verifica al *crear* el disparador. Toda función nueva tiene `EXECUTE` para `PUBLIC` por defecto. Si no se revoca, cualquier rol que pueda crear una tabla podría asociarle esta función `SECURITY DEFINER` y escribir filas falsas en `auditoria.cambios_clientes` con privilegios de `postgres`. Revocarla aplica el mínimo privilegio y protege la integridad de la auditoría.
2. **Hipótesis: ¿qué pasaría si la función no fuera `SECURITY DEFINER`?** Se ejecutaría con los privilegios de `app_ventas`, que no tiene `USAGE` sobre el esquema `auditoria` ni `INSERT` sobre la tabla. El `INSERT` de auditoría fallaría con `permission denied for schema auditoria`. Como el disparador `AFTER` se ejecuta en la misma transacción, también se revertiría el `UPDATE` de `clientes`, y la aplicación dejaría de poder actualizar. La alternativa, otorgar `INSERT` sobre la auditoría a `app_ventas`, le permitiría fabricar o insertar eventos.
3. **¿Quedó registrada en `dba.bitacora` la creación del esquema, la tabla, la función y el disparador? ¿Por qué?** Sí. Con `log_statement = mod`, que incluye todo lo de `ddl`, se registraron `CREATE SCHEMA`, `REVOKE ALL ON SCHEMA`, `CREATE TABLE`, `CREATE OR REPLACE FUNCTION` (con su cuerpo completo en las líneas siguientes), `REVOKE ALL ON FUNCTION` y `CREATE TRIGGER`. La sección "¿Quedó registrada la creación de los objetos?" lo muestra.

### Actividad 12

`app_ventas` recibió `permission denied for schema auditoria`: puede *provocar* un registro de auditoría, pero no leerlo ni alterarlo. El registro muestra `usuario_sesion = app_ventas` y `usuario_efectivo = postgres`. Dentro de una función `SECURITY DEFINER`, `current_user` es el propietario de la función, mientras que `session_user` conserva el rol que se autenticó. Si la auditoría usara solo `current_user`, todos los cambios parecerían hechos por `postgres`.

1. **Compara tu hipótesis con el resultado.** Se confirma. Con `SECURITY DEFINER`, el `UPDATE` de `app_ventas` se aplicó y se auditó aunque `app_ventas` no tiene ningún privilegio sobre `auditoria`; su propio intento de leer la tabla fue rechazado. La diferencia entre `usuario_sesion` y `usuario_efectivo` muestra que la función se ejecutó con privilegios del propietario y por qué la auditoría debe usar `session_user`.
2. **Sentencia `UPDATE` que restauraría el valor anterior:**
   ```sql
   UPDATE clientes SET rfc = 'GAMA780912XYZ'
   WHERE id = 3 AND rfc = 'GAMA780912ZZZ';
   ```
   La condición sobre el valor actual evita sobrescribir un cambio posterior. La restauración también queda auditada.
3. **¿Qué columna vale más para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál es más fácil de falsificar?** `ip_cliente` vale más. Proviene de la conexión TCP, que el servidor ve directamente, aunque puede ocultarse detrás de NAT, un proxy o un *pooler*. `aplicacion` la declara el propio cliente con cualquier texto (`application_name=lo-que-sea`), así que es trivial de falsificar. Sirve para distinguir aplicaciones legítimas, pero no prueba identidad.
