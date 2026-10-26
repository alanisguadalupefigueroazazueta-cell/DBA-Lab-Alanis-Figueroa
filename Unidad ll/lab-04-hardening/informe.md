# Informe — LAB-04 Hardening y configuración segura de PostgreSQL

**Alumno:** Alanís Guadalupe Figueroa Zazueta · **Fecha:** 2026-10-25 · Evidencia: `README.md`, `configuracion/`, `evidencias/`

## 1. Preguntas del informe

**1. ¿Cuál era la principal superficie de ataque?**
El puerto `5432/TCP` expuesto en todas las interfaces (`0.0.0.0:5432`) combinado con reglas `pg_hba.conf` que aceptaban
cualquier base, usuario y origen (`0.0.0.0/0`, `::/0`). Se comprobó con una conexión exitosa desde la IP no local
`192.0.2.2`. Cualquier red con ruta al servidor podía intentar autenticarse.

**2. ¿Qué configuración representaba el mayor riesgo?**
La **aplicación conectada como `SUPERUSER`** (`app_web`) *junto con* el acceso desde cualquier origen. Si la aplicación o su
credencial se comprometen, el atacante obtiene control total: leer/escribir todo, crear roles, usar extensiones como `file_fdw`
o `dblink` y, potencialmente, impactar el sistema operativo del servidor. La exposición de red aumentaba la probabilidad; el
`SUPERUSER`, el impacto.

**3. ¿Qué cambio produjo la mayor reducción de exposición?**
Cambiar `listen_addresses` de `'*'` a `'localhost'`: elimina por completo la superficie de red externa (el socket ya no existe
en esas interfaces; la prueba contra `192.0.2.2` pasó de *aceptada* a *Connection refused*). En segundo lugar, reemplazar
`0.0.0.0/0` por reglas `hostssl` específicas, y en cuanto al **impacto** de un compromiso, retirar el `SUPERUSER` a la aplicación.

**4. ¿Qué diferencia existe entre firewall y `pg_hba.conf`?**
El firewall actúa en red/transporte **antes** de PostgreSQL y decide quién puede llegar al puerto (IP, puerto, protocolo).
`pg_hba.conf` actúa en la aplicación y decide quién puede autenticarse: base de datos, **usuario**, origen, TLS y método.
Son capas complementarias; ver `configuracion/baseline.md` (Anexo A).

**5. ¿Qué diferencia existe entre autenticación y autorización?**
Autenticación = verificar **quién eres** (usuario + contraseña SCRAM). Autorización = determinar **qué puedes hacer**
(`GRANT/REVOKE`, atributos del rol). Una cuenta con contraseña fuerte pero `SUPERUSER` está bien autenticada y
peligrosamente autorizada.

**6. ¿Por qué una cuenta de aplicación no debe ser `SUPERUSER`?**
Porque la aplicación es el componente más expuesto y la credencial suele residir en archivos/variables de entorno.
Con `SUPERUSER` se omiten todas las comprobaciones de permisos: un SQL injection pasa de "leer una tabla" a "controlar el servidor".
En la prueba, `app_comercial` recibe `permission denied` al intentar `DELETE FROM pedidos` y `CREATE ROLE ... SUPERUSER`.

**7. ¿Por qué cambiar el puerto no constituye hardening suficiente?**
Solo reduce ruido de escaneos automáticos (oscuridad). Un escaneo completo de puertos o un `ss`/`nmap` lo descubre. No aporta
autenticación, autorización, cifrado ni filtrado de red. Aquí el puerto se mantuvo en 5432 y la exposición se redujo con
`listen_addresses`, `pg_hba.conf`, TLS y firewall.

**8. ¿Por qué `listen_addresses='*'` puede ser innecesario?**
Porque abre el servicio en **todas** las interfaces (incluidas redes que nunca deben ver la base) cuando normalmente solo
se necesita una (loopback o una IP privada). Cada interfaz extra es superficie extra; si la aplicación está en el mismo
host, basta `localhost`. Si no se necesita, no debe estar expuesto (*secure by default*).

**9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?**
Es la base: protege los archivos de configuración, el directorio de datos, la clave privada TLS y los logs, y aloja el firewall.
Con `GRANT/REVOKE` perfectos, un usuario del SO que lea `pg_hba.conf` obtiene reconocimiento (reglas, redes, usuarios) y, si
pudiera leer el directorio de datos, evitaría PostgreSQL por completo. En la prueba, `labuser` leía `pg_hba.conf` antes
(`0644`) y recibe `Permission denied` después (`0640` y directorio `0750`).

**10. ¿Qué controles deberían revisarse periódicamente?**
`listen_addresses`/puerto y `ss`; `pg_hba.conf` y redes permitidas; reglas de firewall; roles, superusuarios y cuentas sin
uso; privilegios de cuentas de aplicación; extensiones; vigencia de certificados TLS y versión mínima; permisos de
archivos del SO; parches de PostgreSQL y del SO; logs de conexión y autenticaciones fallidas; límites y timeouts;
vigencia/rotación de credenciales. Frecuencias propuestas en `configuracion/baseline.md` §7.

## 2. Respuestas a las preguntas de las actividades

**Act. 1 — ¿Por qué conocer la superficie de ataque debe preceder al hardening?**
No se puede proteger, reducir ni priorizar lo que no se conoce; endurecer "a ciegas" deja huecos o rompe servicios necesarios
(p. ej. cerrar una conexión remota legítima). El inventario permite decidir qué es necesario, qué se elimina y qué se controla,
y define la línea base contra la cual verificar.

**Act. 2 — ¿Por qué conocer la ubicación física de los archivos?**
Para proteger cada categoría con el control correcto (datos, configuración, autenticación, logs) y para verificar sus permisos
y propietarios. En Ubuntu, configuración y datos están en rutas distintas (`/etc/postgresql/...` vs `/var/lib/postgresql/...`);
también permite respaldar antes de cambiar y auditar cambios.

**Act. 3 — Análisis de arquitecturas.**

| | Arquitectura A | Arquitectura B |
|---|---|---|
| Esquema | Internet → Firewall → PostgreSQL:5432 | Internet ✗ → Firewall → red privada → PostgreSQL |
| Exposición | El servicio es alcanzable desde Internet si el firewall lo permite; un error de regla lo expone | Sin ruta pública hacia la BD; un atacante debe antes comprometer algo dentro de la red privada |

La **B reduce mejor la exposición** (segmentación + defensa en profundidad): elimina la ruta directa, requiere varios fallos
encadenados para llegar a la BD y permite listas de acceso por segmento. Configuración encontrada: `*` (todas las interfaces);
necesarias: solo `127.0.0.1` (lab) / interfaz privada (prod); innecesarias: el resto.

**Act. 5 — Regla `host all all 0.0.0.0/0 scram-sha-256`.**

| Pregunta | Respuesta |
|---|---|
| ¿Qué bases permite? | Todas (`all`), incluidas `postgres` y las de otros sistemas |
| ¿Qué usuarios? | Todos, incluidos superusuarios |
| ¿Qué orígenes? | Todo IPv4 (`0.0.0.0/0`); su par `::/0` abre todo IPv6 |
| ¿Qué autenticación? | `scram-sha-256` (adecuada, pero solo protege la contraseña) |
| ¿Por qué es exposición innecesaria? | Cualquiera en cualquier red puede intentar fuerza bruta/credential stuffing contra cualquier cuenta; la única barrera es la contraseña |
| ¿Qué información se necesita para restringirla? | Qué aplicaciones/servicios se conectan, a qué BD, con qué cuenta, desde qué host/red, y si usan TLS |

| Campo | Valor |
|---|---|
| Regla actual | `host all all 0.0.0.0/0 scram-sha-256` (línea 135) y `host all all ::/0 scram-sha-256` (línea 136) |
| Problema | Origen, BD y usuario sin restricción |
| Origen que realmente necesita acceso | La aplicación (en el lab, `127.0.0.1/32`; en prod, su host/red) y la Red DBA `10.10.10.0/24` |
| Base de datos | `comercial_norte` |
| Usuario | `app_comercial`, `consulta_norte`, `dba_lab` |
| Regla propuesta | `hostssl comercial_norte app_comercial 127.0.0.1/32 scram-sha-256` (ver `pg_hba.conf` final) |

**Act. 6 — Mínimo privilegio en conexiones.** Cada regla fija **BD + usuario + origen + método** (y `hostssl`).
En producción se sustituye `127.0.0.1/32` por el host/segmento real (p. ej. `10.10.10.0/24`).

**Act. 7 — Autenticación.**
- *Autenticación vs autorización:* ver pregunta 5.
- *¿Qué protege `scram-sha-256`?* Evita enviar la contraseña en claro durante el intercambio y almacena un verificador
  salteado e iterado (no la contraseña), resistente a *replay* y más costoso de atacar offline que `md5`.
- *Hash ≠ cifrado reversible:* el verificador SCRAM es una derivación **unidireccional**; el servidor no puede recuperar la contraseña, solo comprobar que quien la presenta la conoce. Un cifrado reversible permitiría descifrarla con la clave.
- *Permisos excesivos con contraseña fuerte:* quien tenga la credencial (o la aplicación) puede hacer todo lo que la cuenta permita; la contraseña no limita el daño de un compromiso.
- Hallazgo: `password_encryption=scram-sha-256` y todos los hashes eran SCRAM. `SHOW` solo indica el algoritmo para contraseñas **nuevas**, por eso se verificó también `pg_authid`.

**Act. 8/9 — ¿Por qué no usar `SUPERUSER` como cuenta de aplicación?** Ver pregunta 6.
**¿Qué riesgo hay si la aplicación usa una cuenta administrativa?** Compromiso total ante SQL injection, credencial filtrada
o bug de la aplicación (lectura/modificación de todo, creación de cuentas, extensiones peligrosas, borrado de estructura, persistencia).

**Act. 10 — Extensiones.** Existían `dblink`, `file_fdw`, `pgcrypto`, `plpgsql`. `plpgsql` es base; `pgcrypto` se conserva (necesaria
para el cifrado de LAB-02); `dblink` y `file_fdw` se eliminaron por ser funcionalidad no necesaria (conexiones salientes y lectura de archivos del servidor).
Una extensión no es "insegura" por existir: se aplica el principio de habilitar solo lo necesario.

**Act. 11 — Parámetros de conexión.**

| Parámetro | Antes | Después | Función |
|---|---|---|---|
| `max_connections` | 100 | 50 | Máximo de conexiones simultáneas; acota memoria/procesos |
| `superuser_reserved_connections` | 3 | 3 | Conexiones reservadas a superusuarios para poder administrar cuando se agotan las normales |
| `statement_timeout` | 0 | 0 global; 30 s (app) y 15 s (consulta) por rol | Aborta consultas que superan el tiempo |
| `idle_in_transaction_session_timeout` | 0 | 60 s | Cierra sesiones con transacción abierta sin actividad (retienen *locks* y bloquean `VACUUM`) |
| `idle_session_timeout` | 0 | 30 min | Cierra sesiones inactivas |

*¿Por qué conexiones abiertas indefinidamente son un problema?* Cada conexión es un proceso con memoria; las inactivas ocupan
cupo (`max_connections`) y las que mantienen transacciones abiertas retienen *locks* y bloquean limpieza. Pueden provocar denegación de servicio por agotamiento.

**Act. 12 — Permisos del SO.** Antes: configuración `0644`, directorio `0755`; datos `0700`. Después: `0640`, `0750`, `0700`.
*¿Por qué no basta `GRANT/REVOKE`?* Porque operan **dentro** de PostgreSQL; los archivos se rigen por el SO. Quien lea `postgresql.conf`/`pg_hba.conf`
conoce redes, usuarios y métodos; con acceso al directorio de datos o a copias de seguridad podría leer los datos sin pasar por los controles de la BD.

**Act. 13 — Exposición de red.** Antes: `0.0.0.0:5432`, expuesto fuera de la interfaz necesaria (sí). Después: `127.0.0.1:5432` (no).

**Act. 14 — Firewall.** Ver `configuracion/baseline.md` Anexo A (incluye la comparación firewall vs `pg_hba.conf`).

**Act. 15 — TLS.** `ssl=on`, mínimo `TLSv1.2`; conexión actual: TLSv1.3, `TLS_AES_256_GCM_SHA384`. Antes TLS era *opcional* (se aceptó una conexión con
`sslmode=disable`); ahora es *obligatorio* mediante `hostssl`. Pendiente en producción: certificado de CA y `sslmode=verify-full`. (Nota: la consulta del
enunciado sobre `pg_stat_ssl` se corrigió con un `JOIN` a `pg_stat_activity`.)

## 3. Caso integral (Act. 18)

*Escenario:* IPv4 desde cualquier dirección; aplicación web con usuario administrativo; escucha en todas las interfaces; firewall permite 5432 desde cualquier origen;
`pg_hba.conf` con `all/all` desde `0.0.0.0/0`; el administrador afirma que "no hay problema porque todas las contraseñas son fuertes".

| # | Problema | Riesgo | Control propuesto |
|---|---|---|---|
| 1 | Escucha en todas las interfaces (`*`) | Exposición innecesaria de red | `listen_addresses` solo a la interfaz necesaria |
| 2 | Firewall permite 5432 desde cualquier origen | Cualquier red alcanza el servicio; escaneo y ataques directos | Allowlist de origen + *deny* por defecto |
| 3 | `pg_hba.conf` `all/all 0.0.0.0/0` | Cualquier usuario, a cualquier BD, desde cualquier IP | Reglas por BD + usuario + origen específicos |
| 4 | Aplicación con usuario administrativo | Compromiso total ante SQL injection o credencial filtrada | Cuenta de servicio con mínimo privilegio |
| 5 | Sin límite a intentos / sin monitoreo de accesos | Fuerza bruta y credential stuffing sin detección | Logging de conexiones, alertas, bloqueo en red/firewall |
| 6 | TLS no exigido | Credenciales y datos interceptables | `hostssl`, TLS ≥ 1.2, `verify-full` |
| 7 | Mismas cuentas para DBA y app (sin separación) | Imposible atribuir acciones; privilegios acumulados | Cuentas DBA / APP / CONSULTA separadas |
| 8 | Sin segmentación de red | Movimiento lateral desde cualquier equipo | BD en red privada, segmentos con ACL |
| 9 | Propiedad de BD/objetos en la cuenta de la aplicación | La app puede alterar o borrar estructura | Propietario DBA; app con DML limitado |
| 10 | Archivos de configuración / directorio de datos sin revisar | Reconocimiento y lectura por usuarios del SO | Permisos `0640/0750/0700` y propietario `postgres` |
| 11 | Sin límites de conexiones ni timeouts | Agotamiento de recursos (DoS) | `max_connections`, timeouts, límites por rol |
| 12 | Extensiones/funciones innecesarias habilitadas | Más superficie (lectura de archivos, conexiones salientes) | Revisar y retirar |
| 13 | Sin política de parches ni documentación | Vulnerabilidades conocidas sin corregir; configuración irreproducible | Política de actualización, baseline y checklist |
| 14 | Confianza únicamente en contraseñas | Una sola capa de defensa | Defensa en profundidad |

**¿Es suficiente tener contraseñas fuertes?** No. Una contraseña fuerte solo mejora la **autenticación**; no limita lo que la cuenta puede hacer
(**autorización**), no reduce quién puede llegar al servicio (**red**), no corrige configuraciones inseguras (**configuración**),
no protege archivos (**sistema operativo**) ni permite detectar abusos (**monitoreo**). Además, la contraseña puede filtrarse
(código, logs, phishing, SQL injection en la aplicación) y, entonces, los privilegios y la exposición determinan el daño.

## 4. Reflexión

> *¿Qué cambiarías primero si recibieras la responsabilidad de asegurar un servidor PostgreSQL ya en producción?*

**Primero: descubrir (sin cambiar nada) y luego restringir el origen del acceso (`pg_hba.conf` + firewall) a lo que realmente se usa**, sin reiniciar el servicio.

1. **Riesgo y exposición.** Lo que más probabilidad de ataque tiene es lo accesible desde cualquier origen. Reducir *quién puede llegar y autenticarse* reduce la probabilidad de todos los demás riesgos (fuerza bruta, explotación de vulnerabilidades, credenciales filtradas).
2. **Disponibilidad y continuidad.** En producción, el primer paso es de **solo lectura**: `pg_stat_activity` + logs (activando `log_connections`, que no requiere reinicio) durante un periodo para saber qué conexiones son reales. Después, ajustar `pg_hba.conf` solo requiere `reload` (sin cortar sesiones), a diferencia de `listen_addresses` y `max_connections`, que requieren reinicio y deben ir en ventana de mantenimiento. Un cambio a ciegas puede tumbar la aplicación; por eso se inventaría primero y se prepara reversión (respaldo de la configuración).
3. **Impacto y privilegios.** Inmediatamente después (misma ventana o la siguiente), sustituir las cuentas administrativas usadas por aplicaciones con cuentas de mínimo privilegio, porque es lo que determina *cuánto daño* hace un compromiso. Requiere coordinación con los equipos de aplicación (cambio de credencial), por lo que va después de conocer qué conexiones existen.
4. **Autenticación y red.** Verificar `scram-sha-256` y exigir TLS (`hostssl`) cuando los clientes estén listos; el firewall se alinea con `pg_hba.conf` como segunda capa.
5. **Después:** permisos de SO, extensiones, timeouts, parches y documentación del baseline.

**Por qué este orden:** primero lo que **reduce más probabilidad con menor riesgo operativo** (descubrir + restringir origen con `reload`), luego lo que **reduce más impacto** (privilegios), y por último lo que exige reinicio o coordinación amplia. Nunca se empieza por cambiar el puerto ni se aplican cambios sin evidencia previa.
