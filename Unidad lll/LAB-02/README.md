# LAB-02 — Trazabilidad en MongoDB Community

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos

## Despliegue del servidor (Anexo A)

| Elemento | Valor |
|---|---|
| Forma de despliegue | **Instalación nativa en Windows** con el instalador MSI oficial |
| Edición y versión | **MongoDB 7.0.45 Community** (`db.version()` = `7.0.45`, `buildInfo.modules` = `[]`) |
| Cliente | `mongosh` 2.14.1 (instalado aparte con `winget install MongoDB.Shell`) |
| Servicio de Windows | `MongoDB` ("MongoDB Server (MongoDB)"), cuenta Network Service |
| Archivo de configuración | `C:\Program Files\MongoDB\Server\7.0\bin\mongod.cfg` |
| Datos | `C:\Program Files\MongoDB\Server\7.0\data` |
| Bitácora | Archivo `C:\Program Files\MongoDB\Server\7.0\log\mongod.log` (`destination: file`, `logAppend: true`) |
| Red | `bindIp: 127.0.0.1`, puerto `27017` |
| Control de acceso | `security.authorization: enabled` |

### Pasos de despliegue

1. Se descartó una instalación previa de MongoDB 9.0 (versión distinta a la requerida y sin servicio de Windows) y se instaló **MongoDB 7.0.45 Community** (MSI, tipo *Complete*, con la opción **Install MongoD as a Service**).
2. Se instaló `mongosh`, que desde MongoDB 6.0 no viene incluido en el instalador del servidor.
3. Se habilitó la autorización agregando a `mongod.cfg` (PowerShell como administrador):

   ```powershell
   Add-Content -Path "C:\Program Files\MongoDB\Server\7.0\bin\mongod.cfg" -Value "`nsecurity:`n  authorization: enabled"
   Restart-Service MongoDB
   ```

4. Se verificó la configuración efectiva con `db.serverCmdLineOpts().parsed`. En la primera verificación la sección `security` no estaba aplicada (y `mongosh` mostró la advertencia *Access control is not enabled*); tras el reinicio quedó `security: { authorization: 'enabled' }`. Detalle en `evidencias/01-edicion-y-limitacion.md`.
5. Se crearon los usuarios `admin` (rol `root`, base `admin`) y `app_ventas` (rol `readWrite` en `comercial`) mediante la excepción de *localhost*, y se cargaron los cinco clientes de la sección 6.3.

Reinicio del servicio en este despliegue: `Restart-Service MongoDB` desde **PowerShell como administrador**.

## Estructura

```text
LAB-02/
├── README.md
├── evidencias/
│   ├── 01-edicion-y-limitacion.md
│   ├── 02-incidente-sin-perfilado.md
│   ├── 03-perfilador.md
│   ├── 04-filtro.md
│   ├── 05-accesos-mongod.md
│   ├── 06-correlacion.md
│   ├── 07-privilegios-control-compensatorio.md
│   ├── 08-conservacion.md
│   ├── 09-comparacion.md
│   ├── 10-respuesta-direccion.md
│   ├── system-profile.json              ← exportado en la Actividad 8
│   ├── system-profile-actividad3.json   ← exportación adicional de la Actividad 3
│   ├── bitacora-mongod.log              ← getLog exportado antes del reinicio
│   ├── mongod-archivo.log               ← copia del archivo completo de bitácora
│   └── hashes.sha256
├── scripts/
│   └── comandos-mongosh.js
└── informe.md
```

`system-profile-actividad3.json` y `mongod-archivo.log` son adicionales a la estructura mínima de la guía: el primero conserva la evidencia completa de la Actividad 3 y el segundo la historia completa de la bitácora, no solo los 1024 eventos que conserva `getLog`.

## Adaptaciones por usar Windows PowerShell

- Dentro de `--eval '...'` las cadenas de JavaScript se escriben con comillas simples duplicadas (`''GAMA780912XXX''`), porque Windows PowerShell 5.1 elimina las comillas dobles internas al invocar programas externos.
- Las exportaciones se escriben con `require('fs').writeFileSync(...)` desde `mongosh` en lugar de `>`, porque `>` en Windows PowerShell 5.1 guarda en UTF-16.
- Los hashes se calcularon con `Get-FileHash -Algorithm SHA256` y se guardaron en formato compatible con `sha256sum -c`.

## Integridad de las evidencias

```text
771ce0673a505185d4c574bb917fea04062c077023fcf10c3ca67a8f55ea1014  system-profile-actividad3.json
64f7e992c1cf811c40375bc49960ab39be40672da09d7a95de2164ba982b7d3c  system-profile.json
72ead97af53e3c6c06f5d449acb9d1cb9ac1e260041704b5bc2d53a3a3f3161e  bitacora-mongod.log
fff2ff2ec09c48a64ac33c4bc8ee0e533767f33c55f6debdbd25d3482390ff59  mongod-archivo.log
```

Verificación: `Get-FileHash evidencias\<archivo> -Algorithm SHA256` (Windows) o `cd evidencias && sha256sum -c hashes.sha256` (Linux, Git Bash).

## Credenciales

Las contraseñas de práctica se sustituyeron por `<REDACTED>` en las evidencias y en el script.

## Resultado principal

MongoDB 7.0.45 Community **no tiene auditoría nativa**. Con el perfilador y la bitácora de `mongod` se obtuvo trazabilidad de accesos, de modificaciones (con el perfilador activo) y de cambios de configuración del perfilador, pero **no** del valor anterior de los datos ni de quién cambia privilegios. Ver `informe.md`.
