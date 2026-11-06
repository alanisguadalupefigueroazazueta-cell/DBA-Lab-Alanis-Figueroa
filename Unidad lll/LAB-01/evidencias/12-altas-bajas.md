# Evidencia 12 — Altas y bajas

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 13 |
| Fecha de ejecución | 2026-11-06 14:32:31 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión de administrador (entrada y salida de psql):*

```text
INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)
VALUES ('Pedro Ruiz', 'pedro.ruiz@example.test', 'RUPE950101AAA', 30, 'Guasave', '81000');
INSERT 0 1
DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';
DELETE 1
SELECT id_evento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
       valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
 id_evento | usuario_sesion |   aplicacion   | ip_cliente | operacion | id_cliente |   rfc_antes   |  rfc_despues  
-----------+----------------+----------------+------------+-----------+------------+---------------+---------------
         1 | app_ventas     | app-ventas-web | 127.0.0.1  | UPDATE    |          3 | GAMA780912XYZ | GAMA780912ZZZ
         2 | postgres       | psql           |            | INSERT    |          6 |               | RUPE950101AAA
         3 | postgres       | psql           |            | DELETE    |          6 | RUPE950101AAA | 
(3 rows)

```

## Interpretación y respuestas

1. **Pedro Ruiz ya no existe en `clientes`. ¿Dónde queda evidencia de que existió?** En `auditoria.cambios_clientes`. El evento `INSERT` guarda en `valores_despues` el registro completo al darse de alta, y el evento `DELETE` guarda en `valores_antes` el registro completo al eliminarse. Además, con `log_statement = mod`, la bitácora contiene el texto del `INSERT`, con sus valores, y el del `DELETE`.
2. **¿Por qué `ip_cliente` está vacía en esos eventos?** Porque el administrador se conectó por el socket Unix local. `inet_client_addr()` devuelve `NULL` cuando la conexión no es por TCP.
3. **¿Qué conflicto aparece con la política de retención? ¿Quién debe resolverlo?** La política de la Unidad II pide eliminar datos personales cuando dejan de ser necesarios, conforme al principio de minimización de la ley de protección de datos personales. Sin embargo, la auditoría conserva una copia completa del cliente eliminado, así que el dato sigue existiendo. No lo decide el DBA por sí solo. Lo resuelve el responsable del tratamiento de datos, con las áreas legal, de cumplimiento y de seguridad, que deben fijar:
   - cuánto tiempo se conserva la auditoría y con qué fundamento (por ejemplo, obligaciones fiscales o investigaciones);
   - si después de cierto plazo los datos se seudonimizan o se purgan;
   - quién autoriza y documenta esa depuración.
