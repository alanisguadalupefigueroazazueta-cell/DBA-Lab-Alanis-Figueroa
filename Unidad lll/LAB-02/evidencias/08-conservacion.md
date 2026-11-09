# Actividad 8 — Conservación: exportar antes de perder

## Orden aplicado

Se exportó **antes** de reiniciar, porque el reinicio vacía la memoria de `getLog`:

1. Exportar `system.profile` → `evidencias/system-profile.json`.
2. Exportar la bitácora en memoria (`getLog`) → `evidencias/bitacora-mongod.log`.
3. Reiniciar el servicio.
4. Verificar el estado posterior al reinicio.
5. Copiar el archivo completo de la bitácora (`systemLog.path`) → `evidencias/mongod-archivo.log`.
6. Calcular los hashes SHA-256 → `evidencias/hashes.sha256`.

## 1. Exportación de `system.profile`

```powershell
mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'require(''fs'').writeFileSync(''evidencias/system-profile.json'', EJSON.stringify(db.system.profile.find({}, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, ''command.q'': 1, ''command.u'': 1 }).toArray(), null, 2))'
```

Diferencia con la guía: en lugar de redirigir con `>` se escribe el archivo desde `mongosh` con `fs.writeFileSync`. En Windows PowerShell 5.1, `>` guarda en UTF-16; así el archivo queda en UTF-8, legible en Git y con un hash reproducible. Dentro del código se usan comillas simples duplicadas (`''`) porque Windows PowerShell elimina las comillas dobles internas al invocar programas externos.

## 2. Exportación de la bitácora en memoria

```powershell
mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'require(''fs'').writeFileSync(''evidencias/bitacora-mongod.log'', db.adminCommand({ getLog: ''global'' }).log.join(''\n''))'
```

## 3. Reinicio del servicio

El primer intento falló por falta de privilegios:

```text
PS C:\Users\joser\Documents\LAB-02> Restart-Service MongoDB
Restart-Service : No se puede detener el servicio 'MongoDB Server (MongoDB) (MongoDB)' debido al error siguiente:
No se puede abrir el servicio MongoDB en el equipo '.'.
```

Reiniciar un servicio de Windows requiere una sesión de PowerShell **como administrador**. Desde una sesión elevada:

```text
PS C:\Windows\system32> Restart-Service MongoDB
PS C:\Windows\system32> Get-Service MongoDB

Status   Name               DisplayName
------   ----               -----------
Running  MongoDB            MongoDB Server (MongoDB)
```

## 4. Estado después del reinicio (nueva sesión del DBA)

```text
comercial> db.getProfilingStatus()
{ was: 0, slowms: 100, sampleRate: 1, ok: 1 }

comercial> db.system.profile.countDocuments()
7

comercial> bitacora().length
81
```

| Elemento | Antes del reinicio | Después del reinicio |
|---|---|---|
| Nivel del perfilador en `comercial` | 1, con filtro de escrituras (configurado con `setProfilingLevel`) | **0** (apagado) |
| Documentos en `system.profile` | Los exportados en `system-profile.json` | 7 (se conservan) |
| Eventos en memoria de `getLog` | Los exportados en `bitacora-mongod.log` (142 035 bytes) | **81** (solo los del nuevo arranque) |
| Archivo `mongod.log` | Historia desde la instalación | Misma historia + eventos del nuevo arranque (`logAppend: true`) |

Interpretación:

- El **nivel** del perfilador no sobrevive al reinicio cuando se configura con `db.setProfilingLevel()`: volvió a 0 sin que nadie lo apagara. Desde ese momento, **ninguna modificación de datos queda registrada**, y nada lo advierte.
- Los **documentos** ya registrados sí se conservan, porque `system.profile` es una colección en disco.
- La memoria de `getLog` se vació: los eventos de autenticación, accesos fallidos y cambios de configuración de las Actividades 2 a 7 **ya no pueden consultarse** con `getLog`. Solo existen en el archivo exportado y en `mongod.log`.
- El archivo `mongod.log` copiado después del reinicio (280 211 bytes) pesa aproximadamente el doble que la exportación de `getLog` (142 035 bytes): contiene la historia completa, no solo los eventos recientes.

## 5. Copia del archivo de bitácora del servidor

```powershell
Copy-Item "C:\Program Files\MongoDB\Server\7.0\log\mongod.log" evidencias\mongod-archivo.log
```

## 6. Archivos exportados y hashes

```text
Directorio: C:\Users\joser\Documents\LAB-02\evidencias

Mode     LastWriteTime            Length Name
----     -------------            ------ ----
-a----   08/11/2026 09:52 p. m.   142035 bitacora-mongod.log
-a----   08/11/2026 09:55 p. m.      358 hashes.sha256
-a----   08/11/2026 09:54 p. m.   280211 mongod-archivo.log
-a----   08/11/2026 09:49 p. m.     1542 system-profile-actividad3.json
-a----   08/11/2026 09:52 p. m.     1940 system-profile.json
```

Cálculo (formato compatible con `sha256sum -c`):

```powershell
Get-FileHash evidencias\*.json, evidencias\*.log -Algorithm SHA256 |
  ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } |
  Set-Content -Encoding ascii evidencias\hashes.sha256
```

```text
771ce0673a505185d4c574bb917fea04062c077023fcf10c3ca67a8f55ea1014  system-profile-actividad3.json
64f7e992c1cf811c40375bc49960ab39be40672da09d7a95de2164ba982b7d3c  system-profile.json
72ead97af53e3c6c06f5d449acb9d1cb9ac1e260041704b5bc2d53a3a3f3161e  bitacora-mongod.log
fff2ff2ec09c48a64ac33c4bc8ee0e533767f33c55f6debdbd25d3482390ff59  mongod-archivo.log
```

Para verificar la integridad más adelante: en Windows, `Get-FileHash <archivo> -Algorithm SHA256`; en Linux o Git Bash, `sha256sum -c hashes.sha256` desde la carpeta `evidencias`.

## Configuración persistente (no aplicada)

La guía indica que no es obligatorio aplicarla. **No se aplicó** para no dejar el servidor en modo `all` (nivel 2) con su costo de desempeño y su copia de datos personales. Para este despliegue (Windows, MSI), el fragmento equivalente en `C:\Program Files\MongoDB\Server\7.0\bin\mongod.cfg` sería:

```yaml
security:
  authorization: enabled
systemLog:
  destination: file
  path: C:\Program Files\MongoDB\Server\7.0\log\mongod.log
  logAppend: true
operationProfiling:
  mode: slowOp
  filter: '{ op: { $in: ["insert", "update", "remove"] } }'
```

Con `mode: slowOp` y el filtro de escrituras se obtendría el comportamiento de la Actividad 4 para **todas las bases** y desde el arranque. `systemLog` ya estaba configurado así por el instalador MSI.

## Preguntas

**1. Menciona tres formas en que la evidencia del perfilador o de la bitácora puede perderse sin que nadie la borre deliberadamente.**

1. **Sobrescritura de `system.profile`:** es una colección limitada de 1 MB; cuando se llena, los documentos más antiguos se reemplazan por los nuevos.
2. **Reinicio del servidor:** vacía la memoria de `getLog` y regresa el nivel del perfilador a 0 si se configuró con `setProfilingLevel()`; a partir de ahí las operaciones dejan de registrarse en silencio (observado en esta actividad).
3. **Gestión del archivo de bitácora:** rotación, falta de espacio en disco, `logAppend: false` (el archivo se reemplaza al arrancar) o una reinstalación del servidor que elimine la carpeta `log`.

Otras observadas en este laboratorio: vaciar `system.profile` para reconfigurar el perfilador antes de exportar (se perdió la primera ejecución de la Actividad 3) y el reinicio del contador de conexiones, que invalida la correlación por `ctx` entre arranques distintos.

**2. ¿Por qué el tamaño de 1 MB de `system.profile` es un problema de conservación y no solo de espacio?**

Porque el periodo que cubre la evidencia **no lo decide una política de retención, sino el volumen de operaciones**. En un sistema con mucha actividad, 1 MB puede representar minutos; cuando facturación reporta un cambio días después, la operación ya fue sobrescrita. Además, cualquiera que genere muchas operaciones (incluso un atacante, de forma intencional) puede **empujar fuera** la evidencia de una operación anterior. Una política de conservación necesita garantizar un tiempo mínimo, y una colección limitada no puede garantizarlo; por eso hay que exportar periódicamente.

**3. ¿Por qué `getLog` sirve para interpretar pero no para conservar?**

Sirve para **interpretar** porque devuelve los eventos en JSON desde `mongosh`, sin acceso al sistema de archivos del servidor, y permite filtrarlos por componente, mensaje o conexión, como se hizo en las Actividades 2, 5 y 6. No sirve para **conservar** porque:

- solo guarda los **1024 eventos más recientes**;
- vive **en memoria** y se vacía al reiniciar (de los eventos de la práctica quedaron 81 después del reinicio, todos del nuevo arranque);
- no tiene ningún mecanismo de integridad ni de retención.

Para conservar se necesita el archivo de `systemLog.path` con `logAppend: true`, copias fuera del servidor y hashes que permitan demostrar que no fue alterado.
