# Actividad 7 — Cambios de privilegios: el límite más importante

## 1. Primera instantánea de privilegios

```javascript
db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
  momento: new Date(),
  tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
  usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
})
```

```text
{ acknowledged: true, insertedId: ObjectId('6af14f105023f67203fa59fd') }
```

## 2. Cambio de privilegios con el perfilador en nivel 2

```text
comercial> db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
{ ok: 1 }
```

## 3. Búsqueda de evidencia del cambio

```text
comercial> db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })
0

comercial> bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length
0
```

**No hay evidencia del cambio en ninguna de las dos fuentes**, aun con el perfilador registrando todas las operaciones.

## 4. Segunda instantánea y comparación

```text
{ acknowledged: true, insertedId: ObjectId('6af14f305023f67203fa59fe') }

comercial> db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0 }).sort({ momento: 1 })
[
  {
    momento: ISODate('2026-11-09T04:41:52.602Z'),
    tomada_por: [ { user: 'admin', db: 'admin' } ],
    usuarios: [
      {
        user: 'app_ventas',
        db: 'comercial',
        roles: [ { role: 'readWrite', db: 'comercial' } ]
      }
    ]
  },
  {
    momento: ISODate('2026-11-09T04:42:24.057Z'),
    tomada_por: [ { user: 'admin', db: 'admin' } ],
    usuarios: [
      {
        user: 'app_ventas',
        db: 'comercial',
        roles: [
          { role: 'dbAdmin', db: 'comercial' },
          { role: 'readWrite', db: 'comercial' }
        ]
      }
    ]
  }
]
```

`db.getUsers()` se ejecutó en la base `comercial`, por lo que la instantánea contiene los usuarios definidos en esa base (`app_ventas`). Para cubrir también a los administradores, una versión operativa debería recorrer además la base `admin`.

## 5. Restablecimiento

```text
comercial> db.revokeRolesFromUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
{ ok: 1 }

comercial> db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
{
  was: 2,
  slowms: 100,
  sampleRate: 1,
  filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } },
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}
```

## Interpretación

| Pregunta | ¿La instantánea responde? | Evidencia |
|---|---|---|
| ¿Cambiaron los privilegios de `app_ventas`? | **Sí** | La segunda instantánea tiene un rol más que la primera |
| ¿Qué rol se agregó? | **Sí** | `dbAdmin` sobre `comercial` |
| ¿Quién lo agregó? | **No** | `tomada_por` identifica a quien tomó la instantánea, no a quien hizo el cambio |
| ¿Cuándo exactamente? | **No** | Solo que ocurrió entre `04:41:52.602Z` y `04:42:24.057Z` |

La instantánea es un **control compensatorio de detección**: permite descubrir que un privilegio cambió, pero no permite **atribuirlo**. No equivale a auditoría nativa, que en MongoDB Enterprise/Atlas registraría el comando `grantRolesToUser` con usuario, cliente y momento.

Límites adicionales observados o derivados:

- **Cambios intermedios invisibles:** si alguien otorga y revoca un rol entre dos instantáneas, ninguna de las dos lo muestra. El paso 5 de esta misma actividad (otorgar y revocar) habría pasado inadvertido con instantáneas espaciadas.
- **Ventana de detección:** la precisión del "cuándo" es igual al intervalo entre instantáneas.
- **Integridad:** las instantáneas se guardan en el mismo servidor; un usuario con privilegios suficientes podría modificarlas o borrarlas, y ese cambio tampoco quedaría registrado.

## Preguntas

**1. ¿Por qué un cambio de privilegios es uno de los eventos auditables más importantes?**

Porque un privilegio no es una acción, es la **capacidad de hacer todas las acciones siguientes**. Quien obtiene un rol más alto puede leer o modificar datos que antes no podía, crear usuarios, cambiar la configuración y desactivar los propios mecanismos de registro (como el perfilador). En la práctica, la escalada de privilegios suele ser el paso previo a una fuga o alteración de datos, y la creación de privilegios ocultos es una forma común de que un atacante conserve acceso. Además, el rol `dbAdmin` otorgado aquí permite justamente administrar el perfilador y `system.profile` de la base, es decir, manipular la evidencia.

**2. ¿Con qué frecuencia tomarías instantáneas? ¿Qué factores influyen?**

Las tomaría de forma **automática y frecuente**, por ejemplo cada 5 a 15 minutos mediante una tarea programada, y además **antes y después de cada ventana de cambios** aprobada. Factores:

- **Ventana de detección aceptable:** cuanto más crítico el sistema, más corta.
- **Riesgo de cambios intermedios:** intervalos largos dejan pasar un otorgamiento y una revocación rápidos.
- **Costo:** cada instantánea es pequeña (lista de usuarios y roles), así que el costo de almacenamiento y desempeño es bajo; el costo real es **revisarlas**, por lo que conviene comparar automáticamente y alertar solo cuando haya diferencias.
- **Frecuencia de cambios legítimos** y requisitos normativos o de auditoría interna.
- **Retención:** cuánto tiempo deben conservarse para una investigación.

**3. ¿Quién debería poder escribir en `auditoria.instantaneas_privilegios`?**

Solo una **cuenta de servicio dedicada** a tomar instantáneas, con un rol personalizado que permita **insertar y leer**, pero **no actualizar ni borrar** en esa colección. No deberían poder escribir ahí:

- `app_ventas` ni ninguna cuenta de aplicación;
- los DBA cuya actividad se quiere vigilar (separación de funciones: quien puede cambiar privilegios no debería poder alterar la evidencia de esos cambios).

Idealmente, cada instantánea se exporta también **fuera del servidor** (por ejemplo a un repositorio o sistema de bitácoras centralizado) con su hash, porque un usuario con rol `root` en MongoDB puede modificar cualquier colección.

**4. Redacta en tres líneas cómo comunicarías esta limitación a Dirección.**

> MongoDB Community, la edición que usamos, no registra quién otorga o retira permisos a un usuario; lo verificamos con el registro de operaciones al máximo nivel y no quedó rastro.
> Como medida provisional tomamos fotografías periódicas de los permisos: nos dicen **qué** cambió y en qué intervalo, pero **no quién** lo hizo.
> Si necesitamos atribuir esos cambios con certeza, se requiere la auditoría de MongoDB Enterprise o Atlas, o restringir y registrar fuera de la base quién puede administrar usuarios.

## Conclusión

Ante un cambio de privilegios, MongoDB Community no deja evidencia ni en el perfilador (aun en nivel 2) ni en la bitácora de `mongod`. Para la pregunta de Dirección "¿quién cambió los privilegios de `app_ventas`?", la respuesta es: **No hay evidencia con esta edición.** Las instantáneas permiten **detectar** el cambio, no **atribuirlo**.
