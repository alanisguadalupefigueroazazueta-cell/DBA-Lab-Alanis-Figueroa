# Actividad 8 — Derecho de cancelación y ciclo de vida

## Objetivo

Identificar los lugares donde pueden existir datos personales relacionados con un cliente y analizar por qué eliminar un registro de la tabla principal no garantiza que toda la información haya desaparecido de la organización.

## Procedimiento

Se analizó el escenario en el que el área responsable ha autorizado una solicitud de cancelación de datos personales. Antes de ejecutar cualquier eliminación, es necesario identificar las tablas relacionadas, los respaldos, las réplicas y los demás sistemas que podrían conservar copias de la información.

Se propone el siguiente mapa del ciclo de vida de los datos:

```text
                    clientes
                       |
          +------------+-------------+
          |            |             |
      Respaldos     Réplicas       Reportes
          |            |             |
     Copias de      Copias en      Archivos con
     seguridad      otros nodos    información personal
          |
     Exportaciones
          |
     Archivos CSV, Excel o PDF

                       |
                Sistemas externos
                       |
             Aplicaciones o servicios
             que recibieron los datos
```

### Elementos que deben revisarse

**1. Tablas relacionadas:** comprobar si existen otras tablas que contengan información del cliente, utilizando su identificador u otros datos relacionados.

**2. Respaldos:** identificar las copias de seguridad que podrían conservar el registro eliminado. Su tratamiento debe seguir la política de respaldos, retención y cancelación de la organización.

**3. Réplicas:** comprobar si la información se encuentra en servidores secundarios y verificar cómo se propagan los cambios o eliminaciones.

**4. Registros de auditoría:** revisar si los registros conservan datos personales y determinar qué información debe mantenerse por razones de seguridad, trazabilidad u obligaciones aplicables.

**5. Copias utilizadas para analítica:** comprobar si los datos se copiaron a tablas, almacenes de datos o conjuntos de análisis. Si los datos fueron agregados o seudonimizados, evaluar si todavía permiten identificar a la persona.

**6. Archivos exportados:** identificar archivos CSV, Excel, PDF u otros documentos que puedan contener información del cliente.

**7. Sistemas externos:** comprobar si la información se compartió con proveedores, aplicaciones u otros servicios y determinar qué acciones corresponden para atender la solicitud.

## Pregunta

### ¿Por qué eliminar un registro de una tabla no necesariamente significa que toda la información relacionada con esa persona haya desaparecido de la organización?

Porque los datos personales pueden existir en diferentes lugares, además de la tabla principal. Por ejemplo, pueden permanecer en respaldos, réplicas, reportes, archivos exportados, registros de auditoría, bases de datos analíticas o sistemas externos. Eliminar un registro de `clientes` no garantiza que todas esas copias se eliminen automáticamente.

Por esta razón, la organización debe identificar dónde se encuentran los datos, revisar las relaciones entre las tablas y coordinar las acciones necesarias con las áreas responsables. También debe considerar las políticas de conservación y las obligaciones legales aplicables, ya que ciertos registros pueden necesitar conservarse durante un periodo determinado. La cancelación debe atenderse de manera controlada y documentada, sin eliminar información indiscriminadamente.

## Resultado

Se identificaron siete elementos que deben revisarse antes de realizar una eliminación: tablas relacionadas, respaldos, réplicas, registros de auditoría, copias analíticas, archivos exportados y sistemas externos.

## Análisis

La cancelación de datos personales requiere considerar todo su ciclo de vida, desde su almacenamiento inicial hasta las copias que puedan haberse generado o compartido. Una eliminación ejecutada únicamente en la tabla principal puede dejar información residual y provocar que la organización no atienda completamente la solicitud.

## Conclusión

Antes de eliminar datos personales, la organización debe localizar sus posibles copias y definir las acciones necesarias para cada sistema. El DBA contribuye identificando las ubicaciones técnicas y ejecutando únicamente los cambios autorizados. La coordinación entre las áreas de bases de datos, privacidad y cumplimiento permite gestionar la cancelación de forma segura, controlada y documentada.
