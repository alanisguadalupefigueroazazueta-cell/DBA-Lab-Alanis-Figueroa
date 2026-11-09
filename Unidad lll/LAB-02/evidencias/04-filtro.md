# Actividad 4 — Reducir el volumen con un filtro

## 1. Configuración del filtro (sesión del DBA)

```text
comercial> db.setProfilingLevel(0)
{ was: 2, slowms: 100, sampleRate: 1, ok: 1 }

comercial> db.system.profile.drop()
true

comercial> db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
{
  was: 0,
  slowms: 100,
  sampleRate: 1,
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}

comercial> db.getProfilingStatus()
{
  was: 1,
  slowms: 100,
  sampleRate: 1,
  filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } },
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}
```

Lectura correcta de `was`: `setProfilingLevel` devuelve el nivel **anterior** al cambio (2 → 0, luego 0 → 1). El nivel vigente se confirma con `getProfilingStatus()`, que devuelve `was: 1` y el filtro aplicado.

## 2. La aplicación ejecuta una consulta y una actualización

```powershell
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ _id: 1 }).toArray(); db.clientes.updateOne({ _id: 1 }, { $set: { telefono: ''6670000000'' } })'
```

```text
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

## 3. Contenido de `system.profile`

```text
comercial> db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 })
[
  {
    op: 'update',
    ns: 'comercial.clientes',
    command: { q: { _id: 1 }, u: { '$set': { telefono: '6670000000' } } },
    ts: ISODate('2026-11-09T04:31:31.026Z'),
    appName: 'app-ventas-web',
    user: 'app_ventas@comercial'
  }
]
```

## Interpretación

La aplicación ejecutó dos operaciones (un `find` y un `updateOne`), pero `system.profile` contiene **solo la actualización**. El filtro `{ op: { $in: ["insert", "update", "remove"] } }` hace que el perfilador registre únicamente operaciones de escritura y descarte las lecturas (`query`), los comandos y cualquier otra operación.

El documento registrado conserva lo necesario para trazar la modificación: usuario (`app_ventas@comercial`), aplicación (`app-ventas-web`), momento (`2026-11-09T04:31:31.026Z`), documento afectado (`_id: 1`) y valor nuevo (`telefono: '6670000000'`). Igual que en la Actividad 3, **no** conserva el valor anterior del teléfono.

## Preguntas

**1. ¿Qué perdiste de evidencia al aplicar el filtro? ¿Qué ganaste?**

Se perdió:

- **Las lecturas.** La consulta `find({ _id: 1 })` no quedó registrada. Ya no puede saberse quién consultó datos personales (nombre, RFC, teléfono) ni con qué criterios.
- **Los comandos y otras operaciones** (por ejemplo `aggregate`, `count`, `getMore` o comandos administrativos sobre la base).
- **El registro de operaciones lentas.** Como indica la nota del servidor, con un filtro activo `slowms` y `sampleRate` dejan de usarse para el perfilado y para las líneas de consultas lentas de la bitácora; una consulta lenta ya no se registraría por ser lenta. El perfilador pierde parte de su propósito original de diagnóstico de desempeño.

Se ganó:

- **Menos volumen.** Al guardar solo escrituras, la colección limitada de 1 MB tarda más en llenarse, así que los registros de modificaciones **se conservan más tiempo** antes de sobrescribirse.
- **Menos costo de desempeño** que el nivel 2, porque no se escribe un documento por cada lectura.
- **Menos exposición de datos personales**, porque los filtros de las consultas (que pueden contener RFC, correos o teléfonos usados como criterio de búsqueda) ya no se copian a `system.profile`.
- **Una señal más limpia** para la pregunta que interesa a facturación: quién modificó datos.

**2. ¿Qué filtro usarías si solo interesaran operaciones sobre la colección `clientes`?**

El filtro del perfilador acepta condiciones sobre los campos de su salida, entre ellos `ns`. Para registrar solo las escrituras sobre `clientes`:

```javascript
db.setProfilingLevel(1, {
  filter: {
    ns: "comercial.clientes",
    op: { $in: ["insert", "update", "remove"] }
  }
})
```

Si interesaran **todas** las operaciones (incluidas lecturas) sobre esa colección, bastaría con `{ filter: { ns: "comercial.clientes" } }`.

## Conclusión

El filtro convierte el perfilador en un registro de modificaciones con mejor retención y menor costo, a cambio de perder la trazabilidad de las lecturas y la detección de operaciones lentas. Sigue sin ser auditoría: no registra el valor anterior, no registra cambios de privilegios y su contenido puede sobrescribirse o borrarse.
