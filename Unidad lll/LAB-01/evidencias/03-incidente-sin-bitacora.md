# Evidencia 03 — El incidente sin bitácora

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 3 |
| Fecha de ejecución | 2026-11-06 14:30:52 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión por red como `app_ventas`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://app_ventas@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
```

```text
UPDATE 1
```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora
WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';
 linea 
-------
(0 rows)

```

## Interpretación y respuestas

La sentencia `UPDATE 1` confirma que el cambio se aplicó, pero la bitácora no devuelve ninguna línea. No quedaron ni la conexión de `app_ventas` ni la sentencia.

1. **¿Puedes demostrar quién modificó el RFC?** No. Solo se sabe quién *podía* hacerlo, porque tenía privilegio `UPDATE`: `app_ventas` y los superusuarios. Eso es capacidad, no evidencia del hecho.
2. **¿Puedes demostrar que no lo hizo `soporte_ana`?** No con evidencia directa. Puede argumentarse que no tenía `UPDATE`, pero el estado de los privilegios en ese momento tampoco quedó registrado. Un privilegio pudo otorgarse y revocarse antes y después del cambio sin dejar rastro.
3. **¿Los privilegios de la Unidad II impidieron el cambio? ¿Debían impedirlo?** No, y no debían. `app_ventas` tiene `UPDATE` legítimamente. El control de acceso decide si una operación está *permitida*; no distingue un uso correcto de un error o un abuso.
4. **¿Qué tendría que haber estado configurado antes del incidente?** Hacía falta todo lo siguiente, configurado antes de que ocurriera el cambio:
   - el colector de bitácora (o un destino conservado);
   - `log_connections` y `log_disconnections`;
   - un prefijo con `%u %d %a %h`;
   - `log_statement` al menos en `mod`;
   - una auditoría a nivel de dato que conserve el valor anterior;
   - una copia de la bitácora fuera del servidor y una zona horaria declarada.
