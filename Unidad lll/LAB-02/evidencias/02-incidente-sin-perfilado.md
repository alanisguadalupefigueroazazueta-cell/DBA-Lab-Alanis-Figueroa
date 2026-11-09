# Actividad 2 — El incidente sin perfilado

## 1. Estado del perfilador (sesión del DBA)

```text
comercial> db.getProfilingStatus()
{ was: 0, slowms: 100, sampleRate: 1, ok: 1 }
```

`was: 0` indica que el perfilador de la base `comercial` está **apagado** (valor por defecto).

## 2. La aplicación modifica el RFC (sesión de la aplicación)

Comando ejecutado desde Windows PowerShell. Dentro del código JavaScript se usaron comillas simples duplicadas (`''`) porque Windows PowerShell elimina las comillas dobles internas al pasar argumentos a programas externos:

```powershell
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.updateOne({ _id: 3 }, { $set: { rfc: ''GAMA780912XXX'' } })'
```

Resultado observado:

```text
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 0,
  upsertedCount: 0
}
Error: ENOENT: no such file or directory, open 'C:\Windows\System32\mongosh'
```

**Nota de ejecución:** el comando se pegó dos veces en la misma línea, por lo que `mongosh` recibió dos opciones `--eval` y las ejecutó en un mismo proceso. La primera instrucción modificó el documento y la segunda lo encontró ya con ese valor (`matchedCount: 1`, `modifiedCount: 0`); `mongosh` solo imprime el resultado de la última. El texto sobrante (`mongosh`) se interpretó como un archivo de script inexistente, de ahí el `ENOENT`. En la bitácora se observa **una sola** ejecución del cliente (un único grupo de conexiones a las 21:22:17).

Verificación del cambio desde la sesión del DBA:

```text
comercial> db.clientes.findOne({ _id: 3 }, { rfc: 1 })
{ _id: 3, rfc: 'GAMA780912XXX' }
```

El RFC de María García cambió de `GAMA780912GHI` (valor de carga inicial) a `GAMA780912XXX`. Se conoce el valor anterior **solo** porque se cargaron los datos en este laboratorio, no por ningún registro del servidor.

## 3. Búsqueda de evidencia (sesión del DBA)

```text
comercial> db.system.profile.countDocuments()
0

comercial> bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
0

comercial> bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web")).map(e => e.t.$date + " | " + e.c + " | " + e.ctx + " | " + e.msg)
[
  '2026-11-08T21:22:17.661-07:00 | NETWORK | conn6 | client metadata',
  '2026-11-08T21:22:17.661-07:00 | ACCESS | conn6 | Connection not authenticating',
  '2026-11-08T21:22:17.669-07:00 | NETWORK | conn7 | client metadata',
  '2026-11-08T21:22:17.689-07:00 | ACCESS | conn7 | Successfully authenticated',
  '2026-11-08T21:22:17.834-07:00 | NETWORK | conn8 | client metadata',
  '2026-11-08T21:22:17.834-07:00 | NETWORK | conn9 | client metadata',
  '2026-11-08T21:22:17.862-07:00 | ACCESS | conn8 | Successfully authenticated',
  '2026-11-08T21:22:17.868-07:00 | ACCESS | conn9 | Successfully authenticated'
]
```

## Interpretación

| Fuente | ¿Registra la conexión? | ¿Registra la operación `updateOne`? | ¿Registra el valor nuevo o el anterior? |
|---|---|---|---|
| `system.profile` | No | **No** (0 documentos, perfilador apagado) | No |
| Bitácora de `mongod` (`getLog`) | **Sí** (metadatos y autenticación de `app-ventas-web`) | **No** (0 eventos con `GAMA780912XXX`) | No |

La bitácora demuestra que un cliente identificado como `app-ventas-web` **se conectó y se autenticó** a las 21:22:17 (hora local), pero no contiene ningún rastro de la operación de escritura. Con el perfilador en nivel 0 y una operación rápida (menor a `slowms` = 100 ms), MongoDB Community no deja evidencia del cambio.

## Preguntas

**1. ¿Puedes demostrar qué cambió? ¿Y quién se conectó a esa hora?**

- **Qué cambió: No hay evidencia con esta edición y esta configuración.** El perfilador estaba apagado (`was: 0`, `system.profile` vacío) y la bitácora de `mongod` no registra operaciones CRUD rápidas; la búsqueda del valor `GAMA780912XXX` devuelve 0 eventos. Solo puede observarse el **estado actual** del documento, no la operación que lo produjo ni su autor.
- **Quién se conectó: sí, parcialmente.** La bitácora registra que un cliente con `appName` `app-ventas-web` se conectó desde el propio equipo y se autenticó con éxito a las 21:22:17 (conexiones `conn7`, `conn8` y `conn9`). Esto prueba **presencia** (una conexión autenticada en ese momento), pero no prueba que esa conexión haya ejecutado el cambio: conectarse no es lo mismo que modificar.

**2. ¿Por qué `mongosh` abre varias conexiones (`conn6`, `conn7`, …) para una sola instrucción? ¿Cuál es la que se autentica?**

Los controladores de MongoDB (incluido el que usa `mongosh`) separan dos funciones:

- Una **conexión de monitoreo** que consulta periódicamente el estado del servidor (descubrimiento y monitoreo de la topología). No ejecuta operaciones de usuario y **no se autentica**: es `conn6`, con el mensaje `Connection not authenticating`.
- Un **grupo de conexiones** (*connection pool*) para las operaciones. `mongosh` abre varias al iniciar, porque además de la instrucción del usuario ejecuta sus propios comandos internos (por ejemplo, consultar la versión y el entorno del servidor). Estas **sí se autentican**: `conn7`, `conn8` y `conn9`, todas con `Successfully authenticated`.

La bitácora no permite saber por cuál de las conexiones autenticadas viajó el `updateOne`, porque no registra la operación.

## Conclusión

Sin perfilador, MongoDB Community permite saber **quién se conectó y cuándo**, pero no **qué hizo**. Para la pregunta de Dirección "¿quién cambió el RFC?", con esta configuración la respuesta es: **No hay evidencia con esta edición.**
