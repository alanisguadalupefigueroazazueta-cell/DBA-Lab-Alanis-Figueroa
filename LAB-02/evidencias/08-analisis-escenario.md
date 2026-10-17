# Evidencia 08 — Análisis de un escenario de seguridad

## Objetivo
Identificar riesgos en un escenario donde se almacenan contraseñas y RFC en texto claro, se usan claves en archivos SQL, las conexiones no validan al servidor y los respaldos no están protegidos, y proponer mecanismos de protección.

## Comando o procedimiento
Análisis del escenario y de los hallazgos de las evidencias 01 a 04. Sin comandos.

## Resultado obtenido

**Riesgos principales**
- Contraseñas en texto claro: lectura directa y posible reutilización en otras cuentas.
- RFC en texto claro: dato personal útil para fraude o suplantación de identidad.
- Conexiones sin validación del servidor: intercepción o suplantación del servidor.
- Claves en archivos SQL: exposición al compartir archivos o subirlos a un repositorio.
- Respaldos sin protección: una copia robada revela todo sin pasar por los permisos de la base.

**Mecanismos propuestos**
| Elemento | Mecanismo | Justificación |
|---|---|---|
| Nombre | Control de acceso y, si hace falta, enmascaramiento. | Limita la exposición de datos personales. |
| Correo electrónico | Control de acceso, enmascaramiento y cifrado según el riesgo. | Reduce la exposición de datos de contacto. |
| Contraseña | Hash con sal (Argon2id o bcrypt). | No se guarda la original y se puede verificar. |
| RFC | Cifrado en reposo, control de acceso y enmascaramiento en reportes. | Protege la confidencialidad. |
| Información financiera | Cifrado en reposo, acceso estricto y auditoría. | Reduce el riesgo de exposición económica. |
| Claves criptográficas | KMS o gestor de secretos, permisos restringidos y rotación. | Evita claves en SQL o repositorios. |
| Conexiones | TLS con `sslmode=verify-full`. | Cifra y verifica la identidad del servidor. |
| Respaldos | Cifrado, almacenamiento seguro, acceso restringido y pruebas de recuperación. | Una copia obtenida sin permiso no revela su contenido. |

## Análisis
- **Problema más crítico:** las contraseñas en texto claro, porque con solo leer la tabla se obtienen credenciales directamente utilizables, incluso en servicios externos. Las claves expuestas y los respaldos sin cifrar son igualmente graves porque abren grandes volúmenes de datos.
- **¿Usuarios y permisos correctos eliminan estos riesgos?** No. Los permisos limitan quién consulta la base, pero no protegen contraseñas en claro, no cifran el tráfico, no evitan que una clave se publique y no cubren un respaldo copiado fuera de la base. Se requieren controles complementarios.

## Conclusión
La seguridad de una base de datos exige varias capas: control de acceso, hash de contraseñas, cifrado en reposo y en tránsito, gestión segura de claves, respaldos protegidos y auditoría. Corregir primero contraseñas y claves expuestas reduce más rápido el riesgo.
