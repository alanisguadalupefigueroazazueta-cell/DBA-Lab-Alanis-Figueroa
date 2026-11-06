# Evidencia 14 — Límites: lecturas y volumen

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 15 |
| Fecha de ejecución | 2026-11-06 14:32:31 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión por red como `soporte_ana`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://soporte_ana@127.0.0.1/comercial" -c "SELECT nombre, rfc, telefono FROM clientes WHERE id = 3"
```

```text
    nombre    |      rfc      |  telefono  
--------------+---------------+------------
 María García | GAMA780912GHI | 6679990000
(1 row)

```

*Sesión de administrador (entrada y salida de psql):*

```text
UPDATE clientes SET segmento = 'regular';
UPDATE 5
SELECT count(*) AS lineas_bitacora FROM dba.bitacora
WHERE linea LIKE '%statement: UPDATE clientes SET segmento%';
 lineas_bitacora 
-----------------
               1
(1 row)

SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;
 operacion | count 
-----------+-------
 DELETE    |     1
 INSERT    |     1
 UPDATE    |     6
(3 rows)

SELECT count(*) AS lecturas_soporte FROM dba.bitacora
WHERE linea LIKE '%user=soporte_ana%SELECT nombre, rfc%';
 lecturas_soporte 
------------------
                0
(1 row)

```

## Interpretación y respuestas

El `UPDATE` masivo produjo **una** línea en la bitácora y **una fila de auditoría por registro afectado**. La lectura del RFC por parte de `soporte_ana` no dejó rastro: no existe disparador para `SELECT` y `mod` no registra consultas.

1. **Si `clientes` tuviera un millón de registros, ¿qué ocurriría tras un `UPDATE` sin `WHERE`?** La auditoría recibiría un millón de filas, cada una con dos copias JSONB del registro, dentro de la misma transacción. Eso implica:
   - la transacción tarda mucho más, porque se escribe varias veces el volumen original;
   - crecen el WAL, el espacio en disco y los respaldos;
   - la tabla de auditoría crece de golpe.

   La bitácora, en cambio, sigue registrando una sola línea. Esto obliga a planear capacidad, particiones o depuración para la auditoría, y a tratar con cuidado los cambios masivos legítimos.
2. **¿Quién podría autorizar la depuración de `auditoria.cambios_clientes`?** No el DBA ni la aplicación, porque son los auditados. Debe autorizarla el responsable de los datos, o el oficial de protección de datos, junto con seguridad o cumplimiento, conforme a una política de retención escrita. La depuración debe hacerse con respaldo o archivado previo y dejar su propio registro: quién la autorizó, cuándo y qué rango se eliminó.
3. **¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?** Porque registra el texto de *todas* las consultas, con sus valores literales: búsquedas por RFC, nombre o correo, y valores de inserciones. Con el protocolo extendido también registra los parámetros de enlace. La bitácora tendría datos personales de toda la base, normalmente con menos controles que la base misma: archivos de texto, copias, envío a otros sistemas.
