# Actividad 6 — Correlacionar un cambio de configuración con su autor

## 1. Cambios de configuración del perfilador

```javascript
bitacora()
  .filter(e => e.msg === "Profiler settings changed")
  .map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))
```

```text
[
  {
    t: { '$date': '2026-11-08T21:25:45.563-07:00' },
    ctx: 'conn3',
    msg: 'Profiler settings changed',
    attr: {
      from: { level: 0, slowms: 100, sampleRate: 1 },
      to: { level: 2, slowms: 100, sampleRate: 1 },
      db: 'comercial'
    }
  },
  {
    t: { '$date': '2026-11-08T21:31:08.442-07:00' },
    ctx: 'conn3',
    msg: 'Profiler settings changed',
    attr: {
      from: { level: 2, slowms: 100, sampleRate: 1 },
      to: { level: 0, slowms: 100, sampleRate: 1 },
      db: 'comercial'
    }
  },
  {
    t: { '$date': '2026-11-08T21:31:17.272-07:00' },
    ctx: 'conn3',
    msg: 'Profiler settings changed',
    attr: {
      from: { level: 0, slowms: 100, sampleRate: 1 },
      to: {
        level: 1,
        slowms: 100,
        sampleRate: 1,
        filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } }
      },
      db: 'comercial'
    }
  }
]
```

Los tres eventos corresponden a las Actividades 3 y 4: activación del nivel 2, regreso a nivel 0 antes de vaciar `system.profile` y activación del nivel 1 con filtro. Cada evento registra el estado **anterior** (`from`), el **nuevo** (`to`) y la base afectada (`db`), pero **no** el usuario.

## 2. Autenticación de la misma conexión

El último cambio tiene `ctx: 'conn3'`. Se busca la autenticación exitosa de esa conexión:

```javascript
bitacora()
  .filter(e => e.ctx === "conn3" && e.msg === "Successfully authenticated")
  .map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))
```

```text
[
  {
    t: { '$date': '2026-11-08T21:19:18.212-07:00' },
    ctx: 'conn3',
    user: 'admin',
    db: 'admin',
    client: '127.0.0.1:53997'
  }
]
```

## Línea de tiempo reconstruida

| Momento (local) | Conexión | Evento | Detalle |
|---|---|---|---|
| 21:19:18.212 | `conn3` | `Successfully authenticated` | Usuario `admin`, base `admin`, cliente `127.0.0.1:53997` |
| 21:25:45.563 | `conn3` | `Profiler settings changed` | `comercial`: nivel 0 → 2 |
| 21:31:08.442 | `conn3` | `Profiler settings changed` | `comercial`: nivel 2 → 0 |
| 21:31:17.272 | `conn3` | `Profiler settings changed` | `comercial`: nivel 0 → 1 con filtro de escrituras |

## Preguntas

**1. ¿Qué usuario cambió la configuración del perfilador? ¿Qué dos eventos lo demuestran?**

El usuario **`admin`** (definido en la base `admin`), conectado desde `127.0.0.1:53997`. Lo demuestran dos eventos que comparten el mismo contexto `conn3`:

1. `Successfully authenticated` a las 21:19:18.212, con `user: 'admin'`, `db: 'admin'`.
2. `Profiler settings changed` a las 21:31:17.272 (y los dos anteriores), con `ctx: 'conn3'`.

Ninguno de los dos eventos basta por sí solo: el primero dice quién se autenticó pero no qué hizo; el segundo dice qué cambió pero no quién. La atribución surge de **unirlos por la conexión**.

**2. ¿Qué condición debe cumplirse para que esta correlación sea válida?**

Que ambos eventos pertenezcan a la **misma ejecución del servidor**. Los números de conexión (`conn1`, `conn2`, …) son un contador que se reinicia cada vez que arranca `mongod`; después de un reinicio, otra conexión distinta, de otro usuario, puede volver a llamarse `conn3`. Por eso la correlación también exige:

- que no haya un reinicio del servidor entre la autenticación y el cambio (en la bitácora, un reinicio se identifica por los mensajes de arranque del proceso);
- que la conexión no se haya vuelto a autenticar como otro usuario entre ambos eventos;
- que los dos eventos estén disponibles: `getLog` solo guarda los 1024 eventos más recientes, así que en una conexión larga la autenticación puede ya no estar en memoria y debe buscarse en el archivo `mongod.log`;
- que los eventos provengan del mismo servidor, si se revisan bitácoras de varios nodos.

**3. ¿Por qué es relevante que quede registrado un cambio de configuración del propio mecanismo de registro?**

Porque el perfilador es justamente lo que permite reconstruir quién modificó datos. Si alguien quiere ocultar una acción, lo más sencillo es **apagar el registro, actuar y volver a encenderlo**; el periodo intermedio quedaría sin evidencia y nadie lo notaría. Que la bitácora de `mongod` registre `Profiler settings changed` con el estado anterior, el nuevo y la conexión permite:

- detectar huecos de evidencia (ventanas en que el perfilador estuvo apagado);
- atribuir el cambio a un usuario mediante la correlación por `ctx`;
- demostrar que el control estuvo activo durante el periodo que se investiga.

En auditoría, la protección del propio mecanismo de registro es tan importante como el registro mismo.

## Conclusión

En MongoDB Community, la bitácora de `mongod` no escribe el usuario en el evento de cambio de configuración, pero sí permite **atribuirlo indirectamente** correlacionando por conexión. Es una atribución válida solo bajo las condiciones descritas y depende de que la bitácora se conserve.
