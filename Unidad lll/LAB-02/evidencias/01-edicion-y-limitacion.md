# Actividad 1 — Lo que no existe en esta edición

## Comandos ejecutados

```javascript
db.version()
db.adminCommand({ buildInfo: 1 }).modules
db.serverCmdLineOpts().parsed
```

## Resultado observado

```text
comercial> db.version()
7.0.45

comercial> db.adminCommand({ buildInfo: 1 }).modules
[]

comercial> db.serverCmdLineOpts().parsed
{
  config: 'C:\\Program Files\\MongoDB\\Server\\7.0\\bin\\mongod.cfg',
  net: { bindIp: '127.0.0.1', port: 27017 },
  security: { authorization: 'enabled' },
  service: true,
  storage: { dbPath: 'C:\\Program Files\\MongoDB\\Server\\7.0\\data' },
  systemLog: {
    destination: 'file',
    logAppend: true,
    path: 'C:\\Program Files\\MongoDB\\Server\\7.0\\log\\mongod.log'
  }
}
```

## Hallazgo durante la preparación

En una primera verificación, `serverCmdLineOpts().parsed` **no** mostraba la sección `security` y `mongosh` presentó la advertencia de arranque *"Access control is not enabled for the database. Read and write access to data and configuration is unrestricted"*. Se agregó la sección siguiente al archivo `mongod.cfg` y se reinició el servicio con `Restart-Service MongoDB`:

```yaml
security:
  authorization: enabled
```

Tras el reinicio, la advertencia desapareció y la configuración de arranque muestra `security: { authorization: 'enabled' }`. Este hallazgo es relevante: verificar la configuración **efectiva** con `serverCmdLineOpts()` es más confiable que suponer que un cambio en el archivo quedó aplicado.

## Interpretación

- `db.version()` confirma la versión **7.0.45**.
- `modules: []` indica que el binario **no** incluye el módulo `enterprise`. En MongoDB Enterprise este arreglo contendría `"enterprise"`. Por lo tanto, el servidor es **MongoDB Community Edition**.
- `serverCmdLineOpts().parsed` muestra la configuración con la que arrancó el servidor: archivo `mongod.cfg`, escucha solo en `127.0.0.1:27017`, autorización habilitada, ejecución como servicio de Windows y bitácora en archivo.
- **No aparece ninguna sección `auditLog`**, ni podría aparecer: la opción `auditLog` (y `--auditDestination`) solo existe en Enterprise y Atlas.

## Preguntas

**1. ¿Qué edición de MongoDB estás usando? ¿Qué evidencia lo demuestra?**

MongoDB **7.0.45 Community Edition**. La evidencia es `db.adminCommand({ buildInfo: 1 }).modules`, que devuelve un arreglo vacío `[]`; en Enterprise incluiría `"enterprise"`. Además, el paquete instalado es el MSI de la página de descarga de Community Server y la configuración de arranque no contiene opciones de auditoría.

**2. ¿A dónde escribe tu servidor su bitácora? ¿Cómo lo sabes?**

A un archivo: `C:\Program Files\MongoDB\Server\7.0\log\mongod.log`. Lo demuestra la sección `systemLog` de `serverCmdLineOpts().parsed`, con `destination: 'file'` y `path` apuntando a esa ruta. Como `logAppend: true`, al reiniciar el servicio los eventos nuevos se agregan al final del archivo en lugar de reemplazarlo. Por separado, el comando `getLog` permite consultar desde `mongosh` los 1024 eventos más recientes que el servidor mantiene en memoria.

**3. Según REF-U3-04, ¿qué cuatro categorías de eventos registraría la auditoría nativa?**

1. Cambios de esquema (DDL).
2. Eventos de conjuntos de réplicas y clústeres fragmentados.
3. Autenticación y autorización.
4. Operaciones CRUD (requiere `auditAuthorizationSuccess: true`).

**4. ¿Qué tendría que evaluar una organización antes de licenciar Enterprise o migrar a Atlas solo para obtener auditoría?**

- **Requisito real:** si una norma, contrato o auditoría interna exige registrar cambios de privilegios y accesos con atribución, o si basta con controles compensatorios documentados.
- **Costo:** licencia de Enterprise o costo mensual de Atlas (la auditoría requiere clústeres M10 o superiores), comparado con el riesgo que se cubre.
- **Ubicación y soberanía de los datos:** Atlas implica alojar datos personales (como el RFC) con un tercero y en una región determinada.
- **Esfuerzo y riesgo de la migración:** compatibilidad de versión, ventana de mantenimiento, pruebas de la aplicación y plan de reversión.
- **Costo operativo de la auditoría:** impacto en desempeño, volumen de eventos, almacenamiento, retención y quién revisa los registros; auditar sin revisar no aporta control.
- **Alternativas:** controles compensatorios en Community (perfilador, bitácora de `mongod`, instantáneas de privilegios, restricción de quién tiene rol `root` o `userAdmin`) y sus límites documentados.

## Conclusión

La auditoría nativa de MongoDB **no está disponible** en este servidor porque es Community Edition. En este laboratorio solo se usarán los mecanismos que sí existen: el perfilador (`system.profile`) y la bitácora de `mongod`. Ninguno de los dos se presentará como equivalente a la auditoría nativa.
