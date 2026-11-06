# Informe — LAB-01 Bitácoras y auditoría del dato en PostgreSQL

**Estudiante:** [Tu nombre — matrícula]
**Servidor:** `PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit`
**Fecha de ejecución:** 2026-11-06 14:32 UTC

## 1. Despliegue y situación inicial

El servidor se desplegó como: Instalación nativa en Ubuntu 24.04 con los paquetes de la distribución (postgresql-16). Su directorio de datos es `/var/lib/postgresql/16/main`, su configuración `/etc/postgresql/16/main/postgresql.conf` y sus reglas de autenticación `/etc/postgresql/16/main/pg_hba.conf` (evidencia 01). Ninguna regla `host` usaba `trust`; no fue necesario modificar `pg_hba.conf` (evidencia 01, sección 6.4).

Esta era la configuración de registro con la que se recibió el servidor (evidencia 01):

| Parámetro | Valor | Para cambiarlo | Origen |
|---|---|---|---|
| log_connections | `off` | Recarga | default |
| log_destination | `stderr` | Recarga | default |
| log_directory | `log` | Recarga | default |
| log_disconnections | `off` | Recarga | default |
| log_filename | `postgresql-%Y-%m-%d_%H%M%S.log` | Recarga | default |
| log_line_prefix | `%m [%p] %q%u@%d ` | Recarga | configuration file |
| log_min_error_statement | `error` | Recarga | default |
| log_statement | `none` | Recarga | default |
| log_timezone | `Etc/UTC` | Recarga | configuration file |
| logging_collector | `off` | Reinicio | default |

Con esos valores, el servidor no registraba conexiones ni sentencias, y el prefijo de línea no identificaba a la vez al usuario, la aplicación y el equipo de origen. Al reproducir el incidente (evidencia 03), el `UPDATE` de `app_ventas` sobre el RFC de María García se aplicó sin dejar ninguna línea en la bitácora. No era posible responder ninguna de las preguntas de Dirección: ni quién, ni cuándo, ni desde dónde, ni el valor anterior. El control de acceso de la Unidad II funcionó como se diseñó: permitió el cambio porque `app_ventas` tiene `UPDATE`. Pero el control de acceso no produce evidencia.

## 2. Configuración aplicada

Todos los parámetros se aplicaron con `ALTER SYSTEM`, que funciona igual en cualquier despliegue y deja el valor en `postgresql.auto.conf`. Se verificaron en `pg_settings` con una consulta posterior a la recarga, porque `pg_reload_conf()` es asíncrona. Hubo reinicio: sí (activación de `logging_collector`).

| Parámetro | Valor | Para cambiarlo | Origen |
|---|---|---|---|
| log_connections | `on` | Recarga | configuration file |
| log_disconnections | `on` | Recarga | configuration file |
| log_line_prefix | `%m [%p] user=%u db=%d app=%a client=%h ` | Recarga | configuration file |
| log_min_error_statement | `error` | Recarga | default |
| log_statement | `mod` | Recarga | configuration file |
| logging_collector | `on` | Reinicio | configuration file |

Estos son los motivos de cada valor:

- **`logging_collector = on`**: el propio servidor administra sus archivos, sin depender del despliegue, y la bitácora se lee con `pg_current_logfile()` y `pg_read_file()`.
- **`log_connections` y `log_disconnections`**: registran accesos exitosos y fallidos, la duración de cada sesión y la regla de `pg_hba.conf` aplicada.
- **`log_line_prefix`**: con `%u %d %a %h`, cada línea dice quién, en qué base, con qué aplicación y desde qué equipo. Sin esos campos, la línea dice qué pasó pero no quién.
- **`log_statement = mod`**: registra estructura, privilegios y modificaciones de datos, pero no las lecturas. Es un equilibrio entre evidencia, volumen y exposición de datos sensibles.
- **`log_min_error_statement = error`**: se conserva el valor por defecto, que ya registra la sentencia de cualquier operación rechazada.

## 3. Eventos observados

**Acceso, fallido (evidencia 05).** Alguien intentó autenticarse como `app_ventas` desde esa IP con una contraseña incorrecta. La línea prueba el intento, no quién lo hizo, porque el usuario es el que declaró el cliente.
```
2026-11-06 14:30:54.332 UTC [387] user=app_ventas db=comercial app=[unknown] client=127.0.0.1 FATAL:  password authentication failed for user "app_ventas"
```

**Privilegio (evidencia 06).** `postgres`, por socket local y con `psql`, otorgó `UPDATE` a `app_ventas`.
```
2026-11-06 14:30:55.486 UTC [426] user=postgres db=comercial app=psql client=[local] LOG:  statement: GRANT UPDATE ON clientes TO app_ventas;
```

**Estructura (evidencia 06).** Se agregó la columna `segmento` a `clientes`.
```
2026-11-06 14:30:55.486 UTC [426] user=postgres db=comercial app=psql client=[local] LOG:  statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
```

**Datos (evidencia 07).** `app_ventas`, desde la IP del cliente y con `app-ventas-web`, modificó el teléfono de `id = 3`. Se sabe qué escribió, pero no qué valor tenía antes.
```
2026-11-06 14:30:58.694 UTC [477] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3
```

**Error (evidencia 08).** `soporte_ana`, ya autenticada, intentó un `DELETE` sin privilegio. Es un error de autorización: la sesión continúa y la sentencia queda en la línea `STATEMENT` siguiente.
```
2026-11-06 14:30:59.769 UTC [494] user=soporte_ana db=comercial app=psql client=127.0.0.1 ERROR:  permission denied for table clientes
```

**Configuración (evidencia 07).** El proceso principal registró el cambio de `log_statement` al recargar. Quién lo pidió está en la línea `statement: ALTER SYSTEM …` de la sesión que ejecutó el cambio.
```
2026-11-06 14:30:56.657 UTC [291] user= db= app= client= LOG:  parameter "log_statement" changed to "mod"
```

## 4. Auditoría del dato

**Diseño.** La tabla `auditoria.cambios_clientes` vive en un esquema sin acceso para `PUBLIC` (evidencia 10). Cada registro responde a una pregunta de Dirección:

- `momento` (`TIMESTAMPTZ`) responde *cuándo*;
- `usuario_sesion` responde *quién*;
- `usuario_efectivo` indica *con qué privilegios*;
- `aplicacion` e `ip_cliente` responden *desde dónde*;
- `operacion` e `id_cliente` responden *qué se hizo* y *sobre qué registro*;
- `valores_antes` y `valores_despues` (JSONB con el registro completo) conservan *qué valor tenía antes* y qué valor quedó.

La función de disparador `AFTER … FOR EACH ROW` (evidencia 11) escribe una fila por cada registro afectado.

**`SECURITY DEFINER`, `search_path` y `session_user`.** La función se ejecuta con los privilegios de su propietario, de modo que `app_ventas` provoca el registro sin poder leer ni modificar la auditoría. Su intento de leerla fue rechazado con `permission denied for schema auditoria`. El `search_path` fijo impide que alguien suplante objetos creados en otro esquema. Dentro de la función, `current_user` devuelve el propietario (`postgres`), así que el autor real del cambio se toma de `session_user`. La función se revocó a `PUBLIC` para que nadie pueda asociarla a otra tabla y fabricar eventos.

**Resultado del incidente auditado:**
```
id_evento=1 | 2026-11-06 14:32:31.101863+00 | usuario_sesion=app_ventas | usuario_efectivo=postgres | aplicacion=app-ventas-web | ip_cliente=127.0.0.1 | rfc: GAMA780912XYZ -> GAMA780912ZZZ
```
Esta vez se puede afirmar quién (`app_ventas`), cuándo, desde qué equipo y con qué aplicación se cambió el RFC, y cuál era el valor anterior. Con eso, el cambio puede revertirse con certeza (`sql/06-campos-modificados.sql`). Las altas y bajas también quedan completas: el cliente eliminado sigue constando en la auditoría (evidencia 12).

## 5. Limitaciones

- **Lecturas.** Ni `mod` ni el disparador registran `SELECT`. Las lecturas del RFC de las Actividades 7 y 15 no dejaron rastro (evidencia 14). Las alternativas son `log_statement = all` (volumen y datos sensibles en la bitácora), entregar el dato solo mediante una función que registre su uso, o pgaudit con auditoría de objeto (Parte C).
- **Volumen.** Un `UPDATE` sin `WHERE` produce una línea en la bitácora, pero una fila de auditoría por registro (evidencia 14). En una tabla grande, esto exige planear espacio, retención y depuración autorizada.
- **Administrador con control total.** El propietario de la tabla desactivó el disparador, cambió el RFC y lo reactivó sin dejar fila de auditoría (evidencia 13). Solo la bitácora lo delató, y quien controla el servidor también puede alterar la bitácora o ejecutar `SET log_statement = 'none'` en su sesión. Ningún mecanismo interno protege contra el administrador. La respuesta es organizativa: separación de funciones, envío de la bitácora a un sistema externo custodiado por otra área y conciliaciones periódicas.

## 6. Riesgos de la bitácora

- **Secretos expuestos.** `CREATE ROLE … PASSWORD '…'` dejó la contraseña en texto claro, y eliminar el rol no la borró (evidencia 06). Las contraseñas se asignan con `\password`, la bitácora se clasifica como confidencial y se sanea antes de compartirla. La exportación de este laboratorio sustituyó los secretos por `<REDACTED>` dentro del propio servidor.
- **Pérdida.** La bitácora vive en el servidor que la produce. Puede perderse si el servidor se reinstala, si el contenedor se recrea, si los archivos rotan sin conservarse o si falla el disco.
- **Acceso de terceros.** `pg_read_file` lee cualquier archivo del servidor, y la bitácora contiene contraseñas, sentencias y valores de datos personales. Solo el DBA y el custodio de la auditoría deben acceder a ella.

### Conservación e integridad (Actividad 16)

La bitácora se exportó a `evidencias/bitacora-lab01.log` y se calculó su resumen SHA-256:

```
5f45caa7ba7c43db0f1440ee2442af2afd272adbccaa4e2d10f12f96591d19b1  evidencias/bitacora-lab01.log
```

1. **¿El hash impide modificar la bitácora?** No. Permite demostrar que el archivo no cambió desde que se calculó: cualquier alteración produce un resumen distinto. No prueba que el contenido fuera correcto al exportarse, y no sirve si quien altera el archivo también puede reemplazar el hash.
2. **¿Dónde guardar el hash?** Lejos del archivo y fuera del alcance de quien administra el servidor. Por ejemplo, en el historial del repositorio de GitLab (cada commit queda fechado), enviado al custodio o al docente, firmado digitalmente o en un almacenamiento de solo escritura.
3. **Riesgos de conservar la bitácora solo en el servidor que la produce (NIST SP 800-92).** Un incidente que compromete el servidor compromete también su evidencia: el atacante o el administrador pueden borrar o editar las líneas. A eso se suman las fallas de disco, la rotación sin archivado, la recreación del contenedor y la imposibilidad de correlacionar con otros sistemas. Por eso la guía recomienda centralizar las bitácoras en una infraestructura independiente y protegida.
4. **Conservación propuesta.** Se proponen 90 días en línea y 12 meses archivada, con acceso restringido y hash por archivo, en línea con prácticas comunes como la de PCI DSS: un año de historial con los tres meses más recientes disponibles de inmediato. Como los cambios de RFC afectan a la facturación, el área fiscal podría justificar conservar la tabla de auditoría de clientes durante el plazo de las obligaciones fiscales. Esa decisión corresponde a las áreas legal y fiscal, y se formaliza en el LAB-03.

## 7. Cronología y conclusión

La evidencia 15 reconstruye 55 eventos en orden cronológico a partir de la bitácora y de la tabla de auditoría, y declara como huecos los eventos que no se registraron.

**¿Con esta configuración puede demostrarse quién cambió un dato sensible y qué valor tenía antes?** Sí, para los cambios hechos por usuarios y aplicaciones *a partir de que se configuró*. La bitácora prueba quién, cuándo, desde dónde y con qué aplicación. La tabla de auditoría prueba el valor anterior y el nuevo de cada registro. Hay tres excepciones:

- Los cambios anteriores a la configuración no pueden reconstruirse.
- Las lecturas no quedan registradas sin pgaudit.
- Un administrador con control total puede evadir la auditoría del dato. Solo la bitácora lo delata, y esa bitácora también la controla él.

La evidencia sobre el administrador depende de controles externos al servidor.

## Preguntas de reflexión

1. **¿Por qué la auditoría no puede configurarse después de un incidente?** Porque registra eventos en el momento en que ocurren. Lo que no se escribió entonces no existe en ninguna parte, y el estado actual de los datos no dice cómo se llegó a él. La Actividad 3 lo mostró: configurar la bitácora después no recuperó el primer cambio del RFC.
2. **¿Por qué conviene que la bitácora la administre el propio servidor?** Porque así su ubicación, nombre, rotación y lectura son iguales en cualquier plataforma y se controlan con parámetros del motor, que también quedan registrados. Si la administra el despliegue, el destino y la conservación dependen de un script, un servicio o un contenedor que puede perder la salida sin que el DBA lo note.
3. **¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?** Porque `log_statement` decide *qué* se registra y el prefijo decide si cada línea dice *quién, dónde, con qué aplicación y desde qué equipo*. Una sentencia sin usuario ni cliente prueba que algo ocurrió, pero no permite atribuirlo.
4. **¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?** La sentencia es una línea por operación, con el texto que se ejecutó: muestra la intención, pero no el valor anterior ni las filas afectadas. El cambio en el dato es una fila por registro, con su estado antes y después: permite revertir con certeza y ver el alcance real. Un `UPDATE` sin `WHERE` es una línea en la bitácora y N filas en la auditoría.
5. **¿Qué ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?** `pg_stat_activity` muestra lo que ocurre *ahora*: sesiones vivas, su estado, la consulta en curso y desde cuándo se ejecuta, incluso las lecturas que la bitácora no registra con `mod`. La bitácora conserva lo que *ya ocurrió*: sesiones terminadas, accesos fallidos, sentencias y cambios de configuración.
6. **Si el administrador puede apagar el registro y desactivar el disparador, ¿quién audita al administrador?** Alguien que no sea él, con evidencia que él no controle:
   - otra área que recibe las bitácoras en tiempo real en un sistema externo;
   - la revisión periódica de las operaciones privilegiadas, con gestión de cambios y doble control;
   - cuentas de administrador nominativas y un superusuario reservado para emergencias;
   - conciliaciones entre los datos y la auditoría.

   Es la separación de funciones de la Unidad II aplicada al propio mecanismo de auditoría.
