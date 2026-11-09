# Actividad 5 — Accesos en la bitácora de `mongod`

## 1. Intentos fallidos (sesión de la aplicación)

```powershell
mongosh "mongodb://app_ventas:incorrecta@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
MongoServerError: Authentication failed.

mongosh "mongodb://usuario_inexistente:x@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
MongoServerError: Authentication failed.
```

## 2. Eventos de acceso fallido (sesión del DBA)

```javascript
bitacora()
  .filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate")
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client,
               error: e.attr.error, result: e.attr.result,
               isSpeculative: e.attr.isSpeculative, app: e.attr.doc?.application?.name }))
```

```text
[
  {
    t: { '$date': '2026-11-08T21:32:20.345-07:00' },
    id: 5286307,
    ctx: 'conn23',
    user: 'app_ventas',
    client: '127.0.0.1:64752',
    error: 'AuthenticationFailed: SCRAM authentication failed, storedKey mismatch',
    result: 18,
    isSpeculative: true,
    app: 'mongosh 2.14.1'
  },
  {
    t: { '$date': '2026-11-08T21:32:28.279-07:00' },
    id: 5286307,
    ctx: 'conn25',
    user: 'usuario_inexistente',
    client: '127.0.0.1:64755',
    error: 'UserNotFound: Could not find user "usuario_inexistente" for db "comercial"',
    result: 11,
    isSpeculative: true,
    app: 'mongosh 2.14.1'
  },
  {
    t: { '$date': '2026-11-08T21:32:28.282-07:00' },
    id: 5286307,
    ctx: 'conn25',
    user: 'usuario_inexistente',
    client: '127.0.0.1:64755',
    error: 'UserNotFound: Could not find user "usuario_inexistente" for db "comercial"',
    result: 11,
    isSpeculative: false,
    app: 'mongosh 2.14.1'
  }
]
```

**Intentos frente a líneas:** hay **3 líneas** pero **2 intentos**. El intento con usuario inexistente produjo dos líneas en la misma conexión (`conn25`, mismo puerto `64755`, 3 ms de diferencia): primero la autenticación especulativa (`isSpeculative: true`, que el cliente envía junto con el saludo inicial para ahorrar un viaje de red) y luego el intento normal (`isSpeculative: false`). Se cuentan los intentos agrupando por conexión y cliente, no por línea.

## 3. Último acceso exitoso de la aplicación (sesión del DBA)

```javascript
bitacora()
  .filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas")
  .slice(-1)
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc?.application?.name }))
```

```text
[
  {
    t: { '$date': '2026-11-08T21:31:31.026-07:00' },
    id: 5286306,
    ctx: 'conn21',
    client: '127.0.0.1:49679',
    result: 0,
    app: 'app-ventas-web'
  }
]
```

## Tabla de interpretación

| Momento (local) | Conexión | Usuario | Resultado | Código | Motivo | Aplicación declarada |
|---|---|---|---|---|---|---|
| 21:31:31.026 | `conn21` | `app_ventas` | Éxito (`id 5286306`) | 0 | — | `app-ventas-web` |
| 21:32:20.345 | `conn23` | `app_ventas` | Fallo (`id 5286307`) | 18 | Contraseña incorrecta (`storedKey mismatch`) | `mongosh 2.14.1` |
| 21:32:28.279–.282 | `conn25` | `usuario_inexistente` | Fallo (`id 5286307`), 2 líneas | 11 | Usuario no existe (`UserNotFound`) | `mongosh 2.14.1` |

## Correlación con el perfilador

El acceso exitoso de `conn21` ocurrió a las **21:31:31.026 (UTC-07:00)**, que equivale a **04:31:31.026Z**. Es el mismo instante del documento `update` registrado en `system.profile` en la Actividad 4 (`ts: ISODate('2026-11-09T04:31:31.026Z')`, usuario `app_ventas@comercial`, aplicación `app-ventas-web`). Las dos fuentes, independientes entre sí, coinciden en usuario, aplicación y momento, lo que refuerza la trazabilidad de esa modificación.

## Preguntas

**1. ¿Qué campo distingue un acceso fallido de uno exitoso?**

Varios campos lo hacen de forma consistente:

- `msg`: `Successfully authenticated` frente a `Failed to authenticate`.
- `id`: **5286306** para éxito y **5286307** para fallo. Es el identificador más útil para filtrar, porque no depende del texto del mensaje.
- `attr.result`: **0** en éxito; un código de error distinto de cero en fallo (**18** `AuthenticationFailed`, **11** `UserNotFound`).
- `attr.error`: solo existe en los fallos y contiene la causa.

**2. ¿Qué diferencia hay entre el error de contraseña incorrecta y el de usuario inexistente? ¿Por qué el cliente recibe el mismo mensaje en ambos casos?**

En el servidor la diferencia es clara:

- Contraseña incorrecta: el usuario **existe**, pero la prueba criptográfica de SCRAM no coincide con la clave almacenada → `AuthenticationFailed: SCRAM authentication failed, storedKey mismatch` (código 18).
- Usuario inexistente: el usuario **no existe** en la base `comercial` → `UserNotFound` (código 11).

El cliente recibe en ambos casos el mismo mensaje genérico, `Authentication failed.`, para **no revelar qué usuarios existen**. Si el mensaje fuera distinto, un atacante podría enumerar nombres de usuario válidos probando nombres y observando la respuesta, y después concentrar ataques de contraseña sobre ellos. El detalle queda solo en la bitácora del servidor, accesible para el DBA, que es quien lo necesita para investigar.

**3. ¿Por qué el nombre de la aplicación del intento fallido es `mongosh 2.14.1` y no `app-ventas-web`?**

Porque las cadenas de conexión de los intentos fallidos **no incluían** la opción `?appName=app-ventas-web`. Cuando no se indica, `mongosh` declara por defecto su propio nombre y versión (`mongosh 2.14.1`).

Esto muestra una limitación importante: `appName` lo **declara el cliente** y el servidor no lo verifica. Cualquiera puede conectarse con `appName=app-ventas-web` o con cualquier otro nombre. Sirve para clasificar y correlacionar eventos, pero **no es una prueba de identidad**; la identidad la aporta el usuario autenticado (`attr.user`), y aun ese usuario puede estar compartido por varias personas o sistemas.

## Conclusión

La bitácora de `mongod` sí registra accesos exitosos y fallidos con usuario, origen (IP y puerto), momento, conexión y causa del error. Es la mejor evidencia de acceso disponible en Community. Sus límites: no registra lo que se hizo dentro de la sesión, la aplicación declarada no es verificable y `getLog` solo conserva los eventos recientes en memoria.
