# Evidencia 10 — Política mínima de protección de claves criptográficas

## Objetivo
Establecer reglas básicas para proteger las claves criptográficas de sistemas y bases de datos, evitando su pérdida, divulgación o uso no autorizado.

## Comando o procedimiento
Redacción de una política con ocho reglas, basada en los problemas observados en las evidencias 02, 03 y 08. Sin comandos.

## Resultado obtenido

1. **Generación segura.** Usar herramientas o bibliotecas criptográficas confiables con aleatoriedad segura. No derivar claves de contraseñas personales, fechas ni nombres.
2. **Almacenamiento protegido.** Guardar las claves en un gestor de claves o de secretos autorizado. Prohibido incluir claves reales en SQL, código, documentos o GitLab.
3. **Acceso restringido.** Conceder acceso solo a usuarios y servicios que lo necesiten, y revisar los permisos periódicamente.
4. **Rotación periódica.** Reemplazar las claves según un calendario por nivel de riesgo y de inmediato ante sospecha de exposición, planificando la rotación para no perder acceso a datos cifrados.
5. **Respaldo seguro.** Respaldar las claves necesarias para recuperar información de forma independiente al respaldo de la base, cifradas, con acceso restringido y con pruebas de recuperación.
6. **Revocación.** Revocar o deshabilitar claves comprometidas o ya no autorizadas, generar nuevas y evaluar si hay que volver a cifrar la información afectada.
7. **Actuación ante exposición accidental.** Reportar el incidente, restringir el acceso y revocar o reemplazar la clave. Borrarla del archivo no basta: revisar el historial del repositorio y determinar el alcance.
8. **Eliminación segura.** Eliminar las claves con el procedimiento autorizado, tras comprobar que no se necesitan para recuperar respaldos ni descifrar información que deba conservarse.

## Análisis
Cada regla responde a un fallo concreto observado: claves en consultas (reglas 1 y 2), acceso amplio a archivos (3), claves comprometidas en repositorios (6 y 7) y pérdida de datos por perder la clave (4, 5 y 8). La gestión de claves es tan importante como el algoritmo: un algoritmo robusto no sirve si la clave se filtra o se pierde.

## Conclusión
La protección de claves garantiza tanto la confidencialidad (nadie ajeno descifra) como la disponibilidad (la organización siempre puede descifrar). La política debe complementarse con revisiones periódicas y un procedimiento claro de respuesta a incidentes.
