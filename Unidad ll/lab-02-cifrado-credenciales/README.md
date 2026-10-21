# LAB-02 — Cifrado y gestión de credenciales en PostgreSQL

**Estudiante:** Alanis Guadalupe Figueroa Zazueta · Universidad Autónoma de Sinaloa (UAS)
**Entorno:** PostgreSQL 15.19 (FIC Labs), pgAdmin 4 y `psql` 17.11. Todos los datos, usuarios y claves usados son ficticios.

## Estructura

| Carpeta / archivo | Contenido |
|---|---|
| `sql/01-credenciales.sql` | Contraseñas en texto claro vs. hash bcrypt y verificación |
| `sql/02-cifrado-datos.sql` | Cifrado y descifrado del RFC con `pgcrypto` |
| `sql/03-verificacion-tls.sql` | Consultas de verificación de TLS |
| `evidencias/01-credenciales.md` | Protección de credenciales |
| `evidencias/02-cifrado-datos.md` | Cifrado de datos sensibles |
| `evidencias/03-gestion-claves.md` | Mala práctica con claves y revisión de secretos |
| `evidencias/04-tls.md` | TLS, `pg_stat_ssl`, `psql` y `sslmode` |
| `evidencias/07-comparacion.md` | Protección en reposo vs. en tránsito |
| `evidencias/08-analisis-escenario.md` | Análisis de un escenario de seguridad |
| `evidencias/10-politica-claves.md` | Política mínima de protección de claves |

---

## 1. Introducción
El laboratorio aborda cómo evitar que una base de datos PostgreSQL exponga información sensible por tres vías: credenciales guardadas en texto claro, datos personales sin cifrar y comunicaciones sin protección. También trata el problema que sostiene todo lo demás: dónde y cómo se guardan las claves criptográficas. Se trabajó con datos ficticios.

## 2. Protección de credenciales
- **Texto claro:** la contraseña se guarda tal cual (`usuarios_insegura`); quien lea la tabla la obtiene.
- **Hash:** resultado unidireccional calculado con `crypt()` y `gen_salt('bf')` (bcrypt). Incluye una sal aleatoria, por lo que la misma contraseña produce hashes distintos. No se puede revertir; se verifica recalculando con la sal almacenada (`true` con `Password123`, `false` con `OtraPassword`).
- **Cifrado:** transformación reversible con una clave (`pgp_sym_encrypt` / `pgp_sym_decrypt`). Sirve para datos que deben recuperarse, no para contraseñas.

Detalle en [`evidencias/01-credenciales.md`](evidencias/01-credenciales.md).

## 3. Protección de datos sensibles
Se protegió el **RFC** (dato personal que sirve para identificar a una persona y facilitar fraude o suplantación) cifrándolo en una columna `BYTEA` con `pgp_sym_encrypt()`. Al consultar la tabla solo se ve `[binary data]`; con la clave correcta se recupera el valor. El nombre se dejó sin cifrar y debe protegerse con control de acceso y enmascaramiento. Detalle en [`evidencias/02-cifrado-datos.md`](evidencias/02-cifrado-datos.md).

## 4. TLS
TLS protege los datos mientras viajan entre cliente y servidor: cifrado, integridad y (según `sslmode`) autenticación del servidor. Sin TLS, quien observe la red puede leer o alterar consultas y resultados.

En PostgreSQL se verificó: `SHOW ssl;` → `off`; `pg_stat_ssl` para la sesión → `ssl = false`, sin versión ni cifrador; y `psql ... sslmode=require` → `server does not support SSL, but SSL was required`. Es decir, el servidor del laboratorio no admite TLS. Detalle en [`evidencias/04-tls.md`](evidencias/04-tls.md).

## 5. Gestión de claves
Las claves no deben almacenarse junto con los scripts porque cualquiera con acceso al archivo (o a su copia, historial de Git, captura o respaldo) podría descifrar los datos. Si se sube a un repositorio, la clave permanece en el historial aunque se borre después. Las claves deben estar en un gestor de secretos o KMS, con acceso restringido, rotación y respaldo protegido. Se revisó el repositorio con `Select-String` antes de publicar y se redactó una política mínima. Detalle en [`evidencias/03-gestion-claves.md`](evidencias/03-gestion-claves.md) y [`evidencias/10-politica-claves.md`](evidencias/10-politica-claves.md).

## 6. Resultados
- Contraseña en claro visible en `usuarios_insegura`; en `usuarios_segura` solo se guarda un hash bcrypt (`$2a$06$…`).
- Dos hashes distintos para la misma contraseña (sal aleatoria).
- Verificación de contraseña: `true` / `false` según corresponda.
- RFC almacenado como `BYTEA` cifrado y recuperado con `pgp_sym_decrypt()`.
- TLS: `ssl = off`; la sesión no usa TLS; `sslmode=require` rechazado por el servidor.
- Revisión de secretos: coincidencias solo en documentación y nombres de campos de LAB-01 (tokens de seudonimización), no credenciales reales.

## 7. Problemas encontrados
- **Servidor sin SSL:** no fue posible realizar una conexión cifrada ni probar `verify-ca` / `verify-full`; se requeriría que el administrador habilite SSL.
- **Errores al usar `psql`:** se escribió `-u` en lugar de `-U` (`unrecognized option: u`) y `/q` en lugar de `\q` (`syntax error at or near "/"`); se corrigieron.
- **Clave en la consulta:** para la práctica se usó una clave ficticia escrita en la consulta, que es justo la mala práctica a evitar; el archivo de demostración se eliminó antes de la entrega y el script `02-cifrado-datos.sql` pide la clave con una variable de `psql`.
- **Falsos positivos** en la búsqueda de secretos por palabras clave (revisión manual necesaria). Queda pendiente confirmar que las cadenas de conexión no incluyan credenciales.
- Costo bcrypt por defecto bajo (`$2a$06$`); en producción debe aumentarse.

## 8. Conclusiones
Aprendí que hash, cifrado y TLS resuelven problemas distintos y que ninguno sustituye al control de acceso ni a una buena gestión de claves. En un entorno productivo aplicaría:
- hash de contraseñas con Argon2id o bcrypt con costo alto;
- cifrado de columnas o del almacenamiento para datos sensibles, con enmascaramiento y mínimo privilegio;
- TLS 1.2 o superior con certificado y `sslmode=verify-full`;
- claves en un KMS o gestor de secretos, con rotación, revocación y respaldo propio;
- respaldos cifrados con pruebas de restauración;
- escaneo de secretos antes de cada *push* y auditoría de accesos.

---

## Preguntas de reflexión

**1. ¿Por qué una contraseña no debe almacenarse como texto claro?**
Porque cualquier persona o proceso con lectura sobre la tabla, un respaldo o un log obtiene la contraseña directamente. Como muchos usuarios la reutilizan, el daño se extiende a otros servicios. Debe guardarse como hash con sal.

**2. ¿Por qué un hash no es equivalente a un cifrado?**
El cifrado es reversible con la clave; el hash es unidireccional y está diseñado para no recuperar el original. El hash sirve para verificar (recalcular y comparar); el cifrado, para recuperar el dato.

**3. ¿Por qué el cifrado de una columna no sustituye al control de acceso?**
El cifrado solo protege ese dato; no decide quién puede consultar, modificar o borrar filas, ni protege las demás columnas (como el nombre). Además, quien tenga permiso y la clave (o ejecute consultas donde la clave se pasa) puede descifrar. Ambos controles se complementan.

**4. ¿Por qué TLS no sustituye a los mecanismos de autorización de PostgreSQL?**
TLS protege el canal, pero no determina qué puede hacer un usuario autenticado. Un usuario con permisos excesivos puede leer todo, aunque la conexión esté cifrada. Además, con `sslmode=require` no se valida la identidad del servidor.

**5. ¿Qué ocurriría si una organización pierde una clave utilizada para cifrar información?**
Los datos cifrados con esa clave quedarían irrecuperables: se pierde la disponibilidad aunque la información siga almacenada. Por eso se requieren respaldos seguros de las claves, independientes de los de la base.

**6. ¿Qué ocurriría si una clave criptográfica se publica accidentalmente en GitLab?**
Debe considerarse comprometida: cualquiera que la copie puede descifrar los datos protegidos con ella, y borrar el archivo no basta porque queda en el historial. Hay que reportar, revocar y rotar la clave, revisar el historial, evaluar el alcance y volver a cifrar si es necesario.

**7. ¿Por qué un repositorio privado no debe considerarse un almacén de secretos?**
Porque tiene muchos lectores y copias (colaboradores, clones, forks, CI, historial), los permisos pueden cambiar o filtrarse y no ofrece rotación, auditoría de uso ni control fino de secretos. Reduce la exposición, pero no la elimina.

**8. ¿Qué diferencia existe entre proteger información almacenada y proteger información durante su transmisión?**
Lo almacenado (tablas, archivos, respaldos) se protege con cifrado en reposo y control de acceso; lo transmitido, con TLS. Un dato cifrado en disco viaja expuesto sin TLS, y una conexión con TLS no protege un archivo robado: se necesitan ambas.

**9. ¿Por qué la gestión de claves es tan importante como el algoritmo criptográfico?**
Porque la seguridad del cifrado recae en la clave, no en el secreto del algoritmo. Un algoritmo robusto con una clave expuesta, débil, sin rotar o perdida no protege nada.

**10. ¿Qué mecanismo adicional implementarías en una organización para proteger los respaldos de las bases de datos?**
Cifrado de los respaldos (por ejemplo, el cifrado integrado de la herramienta de respaldo o GPG) con claves en un KMS separado de los respaldos, almacenamiento fuera del servidor con acceso restringido y, si es posible, copias inmutables, además de pruebas periódicas de restauración y auditoría de accesos.
