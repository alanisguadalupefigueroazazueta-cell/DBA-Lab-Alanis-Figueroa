// =============================================================================
// LAB-02 — Trazabilidad en MongoDB Community
// Comandos utilizados, organizados por actividad.
//
// Servidor: MongoDB 7.0.45 Community (Windows, instalador MSI, servicio "MongoDB")
// Cliente:  mongosh 2.14.1
//
// Este archivo es una BITÁCORA DE COMANDOS, no un script para ejecutarse de
// principio a fin: varias actividades se hacen en dos sesiones distintas (DBA y
// aplicación) y algunas instrucciones son de PowerShell (van comentadas).
//
// Contraseñas sustituidas por <REDACTED>.
//
// Sesiones (desde PowerShell):
//   DBA:        mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin"
//   Aplicación: mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web"
//
// Nota para Windows PowerShell 5.1: dentro de --eval '...' se usan comillas
// simples duplicadas ('') para las cadenas de JavaScript, porque PowerShell
// elimina las comillas dobles internas al pasar argumentos a programas externos.
// =============================================================================


// -----------------------------------------------------------------------------
// Preparación — Anexo A (Windows, MSI)
// -----------------------------------------------------------------------------
// PowerShell como administrador:
//   Add-Content -Path "C:\Program Files\MongoDB\Server\7.0\bin\mongod.cfg" -Value "`nsecurity:`n  authorization: enabled"
//   Restart-Service MongoDB
//   Get-Service MongoDB


// -----------------------------------------------------------------------------
// 6.3 Crear usuarios y datos (mongosh SIN credenciales, excepción de localhost)
// Ejecutar una instrucción a la vez.
// -----------------------------------------------------------------------------
use admin
db.createUser({ user: "admin", pwd: "<REDACTED>", roles: ["root"] })
db.auth("admin", "<REDACTED>")

use comercial
db.createUser({ user: "app_ventas", pwd: "<REDACTED>", roles: [{ role: "readWrite", db: "comercial" }] })

db.clientes.insertMany([
  { _id: 1, nombre: "Ana López", correo: "ana.lopez@example.test", telefono: "6671234567", rfc: "LOAA850315ABC", edad: 41, ciudad: "Culiacán", codigo_postal: "80000" },
  { _id: 2, nombre: "Carlos Pérez", correo: "carlos.perez@example.test", telefono: "6672345678", rfc: "PECA900720DEF", edad: 35, ciudad: "Culiacán", codigo_postal: "80100" },
  { _id: 3, nombre: "María García", correo: "maria.garcia@example.test", telefono: "6673456789", rfc: "GAMA780912GHI", edad: 47, ciudad: "Mazatlán", codigo_postal: "82000" },
  { _id: 4, nombre: "Luis Torres", correo: "luis.torres@example.test", telefono: "6674567890", rfc: "TOLU920201JKL", edad: 34, ciudad: "Los Mochis", codigo_postal: "81200" },
  { _id: 5, nombre: "Laura Sánchez", correo: "laura.sanchez@example.test", telefono: "6675678901", rfc: "SALA880525MNO", edad: 38, ciudad: "Culiacán", codigo_postal: "80200" }
])


// -----------------------------------------------------------------------------
// 6.4 Función auxiliar (definir en cada sesión del DBA)
// -----------------------------------------------------------------------------
function bitacora() {
  return db.adminCommand({ getLog: "global" }).log.map(l => JSON.parse(l))
}


// -----------------------------------------------------------------------------
// Actividad 1 — Edición y limitación (sesión del DBA)
// -----------------------------------------------------------------------------
db.version()
db.adminCommand({ buildInfo: 1 }).modules
db.serverCmdLineOpts().parsed


// -----------------------------------------------------------------------------
// Actividad 2 — Incidente sin perfilado
// -----------------------------------------------------------------------------
// DBA:
db.getProfilingStatus()

// Aplicación (PowerShell):
//   mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.updateOne({ _id: 3 }, { $set: { rfc: ''GAMA780912XXX'' } })'

// DBA:
db.clientes.findOne({ _id: 3 }, { rfc: 1 })
db.system.profile.countDocuments()
bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web"))
  .map(e => e.t.$date + " | " + e.c + " | " + e.ctx + " | " + e.msg)


// -----------------------------------------------------------------------------
// Actividad 3 — Perfilador en nivel 2
// -----------------------------------------------------------------------------
// DBA:
db.setProfilingLevel(2)
db.getProfilingStatus()

// Aplicación (PowerShell, una sola vez):
//   mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ ciudad: ''Culiacán'' }, { nombre: 1, ciudad: 1 }).toArray(); db.clientes.updateOne({ _id: 3 }, { $set: { rfc: ''GAMA780912XYZ'' } }); db.clientes.deleteOne({ _id: 2 });'

// DBA:
db.system.profile.find(
  { ns: "comercial.clientes" },
  { op: 1, ns: 1, command: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1 }
).sort({ ts: 1 })

// Resumen de una línea por operación:
db.system.profile.find({ ns: "comercial.clientes" }).sort({ ts: 1 }).toArray().map(p =>
  p.ts.toISOString() + " | " + p.op + " | " + p.user + " | " + p.appName + " | " +
  JSON.stringify(p.command.filter || p.command.q) + " | " + JSON.stringify(p.command.u || "") +
  " | ret=" + p.nreturned + " mod=" + p.nModified + " del=" + p.ndeleted)

// Exportar ANTES de vaciar system.profile (PowerShell, desde la carpeta LAB-02):
//   mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'require(''fs'').writeFileSync(''evidencias/system-profile-actividad3.json'', EJSON.stringify(db.system.profile.find({ ns: ''comercial.clientes'' }, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1, ''command.filter'': 1, ''command.q'': 1, ''command.u'': 1 }).sort({ ts: 1 }).toArray(), null, 2))'

// Restauración de datos usada para repetir la Actividad 3 (DBA, con perfilador en 0):
db.setProfilingLevel(0)
db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XXX" } })
db.clientes.insertOne({ _id: 2, nombre: "Carlos Pérez", correo: "carlos.perez@example.test", telefono: "6672345678", rfc: "PECA900720DEF", edad: 35, ciudad: "Culiacán", codigo_postal: "80100" })


// -----------------------------------------------------------------------------
// Actividad 4 — Filtro del perfilador
// -----------------------------------------------------------------------------
// DBA:
db.setProfilingLevel(0)
db.system.profile.drop()
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
db.getProfilingStatus()

// Aplicación (PowerShell):
//   mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ _id: 1 }).toArray(); db.clientes.updateOne({ _id: 1 }, { $set: { telefono: ''6670000000'' } })'

// DBA:
db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 })

// Variante: solo escrituras sobre la colección clientes
// db.setProfilingLevel(1, { filter: { ns: "comercial.clientes", op: { $in: ["insert", "update", "remove"] } } })


// -----------------------------------------------------------------------------
// Actividad 5 — Accesos en la bitácora de mongod
// -----------------------------------------------------------------------------
// Aplicación (PowerShell):
//   mongosh "mongodb://app_ventas:incorrecta@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
//   mongosh "mongodb://usuario_inexistente:x@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"

// DBA:
bitacora()
  .filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate")
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client,
               error: e.attr.error, result: e.attr.result,
               isSpeculative: e.attr.isSpeculative, app: e.attr.doc?.application?.name }))

bitacora()
  .filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas")
  .slice(-1)
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc?.application?.name }))


// -----------------------------------------------------------------------------
// Actividad 6 — Correlación por conexión (ctx)
// -----------------------------------------------------------------------------
bitacora()
  .filter(e => e.msg === "Profiler settings changed")
  .map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))

// Sustituir conn3 por el ctx del último cambio:
bitacora()
  .filter(e => e.ctx === "conn3" && e.msg === "Successfully authenticated")
  .map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))


// -----------------------------------------------------------------------------
// Actividad 7 — Privilegios y control compensatorio (sesión del DBA)
// -----------------------------------------------------------------------------
function instantanea() {
  return db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
    momento: new Date(),
    tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
    usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
  })
}

instantanea()
db.setProfilingLevel(2)
db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])

db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })
bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length

instantanea()
db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0 }).sort({ momento: 1 })

db.revokeRolesFromUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })


// -----------------------------------------------------------------------------
// Actividad 8 — Conservación
// -----------------------------------------------------------------------------
// 1) Exportar ANTES de reiniciar (PowerShell, desde la carpeta LAB-02):
//   mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'require(''fs'').writeFileSync(''evidencias/system-profile.json'', EJSON.stringify(db.system.profile.find({}, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, ''command.q'': 1, ''command.u'': 1 }).toArray(), null, 2))'
//   mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'require(''fs'').writeFileSync(''evidencias/bitacora-mongod.log'', db.adminCommand({ getLog: ''global'' }).log.join(''\n''))'
//
// 2) Reiniciar (PowerShell COMO ADMINISTRADOR):
//   Restart-Service MongoDB
//
// 3) Verificar (nueva sesión del DBA):
db.getProfilingStatus()
db.system.profile.countDocuments()
bitacora().length
//
// 4) Copiar la bitácora completa y calcular hashes (PowerShell, carpeta LAB-02):
//   Copy-Item "C:\Program Files\MongoDB\Server\7.0\log\mongod.log" evidencias\mongod-archivo.log
//   Get-FileHash evidencias\*.json, evidencias\*.log -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } | Set-Content -Encoding ascii evidencias\hashes.sha256
//   Get-Content evidencias\hashes.sha256
