# Evidencia 07 — Comparación: protección en reposo vs. en tránsito

## Objetivo
Comparar los mecanismos de protección según dónde se encuentra la información (almacenada, en transmisión, en respaldos o como clave) y elegir el apropiado en cada situación.

## Comando o procedimiento
Análisis conceptual apoyado en lo practicado en las evidencias 01 a 04. No requiere comandos.

## Resultado obtenido
| Situación | Mecanismo apropiado | ¿Qué protege? |
|---|---|---|
| Contraseña de usuario | Hash con sal usando una función para contraseñas (Argon2id o bcrypt). | Evita guardar la contraseña original; protege las credenciales almacenadas. |
| RFC almacenado en una tabla | Cifrado en reposo con clave administrada de forma segura, más control de acceso y enmascaramiento. | Confidencialidad del RFC frente a accesos no autorizados. |
| Consulta enviada del cliente al servidor | TLS, verificando la identidad del servidor (`verify-full`). | Datos en tránsito contra lectura y modificación por terceros. |
| Respaldo de una base de datos | Cifrado del archivo de respaldo y almacenamiento seguro de la clave. | La información respaldada, aunque el archivo se copie o se pierda. |
| Clave criptográfica | Gestor de secretos o KMS con acceso estricto. | La clave contra divulgación, robo y uso no autorizado. |

## Análisis
La protección en reposo cubre tablas, archivos y respaldos; la protección en tránsito cubre la comunicación. Ninguna sustituye a la otra: un dato cifrado en la tabla viaja expuesto si no hay TLS, y una conexión con TLS no protege un respaldo robado. Las contraseñas usan hash (no se recuperan) y los datos que deben leerse de nuevo usan cifrado reversible. Todo esquema criptográfico depende de proteger las claves.

## Conclusión
La protección debe elegirse según el estado del dato (almacenado, transmitido, respaldado o clave) y combinarse en capas. Hash y cifrado resuelven problemas distintos, TLS protege el canal y un gestor de claves protege lo que sostiene a todos los demás mecanismos.
