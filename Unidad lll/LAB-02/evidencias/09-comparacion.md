# Actividad 9 — Comparar los tres escenarios


**Convención:** **Sí** (observado), **Parcial** (con explicación), **No**. Para Enterprise/Atlas: **Documentado, no practicado**, porque esa edición no se usó.

| Evento auditable | PostgreSQL (bitácora + disparador) | MongoDB Community (perfilador + bitácora) | MongoDB Enterprise/Atlas (auditoría nativa) |
|---|---|---|---|
| Acceso exitoso | **Sí.** Con `log_connections` la bitácora registra la conexión y la autorización del usuario. | **Sí.** Bitácora de `mongod`: `Successfully authenticated` (id 5286306) con usuario, base, cliente, conexión y `appName` (Actividad 5). | Documentado, no practicado (categoría autenticación y autorización). |
| Acceso fallido | **Sí.** La bitácora registra el `FATAL` de autenticación fallida con el usuario. | **Sí.** `Failed to authenticate` (id 5286307) con usuario, cliente, causa (`storedKey mismatch`, `UserNotFound`) y código (Actividad 5). | Documentado, no practicado. |
| Cambio de privilegios | **Sí.** `GRANT`/`REVOKE` quedan en la bitácora con `log_statement` en `ddl` o superior, y el prefijo de línea identifica al usuario. | **No.** Ni el perfilador en nivel 2 ni la bitácora registraron `grantRolesToUser` (0 y 0, Actividad 7). Las instantáneas de privilegios solo **detectan** qué cambió entre dos momentos, no quién ni cuándo exactamente. | Documentado, no practicado (categoría autenticación y autorización; registra el comando con usuario y momento). |
| Cambio de estructura | **Sí.** DDL registrado con `log_statement` en `ddl` o superior. | **Parcial, no verificado.** Con nivel 2 el perfilador registra los comandos ejecutados en la base, pero no se probó DDL en este laboratorio; con el filtro de escrituras no se registraría. La bitácora no registra DDL ordinario. | Documentado, no practicado (categoría cambios de esquema). |
| Modificación de datos | **Sí.** Bitácora (`log_statement = 'mod'`) y disparador con usuario, momento y operación. | **Parcial.** Sí con el perfilador activo: usuario, cliente, `appName`, momento, criterio y valor nuevo (Actividades 3 y 4). No hay nada con el perfilador apagado (Actividad 2), que es el valor por defecto y el estado tras un reinicio (Actividad 8). | Documentado, no practicado (operaciones CRUD; requiere `auditAuthorizationSuccess: true`). |
| Valor anterior del dato | **Sí.** El disparador guarda el registro anterior (`OLD`). | **No.** `system.profile` solo guarda el criterio y la modificación (`q` y `u`); tampoco conserva el contenido de un documento eliminado (Actividad 3). | **No** como función de auditoría: la auditoría registra el comando ejecutado, no la imagen previa del documento (según REF-U3-04, documentado, no practicado). |
| Lectura de datos sensibles | **Parcial.** Con `log_statement = 'mod'` las consultas `SELECT` no se registran; requeriría `all` o `pgaudit`. El disparador no se activa con lecturas. | **Parcial.** Sí con nivel 2: la consulta quedó registrada con filtro y proyección (Actividad 3). No con el filtro de escrituras (Actividad 4) ni con el perfilador apagado. | Documentado, no practicado (CRUD con `auditAuthorizationSuccess: true`). |
| Cambio de configuración del registro | **Sí.** La recarga de configuración y los parámetros modificados quedan en la bitácora del servidor; `ALTER SYSTEM` también, según `log_statement`. | **Sí, con atribución indirecta.** `Profiler settings changed` registra estado anterior, nuevo, base y conexión; el usuario se obtiene correlacionando por `ctx` con `Successfully authenticated` (Actividad 6). | Documentado, no practicado. |

> La columna de PostgreSQL resume la configuración del LAB-01 (`log_connections`, `log_statement = 'mod'` y un disparador de auditoría del dato). Si en tu LAB-01 usaste otros valores, ajusta las celdas a lo que observaste allí.

## Lectura de la tabla

- **Donde Community es fuerte:** accesos exitosos y fallidos, y cambios de configuración del propio perfilador. Esa evidencia está en la bitácora de `mongod` sin configuración adicional.
- **Donde Community es parcial:** modificaciones y lecturas. Dependen de que el perfilador esté encendido en la base correcta, de su nivel y filtro, y de que `system.profile` no se haya sobrescrito ni vaciado.
- **Donde Community no llega:** cambios de privilegios y valor anterior del dato. Ningún mecanismo disponible los registra.
- **PostgreSQL** cubre el valor anterior gracias al disparador, que es auditoría del dato construida a nivel de aplicación de base de datos. En MongoDB Community no se practicó un equivalente (por ejemplo, *change streams* con imagen previa o una colección de historial mantenida por la aplicación).
- **Enterprise/Atlas** cubriría accesos, privilegios, esquema y CRUD con un solo mecanismo de auditoría, pero esta afirmación proviene de la documentación, no de una prueba.
