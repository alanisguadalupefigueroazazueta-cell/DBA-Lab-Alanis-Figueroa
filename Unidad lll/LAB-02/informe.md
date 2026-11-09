# Informe — LAB-02: Trazabilidad en MongoDB Community

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos · Unidad III
---

## 1. Despliegue, edición y limitación

El servidor se desplegó con el instalador MSI oficial de **MongoDB 7.0.45 Community** en Windows, como servicio (`MongoDB`), con `mongosh` 2.14.1 instalado por separado. La autorización se habilitó agregando `security.authorization: enabled` a `mongod.cfg` y reiniciando el servicio. Una primera verificación mostró que el cambio **no estaba aplicado** (advertencia *Access control is not enabled* y ausencia de la sección `security`); se corrigió y se comprobó con `db.serverCmdLineOpts().parsed`. Esto confirmó que la configuración efectiva debe verificarse, no suponerse.

**Qué no existe en Community:** la **auditoría nativa** (opciones `auditLog` y `--auditDestination`), que solo está en MongoDB Enterprise y Atlas (M10 o superior). Según la documentación registraría cambios de esquema, eventos de réplicas y fragmentación, autenticación y autorización, y operaciones CRUD.

**Cómo se verificó:** `db.adminCommand({ buildInfo: 1 }).modules` devuelve `[]` (en Enterprise incluiría `"enterprise"`), y la configuración de arranque no contiene ninguna opción de auditoría. La bitácora se escribe en archivo (`systemLog.destination: file`, `path: ...\7.0\log\mongod.log`, `logAppend: true`).

## 2. Perfilador

**Configuración.** El perfilador está apagado por defecto (`was: 0`). Se probó:

- **Nivel 2** (`db.setProfilingLevel(2)`): registra todas las operaciones de la base `comercial`.
- **Nivel 1 con filtro** `{ op: { $in: ["insert", "update", "remove"] } }`: solo escrituras. Con filtro, `slowms` y `sampleRate` dejan de aplicarse.
- `setProfilingLevel` devuelve en `was` el nivel **anterior**; el vigente se lee con `getProfilingStatus()`.

**Interpretación.** Con el perfilador apagado, la modificación del RFC de la Actividad 2 **no dejó rastro** (`system.profile` vacío, 0 eventos en la bitácora). En nivel 2 quedaron registradas la consulta, la actualización y la eliminación de `app_ventas@comercial`, con cliente `127.0.0.1`, aplicación `app-ventas-web`, momento, criterio (`q`) y valor nuevo (`u`). No queda el **valor anterior** ni el contenido de un documento **eliminado**. El perfilador registra la operación **intentada**: en una ejecución repetida aparecieron un `update` con `nModified: 0` y un `remove` con `ndeleted: 0`, por lo que deben leerse los contadores y no solo `op`.

**Costo.** El nivel 2 agrega escrituras por cada operación (impacto en desempeño), llena rápido la colección limitada de 1 MB (menor retención) y copia en texto claro los filtros de las consultas, que pueden contener datos personales. El filtro de escrituras reduce volumen, costo y exposición, a cambio de perder la trazabilidad de lecturas y la detección de operaciones lentas.

## 3. Bitácora de `mongod`

**Dónde se escribe.** En el archivo `C:\Program Files\MongoDB\Server\7.0\log\mongod.log`, configurado por el instalador. Desde `mongosh`, `getLog` devuelve los 1024 eventos más recientes en memoria, en JSON (`t`, `s`, `c`, `id`, `ctx`, `msg`, `attr`).

**Accesos.** La bitácora registra:

- Éxitos: `Successfully authenticated`, id 5286306, `result: 0`, con usuario, base, cliente (IP y puerto), conexión y `appName`.
- Fallos: `Failed to authenticate`, id 5286307, con la causa: `storedKey mismatch` (código 18, contraseña incorrecta) o `UserNotFound` (código 11). El cliente recibe en ambos casos el mismo `Authentication failed.` para no revelar qué usuarios existen. Un intento puede generar dos líneas (autenticación especulativa y normal): se cuentan intentos, no líneas.
- `appName` lo declara el cliente y no se verifica (los intentos fallidos aparecieron como `mongosh 2.14.1`).

Se observó una correlación exacta entre fuentes: la autenticación de `app_ventas` en `conn21` (21:31:31.026, UTC-07:00) coincide al milisegundo con el `update` registrado en `system.profile` (04:31:31.026Z).

**Cambios de configuración.** `Profiler settings changed` registra estado anterior, nuevo y base, pero **no el usuario**. Se atribuyó a `admin@admin` correlacionando el `ctx` (`conn3`) con el evento `Successfully authenticated` de la misma conexión. La correlación solo es válida dentro de una misma ejecución del servidor, porque los números de conexión se reinician al arrancar.

## 4. Privilegios

**Evidencia disponible: ninguna.** Con el perfilador en nivel 2, `grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])` no dejó rastro ni en `system.profile` ni en la bitácora (0 y 0).

**Control compensatorio.** Instantáneas de privilegios en `auditoria.instantaneas_privilegios` (momento, quién toma la instantánea y roles de cada usuario). Al comparar dos instantáneas se detectó que `app_ventas` pasó de `readWrite` a `readWrite` + `dbAdmin` entre 04:41:52.602Z y 04:42:24.057Z.

**Límite.** La instantánea responde **qué** cambió y **en qué intervalo**, pero no **quién** ni **cuándo exactamente**. No detecta cambios que se otorgan y revocan entre dos instantáneas (la revocación posterior no quedó evidenciada), y se guarda en el mismo servidor, donde un usuario con privilegios podría alterarla. **No equivale a auditoría.**

## 5. Conservación

**Riesgos observados en la práctica:**

- `system.profile` se vació en la Actividad 4 antes de exportarlo, y la primera ejecución de la Actividad 3 se perdió; hubo que repetirla.
- Tras reiniciar, el perfilador volvió a **nivel 0** sin aviso, por lo que dejaría de registrar modificaciones; los 7 documentos ya registrados sí se conservaron.
- La memoria de `getLog` quedó con 81 eventos, todos del nuevo arranque; los eventos de las actividades anteriores solo existen en el archivo y en la exportación.
- `system.profile` es una colección limitada de 1 MB: su retención depende del volumen de operaciones, no de una política.

**Exportación realizada** (antes del reinicio, en UTF-8 con `fs.writeFileSync`): `system-profile.json`, `system-profile-actividad3.json` y `bitacora-mongod.log`; después, copia completa de `mongod.log` (`mongod-archivo.log`). Se calcularon los hashes SHA-256 de los cuatro archivos en `hashes.sha256`.

## 6. Comparación (resumen de la Actividad 9)

| Evento | PostgreSQL (LAB-01) | MongoDB Community | Enterprise/Atlas |
|---|---|---|---|
| Acceso exitoso / fallido | Sí / Sí | Sí / Sí (bitácora) | Documentado, no practicado |
| Cambio de privilegios | Sí | **No** (solo detección con instantáneas) | Documentado, no practicado |
| Cambio de estructura | Sí | Parcial, no verificado | Documentado, no practicado |
| Modificación de datos | Sí | Parcial (solo con perfilador activo) | Documentado, no practicado |
| Valor anterior | Sí (disparador) | **No** | No (registra el comando, no la imagen previa) |
| Lectura de datos sensibles | Parcial | Parcial (solo nivel 2) | Documentado, no practicado |
| Cambio de configuración del registro | Sí | Sí (atribución indirecta por `ctx`) | Documentado, no practicado |

Community es fuerte en accesos y en cambios de configuración del perfilador, parcial en modificaciones y lecturas, y no cubre privilegios ni valor anterior.

## 7. Recomendación

**Caso:** una organización necesita auditar cambios de privilegios en MongoDB.

**Recomendación:**

1. **Si la atribución es un requisito** (norma, contrato o auditoría interna exige saber quién otorgó o retiró permisos): usar **MongoDB Enterprise o Atlas (M10 o superior)** con auditoría nativa, filtrada a eventos de autenticación y gestión de usuarios y roles, enviada a archivo o *syslog* y centralizada fuera del servidor con retención definida y control de integridad.
2. **Mientras tanto, o si se decide permanecer en Community**, documentar el riesgo como aceptado y aplicar controles compensatorios combinados:
   - Reducir al mínimo las cuentas con `root`, `userAdmin` o `userAdminAnyDatabase`; cuentas **nominales** (una por persona), nunca compartidas.
   - Cambios de privilegios solo mediante **gestión de cambios** (solicitud, aprobación, ventana), de modo que exista un registro fuera de la base que diga quién pidió y quién ejecutó.
   - Instantáneas **automáticas y frecuentes**, comparadas por un proceso que alerte ante diferencias, guardadas por una cuenta de servicio con permiso de solo inserción y copiadas fuera del servidor con su hash.
   - Bitácora de `mongod` en archivo con `logAppend: true`, rotación y copia centralizada, para conservar accesos y cambios de configuración.
   - Perfilador configurado de forma **persistente** (`operationProfiling` en `mongod.cfg`) con filtro de escrituras, para que un reinicio no lo apague.

**Hechos verificados en este laboratorio:** Community no tiene auditoría nativa (`modules: []`); `grantRolesToUser` no deja rastro en el perfilador (nivel 2) ni en la bitácora; las instantáneas detectan el cambio pero no su autor; la bitácora registra accesos y cambios del perfilador; el nivel del perfilador no sobrevive a un reinicio si se configura con `setProfilingLevel`.

**Supuestos (no verificados aquí):** que la auditoría de Enterprise/Atlas registra `grantRolesToUser` con usuario y momento (proviene de la documentación); el costo de licencia o de Atlas y si se justifica frente al riesgo; el impacto real en desempeño de la auditoría o del perfilador en producción; la frecuencia adecuada de instantáneas, que depende del volumen de cambios y de la ventana de detección aceptable para la organización.

---

## Preguntas de reflexión

**1. ¿Por qué el perfilador no debe presentarse como un mecanismo de auditoría de seguridad?**

Porque fue diseñado para **analizar desempeño**, no para producir evidencia. En este laboratorio se comprobó que: está apagado por defecto y vuelve a apagarse con un reinicio; se configura por base de datos; su colección limitada de 1 MB sobrescribe la evidencia antigua; cualquiera con permisos suficientes (incluido el rol `dbAdmin`) puede vaciarla; no registra cambios de privilegios aun en nivel 2; y no conserva valores anteriores. Una auditoría debe ser completa, persistente, protegida contra alteración y con retención garantizada; el perfilador no cumple ninguna de esas condiciones. Presentarlo como auditoría daría a la organización una falsa sensación de control.

**2. ¿Por qué el perfilador sí aporta trazabilidad aunque no sea auditoría?**

Porque, mientras está activo, deja registro de **quién** (usuario autenticado), **desde dónde** (cliente), **con qué aplicación** (`appName`), **cuándo** (`ts`), **qué operación** y **sobre qué documento** se ejecutó, incluido el valor nuevo. Permitió responder, para la Actividad 3, que la cuenta `app_ventas@comercial` cambió el RFC a `GAMA780912XYZ` a las 04:49:27 UTC, y se correlacionó al milisegundo con la autenticación registrada en la bitácora. Trazabilidad es poder seguir el rastro de una operación; el perfilador lo permite dentro de sus límites, aunque no ofrezca las garantías de una auditoría.

**3. ¿Qué riesgo introduce el nivel 2 al registrar filtros de consultas que pueden contener datos personales?**

Crea una **copia no controlada de datos personales**. Si una consulta busca por RFC, correo o teléfono, ese valor queda en texto claro en `system.profile`, una colección que no tiene las mismas restricciones de acceso, cifrado, minimización ni retención que la colección original, y que puede leer cualquiera con permisos sobre la base o sobre esa colección. Además, se exporta como evidencia (como `system-profile.json`) y puede terminar en repositorios o respaldos. Esto contradice principios de protección de datos personales como minimización y finalidad. Por eso conviene usar filtros que excluyan lecturas, restringir quién puede leer `system.profile` y tratar sus exportaciones como información sensible.

**4. ¿Qué diferencia hay entre detectar un cambio y atribuirlo a alguien?**

**Detectar** es saber que algo cambió: las instantáneas mostraron que `app_ventas` ganó el rol `dbAdmin` entre dos momentos. **Atribuir** es poder demostrar **quién** lo hizo, **cuándo** y **desde dónde**, con evidencia que lo vincule a una identidad: eso es lo que no fue posible, porque ni el perfilador ni la bitácora registraron el comando. Detectar permite reaccionar (revertir, investigar); atribuir permite rendir cuentas y sostener una conclusión ante Dirección o ante una auditoría. Incluso la atribución tiene grados: el perfilador identifica una **cuenta** (`app_ventas@comercial`), no a la **persona** que la usó.

**5. ¿Por qué reconocer una limitación técnica es parte del trabajo profesional del DBA?**

Porque las decisiones de la organización (aceptar un riesgo, invertir en una licencia, cambiar un proceso) dependen de que el DBA diga con precisión **qué puede demostrar y qué no**. Afirmar que Community "audita" cambios de privilegios llevaría a creer que existe un control que no existe, y el error se descubriría justo durante un incidente, cuando ya no hay remedio. Responder "No hay evidencia con esta edición", explicar el motivo técnico y proponer controles compensatorios con sus límites es lo que permite gestionar el riesgo con honestidad. También protege al propio DBA: una conclusión respaldada por evidencia verificable es defendible; una suposición presentada como hecho no lo es.
