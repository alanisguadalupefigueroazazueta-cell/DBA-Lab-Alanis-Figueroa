# Actividad 3 — Activar el perfilador y registrar operaciones

## Nota de ejecución: por qué hay una primera y una segunda ejecución

1. **Primera ejecución** (2026-11-08 21:25–21:27 local = 04:25–04:27 UTC). El comando de la aplicación se ejecutó dos veces seguidas y los documentos se consultaron en pantalla, pero `system.profile` se vació en la Actividad 4 **sin haberlo exportado antes** (error frecuente n.º 4 de la guía). La evidencia de esa ejecución solo quedó en capturas.
2. **Repetición** (2026-11-08 21:49 local = 04:49 UTC). Siguiendo la indicación de la guía ("si no lo hiciste, repite la Actividad 3 después de esta"), se restauraron los datos al estado previo, se repitió la actividad y esta vez se exportó el resultado **antes** de cualquier cambio. Es la evidencia principal de esta actividad.

Para la repetición, el DBA restauró el RFC de María García a `GAMA780912XXX` y volvió a insertar a Carlos Pérez (`_id: 2`) **con el perfilador en nivel 0**. Esas dos operaciones del DBA no aparecen en `system.profile`: es otro ejemplo de que, con el perfilador apagado, una modificación no deja rastro.

## 1. Activación del nivel 2 (sesión del DBA)

Primera ejecución:

```text
comercial> db.setProfilingLevel(2)
{ was: 0, slowms: 100, sampleRate: 1, ok: 1 }

comercial> db.getProfilingStatus()
{ was: 2, slowms: 100, sampleRate: 1, ok: 1 }
```

`setProfilingLevel` devuelve en `was` el nivel **anterior**; `getProfilingStatus` confirma el nivel vigente (2). La bitácora de `mongod` registró este cambio a las 21:25:45.563 en la conexión `conn3` (ver Actividad 6).

## 2. La aplicación ejecuta una consulta, una actualización y una eliminación (repetición)

Desde la carpeta del repositorio (`C:\Users\joser\Documents\LAB-02`):

```powershell
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ ciudad: ''Culiacán'' }, { nombre: 1, ciudad: 1 }).toArray(); db.clientes.updateOne({ _id: 3 }, { $set: { rfc: ''GAMA780912XYZ'' } }); db.clientes.deleteOne({ _id: 2 });'
```

```text
{ acknowledged: true, deletedCount: 1 }
```

Exportación inmediata del perfilador:

```powershell
mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'require(''fs'').writeFileSync(''evidencias/system-profile-actividad3.json'', EJSON.stringify(db.system.profile.find({ ns: ''comercial.clientes'' }, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1, ''command.filter'': 1, ''command.q'': 1, ''command.u'': 1 }).sort({ ts: 1 }).toArray(), null, 2))'
```

```text
Directorio: C:\Users\joser\Documents\LAB-02\evidencias
-a----   08/11/2026  09:49 p. m.   1542 system-profile-actividad3.json
```

Se usó `writeFileSync` de `mongosh` en lugar de la redirección `>` porque en Windows PowerShell 5.1 `>` guarda el archivo en UTF-16, lo que dificulta compararlo, versionarlo en Git y calcular su hash de forma reproducible.

## 3. Consulta del perfilador (sesión del DBA)

Resumen de una línea por operación:

```javascript
db.system.profile.find({ ns: "comercial.clientes" }).sort({ ts: 1 }).toArray().map(p =>
  p.ts.toISOString() + " | " + p.op + " | " + p.user + " | " + p.appName + " | " +
  JSON.stringify(p.command.filter || p.command.q) + " | " + JSON.stringify(p.command.u || "") +
  " | ret=" + p.nreturned + " mod=" + p.nModified + " del=" + p.ndeleted)
```

```text
[
  '2026-11-09T04:31:31.026Z | update | app_ventas@comercial | app-ventas-web | {"_id":1} | {"$set":{"telefono":"6670000000"}} | ret=undefined mod=1 del=undefined',
  '2026-11-09T04:49:27.077Z | query | app_ventas@comercial | app-ventas-web | {"ciudad":"Culiacán"} | "" | ret=3 mod=undefined del=undefined',
  '2026-11-09T04:49:27.083Z | update | app_ventas@comercial | app-ventas-web | {"_id":3} | {"$set":{"rfc":"GAMA780912XYZ"}} | ret=undefined mod=1 del=undefined',
  '2026-11-09T04:49:27.086Z | remove | app_ventas@comercial | app-ventas-web | {"_id":2} | "" | ret=undefined mod=undefined del=1'
]
```

La primera línea es el `update` de la Actividad 4 (registrado con el filtro de escrituras). Las tres siguientes son la repetición de esta actividad. `undefined` indica que ese contador no aplica al tipo de operación (por ejemplo, un `query` no tiene `nModified`).

Fragmento de la primera ejecución (capturas de pantalla), con el documento completo tal como lo muestra el perfilador:

```text
{
  op: 'update',
  ns: 'comercial.clientes',
  command: { q: { _id: 3 }, u: { '$set': { rfc: 'GAMA780912XYZ' } }, multi: false, upsert: false },
  docsExamined: 1,
  nModified: 0,
  millis: 0,
  ts: ISODate('2026-11-09T04:26:36.422Z'),
  client: '127.0.0.1',
  appName: 'app-ventas-web',
  user: 'app_ventas@comercial'
}
```

En esa primera ejecución, la segunda pasada del comando produjo `nModified: 0` y `ndeleted: 0`, porque el RFC ya tenía el valor nuevo y Carlos Pérez ya había sido eliminado. Esto demuestra que el perfilador registra la **operación intentada** aunque no cambie nada: hay que leer `nModified` y `ndeleted`, no solo `op`.

## 9.1 Interpretación de los documentos (repetición)

| # | `op` | Usuario | Cliente | Aplicación | Momento (UTC) | Qué hizo | Documentos afectados |
|---|---|---|---|---|---|---|---|
| 1 | `query` | `app_ventas@comercial` | `127.0.0.1` | `app-ventas-web` | 2026-11-09 04:49:27.077 | Buscó clientes con `ciudad: 'Culiacán'`, proyectando `nombre` y `ciudad` | Devolvió 3 |
| 2 | `update` | `app_ventas@comercial` | `127.0.0.1` | `app-ventas-web` | 2026-11-09 04:49:27.083 | `$set` de `rfc: 'GAMA780912XYZ'` sobre `_id: 3` (María García) | Modificó 1 |
| 3 | `remove` | `app_ventas@comercial` | `127.0.0.1` | `app-ventas-web` | 2026-11-09 04:49:27.086 | Eliminó el documento con `_id: 2` (Carlos Pérez) | Eliminó 1 |

El detalle completo de cada documento (incluidos `client`, `docsExamined` y `millis`) está en `system-profile-actividad3.json`. Las tres operaciones ocurrieron en 9 ms dentro de una misma ejecución de `mongosh`.

## Preguntas

**1. ¿Puedes saber cuál era el RFC antes del cambio con la información de `system.profile`?**

**No.** El documento `update` guarda el criterio (`q: { _id: 3 }`) y la modificación aplicada (`u: { $set: { rfc: 'GAMA780912XYZ' } }`), es decir, el **valor nuevo**. No guarda el estado del documento antes de la operación. El valor anterior (`GAMA780912XXX`) solo se conoce porque lo pusimos nosotros, no porque el perfilador lo registre.

**2. ¿Puedes saber qué datos tenía el documento eliminado?**

**No.** El documento `remove` solo contiene el criterio `q: { _id: 2 }`. Nombre, correo, teléfono y RFC de Carlos Pérez desaparecieron de la colección y no quedan en `system.profile`. Sin un respaldo o una copia previa no hay forma de recuperarlos ni de demostrar qué contenían. (En esta práctica pudo reinsertarse solo porque los datos de carga estaban en la guía.)

**3. A diferencia de `log_statement = 'mod'` en PostgreSQL, el nivel 2 sí registró la consulta. ¿Qué ventaja y qué riesgo tiene eso?**

- **Ventaja:** se puede rastrear **quién leyó datos**, con qué criterio y cuántos documentos obtuvo. Es útil para investigar accesos indebidos a datos personales (por ejemplo, alguien que consultó todos los clientes de una ciudad).
- **Riesgo:** el filtro y la proyección de cada consulta se copian **en texto claro** a `system.profile`. Si una búsqueda usa como criterio un RFC, un correo o un teléfono, ese dato personal queda duplicado en una colección que no fue diseñada para protegerlo, que puede leer cualquier usuario con permisos sobre la base y que no está cubierta por las mismas políticas de acceso y retención. Además, el nivel 2 aumenta el costo de desempeño y llena antes la colección limitada de 1 MB, con lo que la evidencia útil se sobrescribe más rápido.

**4. ¿Por qué el campo `user` incluye `@comercial`?**

Porque en MongoDB un usuario se identifica por **nombre y base de autenticación** (la base donde se creó). `app_ventas` se creó en `comercial`, así que su identidad completa es `app_ventas@comercial`. Podría existir otro `app_ventas` definido en otra base, con otros roles, y sería un usuario distinto. Por el mismo motivo, el DBA aparece como `admin@admin`.

## Conclusión

Con el nivel 2, `system.profile` responde **quién** (usuario autenticado), **desde dónde** (cliente), **con qué aplicación** (`appName`), **cuándo** (`ts`) y **qué operación** se intentó sobre **qué documento**, incluido el valor nuevo. No responde cuál era el valor anterior ni qué contenía un documento eliminado, y su contenido es temporal: en este mismo laboratorio la primera ejecución se perdió al vaciar la colección antes de exportarla.
