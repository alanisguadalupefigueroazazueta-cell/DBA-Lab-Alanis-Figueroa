# Actividad 10 — Responder a Dirección

## 1. ¿Quién cambió el RFC de María García?

**En la Actividad 2: No hay evidencia con esta edición.**
El perfilador de la base `comercial` estaba apagado (nivel 0, valor por defecto) y `system.profile` estaba vacío. La bitácora de `mongod` no registra operaciones de escritura rápidas: la búsqueda del valor nuevo (`GAMA780912XXX`) devolvió 0 eventos. Lo único verificable es que un cliente identificado como `app-ventas-web` **se conectó y se autenticó** a las 21:22:17 (hora local) desde el propio equipo; estar conectado no demuestra haber hecho el cambio.

**En la Actividad 3: la cuenta de base de datos `app_ventas@comercial`.**
Con el perfilador en nivel 2, `system.profile` registró la operación `update` sobre `comercial.clientes` con `q: { _id: 3 }` y `u: { $set: { rfc: 'GAMA780912XYZ' } }`, ejecutada por `app_ventas@comercial` y con `nModified: 1` (repetición del 2026-11-09 04:49:27.083Z, exportada en `system-profile-actividad3.json`).

Límite de esta respuesta: identifica la **cuenta**, no a la **persona**. `app_ventas` es la cuenta de la tienda en línea; cualquiera que tenga su contraseña o acceso a la aplicación aparece con el mismo usuario.

## 2. ¿Cuándo y desde qué aplicación?

**Actividad 2: No hay evidencia con esta edición** del momento de la operación. Solo consta la conexión autenticada de `app-ventas-web` a las 21:22:17.689 (UTC-07:00), conexión `conn7`.

**Actividad 3:** el 2026-11-09 a las **04:49:27.083 UTC** (21:49:27 del 2026-11-08, hora local), desde el cliente **127.0.0.1**, con aplicación declarada **`app-ventas-web`**. En la primera ejecución de esa actividad la consulta del mismo comando quedó registrada a las 04:26:08.869 UTC.

Límite: `appName` lo **declara el cliente** en la cadena de conexión y el servidor no lo verifica; en la Actividad 5 se observó que la misma cuenta aparece como `mongosh 2.14.1` cuando la cadena no lo incluye. Es un dato de clasificación, no de identidad.

## 3. ¿Qué valor tenía antes?

**No hay evidencia con esta edición.**
El perfilador guarda el criterio y la modificación aplicada (el valor nuevo), pero **no el estado anterior** del documento. La bitácora de `mongod` tampoco registra valores de datos. MongoDB Community no ofrece un registro de la imagen previa equivalente al disparador del LAB-01 en PostgreSQL. El valor anterior solo podría obtenerse de un respaldo previo al cambio o de un registro de historial mantenido por la aplicación, y ninguno existía.

## 4. ¿Cambió alguien los privilegios de `app_ventas`?

**Sí cambiaron; quién lo hizo: No hay evidencia con esta edición.**

- **Qué cambió (detectado):** las instantáneas de privilegios muestran que `app_ventas` tenía solo `readWrite` en `comercial` a las 04:41:52.602 UTC y que a las 04:42:24.057 UTC tenía además **`dbAdmin` en `comercial`**.
- **Cuándo:** solo se sabe que ocurrió **entre** esas dos instantáneas, no el momento exacto.
- **Quién:** ni el perfilador (en nivel 2 durante el cambio) ni la bitácora de `mongod` registraron el comando `grantRolesToUser`: 0 resultados en ambas fuentes. El campo `tomada_por` de las instantáneas identifica a quien las tomó, no a quien otorgó el rol.
- **Después:** el rol se revocó, pero no se tomó una instantánea posterior; con el control actual, esa revocación **no quedó evidenciada**. Esto muestra el riesgo de que un otorgamiento y una revocación entre dos instantáneas pasen inadvertidos.

Atribuir cambios de privilegios con certeza requiere la auditoría nativa de MongoDB Enterprise o Atlas, que no existe en Community.

## Resumen para Dirección

| Pregunta | Respuesta con la evidencia disponible |
|---|---|
| ¿Quién cambió el RFC? | Actividad 2: no hay evidencia. Actividad 3: la cuenta `app_ventas@comercial` (no identifica a una persona). |
| ¿Cuándo y desde qué aplicación? | Actividad 2: no hay evidencia de la operación. Actividad 3: 2026-11-09 04:49:27 UTC, desde 127.0.0.1, aplicación declarada `app-ventas-web`. |
| ¿Qué valor tenía antes? | No hay evidencia con esta edición. |
| ¿Cambiaron los privilegios de `app_ventas`? | Sí: se agregó `dbAdmin` entre 04:41:52 y 04:42:24 UTC. Quién lo hizo: no hay evidencia con esta edición. |
