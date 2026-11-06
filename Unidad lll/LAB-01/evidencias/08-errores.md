# Evidencia 08 — Errores y operaciones rechazadas

| Dato | Valor |
|---|---|
| Estudiante | [Tu nombre — matrícula] |
| Actividad | Actividad 8 |
| Fecha de ejecución | 2026-11-06 14:30:59 UTC |
| Servidor | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit |

Los bloques de esta evidencia son la entrada y la salida reales de cada sesión. Las contraseñas se sustituyeron por `<REDACTED>`.

*Sesión por red como `soporte_ana`:*

```bash
PGPASSWORD=<REDACTED> psql "postgresql://soporte_ana@127.0.0.1/comercial" -c "DELETE FROM clientes WHERE id = 5"
```

```text
ERROR:  permission denied for table clientes
```

*Sesión de administrador (entrada y salida de psql):*

```text
DROP ROLE soporte_ana;
psql:<stdin>:1: ERROR:  role "soporte_ana" cannot be dropped because some objects depend on it
DETAIL:  privileges for table clientes
```

*Sesión de administrador (entrada y salida de psql):*

```text
SELECT linea FROM dba.bitacora
WHERE linea ~ '(ERROR|STATEMENT|DETAIL):  (permission|privileges|role|DELETE|DROP)'
ORDER BY num;
                                                                                linea                                                                                
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2026-11-06 14:30:59.769 UTC [494] user=soporte_ana db=comercial app=psql client=127.0.0.1 ERROR:  permission denied for table clientes
 2026-11-06 14:30:59.769 UTC [494] user=soporte_ana db=comercial app=psql client=127.0.0.1 STATEMENT:  DELETE FROM clientes WHERE id = 5
 2026-11-06 14:30:59.795 UTC [501] user=postgres db=comercial app=psql client=[local] ERROR:  role "soporte_ana" cannot be dropped because some objects depend on it
 2026-11-06 14:30:59.795 UTC [501] user=postgres db=comercial app=psql client=[local] DETAIL:  privileges for table clientes
 2026-11-06 14:30:59.795 UTC [501] user=postgres db=comercial app=psql client=[local] STATEMENT:  DROP ROLE soporte_ana;
(5 rows)

```

## Interpretación y respuestas

Las sentencias que provocaron error quedaron registradas en una línea `STATEMENT` gracias a `log_min_error_statement = error`, sin importar el valor de `log_statement`. Como en esta actividad ya está en `mod`, el `DELETE` también aparece antes como `statement:`, es decir, antes de que se evaluaran los permisos.

1. **¿El intento de `soporte_ana` causó daño? ¿Por qué auditarlo?** No causó daño: el control de acceso lo rechazó. Aun así debe auditarse por tres razones:
   - Revela una intención o un error, como un usuario que intenta algo fuera de su función, una cuenta comprometida o un script mal configurado.
   - Los intentos repetidos forman patrones que solo se ven si cada uno quedó registrado.
   - Demuestra que el control funciona, lo que también es evidencia de cumplimiento.
2. **¿Qué diferencia hay entre un error de autorización y uno de autenticación?** La autenticación (Actividad 5) responde a "¿eres quien dices ser?". Si falla, la conexión se rechaza con un `FATAL` y no llega a existir una sesión. La autorización (esta actividad) responde a "¿puedes hacer esto?". El usuario ya está autenticado, la operación se rechaza con un `ERROR` y la sesión continúa. En este caso la línea sí identifica a un usuario verificado.
3. **¿Qué indica el error de `DROP ROLE` sobre el orden para dar de baja a un usuario?** Que un rol no puede eliminarse mientras tenga privilegios u objetos en alguna base. El orden correcto es:
   1. Bloquear el acceso con `ALTER ROLE … NOLOGIN` y terminar sus sesiones.
   2. Revocar sus privilegios, o ejecutar `REASSIGN OWNED BY …` y `DROP OWNED BY …` en cada base.
   3. Eliminar el rol con `DROP ROLE`.

   Así, cada paso queda registrado y el rol no se elimina mientras otros objetos dependen de él.
