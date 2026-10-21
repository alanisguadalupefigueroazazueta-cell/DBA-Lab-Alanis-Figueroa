# Laboratorio de privacidad de datos — Informe final

**Elaboró:** Alanis Guadalupe Figueroa Zazueta

## Contenido

1. [Introducción](#1-introducción)
2. [Inventario de datos](#2-inventario-de-datos)
3. [Finalidades](#3-finalidades)
4. [Minimización](#4-minimización)
5. [Control de acceso](#5-control-de-acceso)
6. [Derechos ARCO](#6-derechos-arco)
7. [Retención](#7-retención)
8. [Gobierno de datos](#8-gobierno-de-datos)
9. [Evaluación integral](#9-evaluación-integral)
10. [Conclusiones](#10-conclusiones)
11. [Verificación final del laboratorio](#11-verificación-final-del-laboratorio)
12. [Preguntas de reflexión](#12-preguntas-de-reflexión)

---

## 1. Introducción

Comercializadora Norte S.A. de C.V. almacena información personal de 50,000 clientes en la tabla `clientes`, que contiene nueve campos: `id`, `nombre`, `correo`, `telefono`, `rfc`, `edad`, `ciudad`, `codigo_postal` y `fecha_alta`.

El problema de privacidad que aborda este laboratorio es que **tener los datos no significa poder usarlos libremente ni que todas las áreas deban verlos**. En el escenario analizado se identifican situaciones como las siguientes:

- El personal de analítica consulta directamente la tabla `clientes`, aunque solo genera estadísticas mensuales.
- Los datos se conservan desde hace 12 años sin una justificación ni una política de retención documentadas.
- Los desarrolladores reciben copias completas de la base de datos con información real.
- Marketing utiliza los correos electrónicos para campañas promocionales sin que las finalidades estén claras.

El laboratorio aplica los principios de **minimización, limitación de la finalidad, mínimo privilegio, privacidad por diseño y por defecto, retención limitada y atención de derechos ARCO** (acceso, rectificación, cancelación y oposición). El objetivo es identificar qué datos se tienen, para qué se usan, quién debe acceder a ellos, cuánto tiempo deben conservarse y qué controles técnicos y administrativos reducen los riesgos.

Las evidencias detalladas de cada actividad se encuentran en la carpeta `evidencias/`.

---

## 2. Inventario de datos

Se revisaron los nueve campos de la tabla `clientes` para determinar si permiten identificar a una persona, qué finalidad justifican, si son necesarios y qué áreas deben acceder a ellos (detalle completo en [`evidencias/01-inventario-datos.md`](evidencias/01-inventario-datos.md)).

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Acceso |
|---|---|---|---|---|
| `id` | No directamente; puede identificar indirectamente al relacionarse con otros datos. | Identificar cada registro de forma única. | Sí | Atención al cliente, Facturación y DBA; Analítica solo si lo requiere técnicamente. |
| `nombre` | Sí | Identificar y atender al cliente; facturar. | Sí | Atención al cliente, Facturación y DBA autorizado. Analítica no lo necesita. |
| `correo` | Sí | Comunicaciones del servicio y atención de solicitudes. | Sí, si es medio de contacto. | Atención al cliente y DBA autorizado; otras áreas con justificación. |
| `telefono` | Sí | Llamadas o comunicaciones de atención. | Condicional | Atención al cliente y DBA autorizado. |
| `rfc` | Sí, cuando se vincula con una persona física. | Identificación fiscal y facturación. | Sí, solo para procesos fiscales. | Facturación y personal autorizado; Analítica sin acceso. |
| `edad` | Sí, cuando se asocia con una persona identificable. | Estadísticas demográficas justificadas. | No necesariamente | Personal autorizado; Analítica mediante grupos agregados. |
| `ciudad` | Puede serlo al combinarse con otros datos. | Atención por ubicación y estadísticas. | Sí, si se necesita para el servicio o estadísticas. | Atención al cliente y Facturación cuando corresponda; Analítica con datos agregados. |
| `codigo_postal` | Puede serlo al combinarse con otros datos. | Procesos postales, comerciales o fiscales. | Condicional | Personal autorizado según el proceso. |
| `fecha_alta` | Puede serlo cuando se vincula a un cliente identificable. | Antigüedad y evolución de la relación comercial. | Sí, si se justifica. | Atención al cliente, Facturación, Analítica y DBA según sus funciones. |

**Clasificación general:**

- **Identificadores directos:** `nombre`, `correo`, `telefono`, `rfc`.
- **Datos que pueden identificar de forma indirecta al combinarse:** `id`, `edad`, `ciudad`, `codigo_postal`, `fecha_alta`.
- **Datos de acceso más restringido:** `rfc` (identificación fiscal), seguido de los medios de contacto (`correo` y `telefono`).
- **Datos cuya necesidad debe justificarse:** `edad` y `codigo_postal`.

Almacenar un dato no implica que todas las áreas deban consultarlo: cada permiso debe responder a una necesidad funcional.

---

## 3. Finalidades

Cada dato debe utilizarse únicamente para la finalidad que justifica su recopilación (matriz completa en [`evidencias/11-gobierno-datos.md`](evidencias/11-gobierno-datos.md)):

| Dato | Finalidad |
|---|---|
| `nombre` | Identificar al cliente y atender sus solicitudes. |
| `correo` | Contactar al cliente y enviar comunicaciones autorizadas. |
| `telefono` | Contactar al cliente para atender solicitudes o dar seguimiento a servicios. |
| `rfc` | Identificación fiscal y cumplimiento de obligaciones de facturación. |
| `edad` | Clasificación estadística o segmentación justificada por una finalidad autorizada. |
| `ciudad` | Atención relacionada con ubicación y estadísticas geográficas. |
| `codigo_postal` | Ubicación aproximada para servicios, entregas u operaciones justificadas. |

### Separación por finalidad: Analítica

La información agregada es más apropiada para Analítica que la tabla completa, porque permite obtener estadísticas y conocer la distribución de clientes por ciudad o rango de edad sin exponer nombres, correos, teléfonos ni RFC, que no son necesarios para ese análisis. Así se aplican la minimización de datos y la limitación de la finalidad. Los resultados agregados deben revisarse para evitar que grupos muy pequeños permitan identificar indirectamente a una persona.

### Finalidad secundaria: promociones personalizadas

Se analizó la propuesta de usar los datos para enviar promociones según edad, ciudad y comportamiento de compra (detalle en [`evidencias/05-finalidad-secundaria.md`](evidencias/05-finalidad-secundaria.md)):

- Que la empresa tenga los datos **no** significa que pueda utilizarlos para cualquier propósito. Debe revisar el aviso de privacidad, la compatibilidad con la finalidad original y si necesita informar al cliente u obtener su consentimiento.
- Para una segmentación básica bastarían la ciudad, un rango de edad y categorías generales de productos. Si hay que identificar al destinatario, podría usarse el correo o un identificador interno, con justificación.
- Nombre completo, teléfono y RFC no son necesarios para segmentar.
- Marketing no necesita acceso directo a `clientes`: debe trabajar con una vista o tabla preparada con los datos estrictamente necesarios.
- Controles posibles: vistas SQL, roles con permisos específicos, agrupación por rangos, seudonimización con identificadores internos, auditoría y mínimo privilegio.

---

## 4. Minimización

### Tabla para Atención al cliente

Ante la solicitud de crear una tabla (`clientes_soporte`) para Atención al cliente, se evaluó la utilidad de cada campo en la atención habitual.

- **Pueden cubrir las necesidades habituales:** `id`, `nombre`, `correo` y `telefono`.
- **Dependen del servicio:** `ciudad`, `codigo_postal` y `fecha_alta`; solo deberían usarse cuando una actividad concreta lo requiera.
- **No deberían incluirse sin finalidad justificada:** `rfc` y `edad`.

Respuestas a las preguntas del análisis:

1. **¿Todos los campos son necesarios para atención al cliente?** No. Los campos `id`, `nombre`, `correo` y `telefono` pueden ser suficientes. La necesidad de `ciudad`, `codigo_postal` y `fecha_alta` depende de las funciones del área, y el RFC y la edad no deberían incluirse sin una finalidad justificada.
2. **¿Por qué soporte necesitaría conocer el RFC?** Normalmente no lo necesita. Podría requerirlo de forma excepcional para una solicitud de facturación o identificación fiscal, y en ese caso el acceso debe limitarse a casos autorizados, no a la consulta general.
3. **¿Necesita conocer la edad?** No necesariamente; solo cuando exista una finalidad específica que lo justifique.
4. **¿Necesita conocer el código postal?** Depende del servicio: puede necesitarlo para entregas, direcciones o cobertura geográfica, pero no necesita acceso permanente si solo responde consultas generales.
5. **¿Qué principio se relaciona?** El de **minimización de datos**, junto con la limitación de la finalidad y el control de acceso.

Mantener todos los campos de la tabla original en la tabla de soporte ampliaría innecesariamente la información personal disponible para esa área. La minimización debe aplicarse tanto al diseño de las tablas como a los permisos de consulta; si soporte necesita un dato de forma excepcional, conviene un mecanismo de acceso limitado en lugar de acceso general.

### Privacidad por diseño: tabla con datos excesivos

Se revisó una propuesta de tabla con nombre, correo, teléfono, RFC, edad, dirección, fecha de nacimiento, ocupación, salario y estado civil, justificada porque "podrían ser útiles en el futuro" (detalle en [`evidencias/12-privacidad-diseno.md`](evidencias/12-privacidad-diseno.md)).

- **Principio ignorado:** la minimización de datos y, en relación con ella, la limitación de la finalidad.
- **Datos que se eliminarían inicialmente** si la aplicación solo registra clientes y permite contacto básico: RFC, edad, dirección completa, fecha de nacimiento, ocupación, salario y estado civil. Se conservaría un identificador único, nombre y correo; el teléfono solo con una necesidad concreta. Si la aplicación factura, podría justificarse el RFC.
- **Datos que requieren justificación adicional:** RFC, edad y fecha de nacimiento, dirección y código postal, ocupación, salario y estado civil.
- **Privacidad por defecto:** recopilar solo lo indispensable, configurar permisos restrictivos desde la creación del sistema y solicitar datos adicionales únicamente cuando una función opcional los requiera, informando su finalidad.

---

## 5. Control de acceso

Los permisos se relacionaron con las funciones de cada área, bajo el principio de **mínimo privilegio** y el control de acceso basado en roles (arquitectura completa en [`evidencias/15-arquitectura.md`](evidencias/15-arquitectura.md)):

| Área | Información utilizada | Control principal |
|---|---|---|
| Operación / Atención al cliente | Datos necesarios para atender a los clientes | Acceso limitado por función |
| Facturación | Datos fiscales necesarios para comprobantes | Acceso restringido a RFC y datos fiscales |
| Analítica | Datos agregados y agrupados | Vistas y minimización |
| Auditoría | Registros de acceso y cambios relevantes | Permisos restringidos y revisión periódica |
| Administración de la base de datos (DBA) | Acceso técnico según responsabilidades autorizadas | Roles, permisos y registro de actividades |
| Privacidad o cumplimiento | Información necesaria para evaluar solicitudes y políticas | Procedimientos documentados y seguimiento |

### Implementación en PostgreSQL

Para Analítica se propone una vista con ciudad y rango de edad, sin nombre, correo, teléfono ni RFC:

```sql
CREATE VIEW v_analitica_clientes AS
SELECT
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        WHEN edad >= 60 THEN '60 o más'
        ELSE 'Sin dato'
    END AS rango_edad
FROM clientes;
```

Al rol de analítica (`analista_alanis_figueroa`) se le concederían únicamente los permisos necesarios sobre la vista autorizada, sin acceso a la tabla original. Este código es un ejemplo conceptual y debe verificarse en PostgreSQL antes de afirmar que fue implementado. Además, una vista con filas individuales no equivale por sí sola a datos agregados; para estadísticas se pueden usar consultas con `GROUP BY` y revisar el riesgo de identificar personas en grupos pequeños.

### Análisis del rol de analítica

1. **¿Qué información puede consultar el rol?** La autorizada mediante la vista `v_analitica_clientes`, como ciudad y rango de edad, para análisis estadísticos.
2. **¿Puede consultar directamente `clientes`?** No, siempre que no tenga permisos directos o heredados sobre la tabla original.
3. **¿Puede obtener nombre, correo y RFC?** No mediante la vista de analítica, porque esos datos no están incluidos, siempre que el rol no tenga otros permisos que le permitan acceder a ellos.
4. **Principio de privacidad aplicado:** minimización de datos.
5. **Principio de seguridad aplicado:** mínimo privilegio y control de acceso basado en roles.

### Controles técnicos y administrativos

| Medida | Técnico | Administrativo | Justificación |
|---|:---:|:---:|---|
| Crear roles de PostgreSQL | X | | Permite asignar permisos específicos a los usuarios dentro de la base de datos. |
| Política de retención | | X | Establece cuánto tiempo deben conservarse los datos y qué hacer cuando termine ese periodo. |
| Cifrado de datos | X | | Protege la información para dificultar su lectura por personas no autorizadas. |
| Procedimiento para solicitudes ARCO | | X | Define cómo recibir, evaluar, atender y documentar las solicitudes de los titulares. |
| Vista con información limitada | X | | Muestra únicamente los campos necesarios para una función determinada. |
| Clasificación de información | | X | Establece categorías para identificar el nivel de protección que necesita cada tipo de información. |
| Registro de auditoría | X | X | Técnicamente registra acciones y accesos; administrativamente requiere reglas sobre revisión, responsables y conservación. |
| Política de control de acceso | | X | Define quién puede consultar la información y bajo qué condiciones; los permisos se implementan técnicamente. |

Tres medidas requieren combinar ambos tipos de control: el **registro de auditoría** (mecanismo técnico más reglas de revisión), la **política de control de acceso** (reglas administrativas implementadas con roles, permisos y vistas) y la **política de retención** (administrativa, pero su cumplimiento puede requerir controles técnicos para identificar datos que alcanzaron su periodo de conservación).

---

## 6. Derechos ARCO

Los derechos de acceso, rectificación, cancelación y oposición exigen que la organización cuente con procedimientos y herramientas para atender a los titulares. Técnicamente pueden requerirse consultas SQL, actualización de registros, controles de acceso, procesos de eliminación y revisión de copias en respaldos, reportes y otros sistemas.

### Acceso

Una consulta SQL permite localizar los datos de un titular a partir de un identificador, como el correo (detalle en [`evidencias/06-derechos-arco.md`](evidencias/06-derechos-arco.md)):

```sql
SELECT id, nombre, correo, telefono, rfc, edad, ciudad, codigo_postal, fecha_alta
FROM clientes
WHERE correo = 'ana@example.com';
```

- Antes de entregar la información deben verificarse la identidad del solicitante y la autorización para atender la solicitud.
- El resultado de la consulta **no constituye por sí solo una respuesta completa**: la organización debe explicar para qué utiliza la información, cómo la obtuvo, si la comparte con terceros, cuánto tiempo la conserva y qué mecanismos existen para ejercer otros derechos.
- El DBA debe considerar datos relacionados en otras tablas, respaldos, registros o sistemas conectados, y conservar evidencias de la atención de la solicitud.

### Rectificación

Requiere corregir datos incorrectos mediante la actualización de registros, con procedimientos autorizados y documentados.

### Cancelación y ciclo de vida

Eliminar un registro de la tabla principal **no garantiza** que toda la información haya desaparecido de la organización (detalle en [`evidencias/08-ciclo-vida.md`](evidencias/08-ciclo-vida.md)). Antes de ejecutar cualquier eliminación autorizada deben revisarse siete elementos:

1. Tablas relacionadas.
2. Respaldos.
3. Réplicas.
4. Registros de auditoría.
5. Copias utilizadas para analítica.
6. Archivos exportados (CSV, Excel, PDF).
7. Sistemas externos.

La cancelación debe atenderse de forma controlada y documentada, considerando las políticas de conservación y las obligaciones legales, sin eliminar información indiscriminadamente.

### Oposición

El derecho de oposición **no implica eliminar automáticamente todos los datos**:

- Pueden tener que conservarse los datos indispensables para la relación comercial, compras pendientes, garantías u obligaciones fiscales y contables.
- Los datos usados exclusivamente para campañas (rango de edad, ciudad, historial de compras, correo) pueden dejar de emplearse para esa finalidad sin eliminarse de todos los sistemas si siguen siendo necesarios para otras finalidades autorizadas.
- **Mecanismos técnicos para separar finalidades:** vistas SQL específicas por área, roles con permisos limitados, tablas separadas para campañas, controles que excluyan a quienes se opusieron, registro de preferencias de privacidad y una lista de exclusión de acceso limitado.
- **La decisión no debe tomarla solo el DBA**, porque implica consecuencias jurídicas. Privacidad, cumplimiento y las demás áreas responsables evalúan el alcance de la solicitud; el DBA ejecuta las medidas técnicas autorizadas y verifica que se apliquen correctamente.

---

## 7. Retención

La propuesta de conservar todos los datos de los clientes indefinidamente porque podrían ser útiles en el futuro **no es compatible con el principio de minimización** (detalle en [`evidencias/10-retencion.md`](evidencias/10-retencion.md)). Cuando los datos dejan de ser necesarios, debe evaluarse su eliminación, bloqueo, anonimización u otra medida procedente, considerando las obligaciones legales.

**Riesgos de conservar información innecesaria:** mayor exposición ante accesos no autorizados, filtraciones o ataques; más costos de almacenamiento, administración, respaldo y protección; posibilidad de usos incompatibles con la finalidad original; dificultad para atender solicitudes ARCO; y mayores consecuencias de un incidente de seguridad.

### Cómo debe determinarse el periodo de conservación

Antes de fijar un periodo, la organización debe:

- Identificar la **finalidad** de cada conjunto de datos y cuánto tiempo son necesarios para cumplirla.
- Revisar las **obligaciones** legales, fiscales, contables, contractuales y administrativas aplicables.
- Considerar los plazos para atender reclamaciones y las necesidades operativas justificadas.
- Definir qué se hará cuando termine el periodo.

Los periodos no deben elegirse arbitrariamente ni ser iguales para todos los datos. Por ejemplo, la información de contacto de una finalidad comercial puede conservarse de forma distinta que los registros fiscales sujetos a obligaciones específicas.

### Información que debe documentarse

| Elemento | Qué debe incluir |
|---|---|
| Tipo de datos | Qué información personal se conserva. |
| Finalidad | Para qué se utiliza cada conjunto de datos. |
| Justificación | Por qué es necesario conservarlo durante el periodo seleccionado. |
| Fundamento aplicable | Obligaciones legales u otros criterios. |
| Periodo de retención | Duración y criterios para determinar cuándo termina. |
| Responsable | Área que revisa y aplica la política. |
| Disposición final | Procedimiento para eliminar, bloquear, anonimizar o tratar los datos al terminar el periodo. |
| Excepciones | Circunstancias justificadas que requieran conservación adicional. |
| Revisión y evidencia | Fecha de revisión y registros que comprueben el cumplimiento. |

---

## 8. Gobierno de datos

La matriz de gobierno relaciona cada dato con su finalidad, responsable, usuarios autorizados, protección, retención y acción al finalizar (detalle en [`evidencias/11-gobierno-datos.md`](evidencias/11-gobierno-datos.md)).

| Dato | Responsable | Usuarios autorizados | Protección | Acción al finalizar |
|---|---|---|---|---|
| `nombre` | Atención al cliente | Atención al cliente; facturación cuando sea necesario | Control de acceso por roles y acceso limitado | Eliminar o bloquear, salvo obligación de conservación |
| `correo` | Atención al cliente | Atención al cliente; marketing solo para finalidades autorizadas | Acceso restringido, protección de credenciales y registro de accesos | Eliminar o dejar de utilizar para la finalidad correspondiente |
| `telefono` | Atención al cliente | Atención al cliente y otras áreas con necesidad justificada | Acceso por roles y uso limitado a la finalidad autorizada | Eliminar o bloquear cuando deje de ser necesario |
| `rfc` | Facturación | Facturación autorizada; DBA solo para tareas técnicas justificadas | Acceso restringido, permisos específicos y protección de respaldos | Eliminar o bloquear al terminar las obligaciones de conservación |
| `edad` | Analítica | Analítica con datos agrupados o vista limitada | Rangos de edad; evitar exponer datos identificables | Eliminar, anonimizar o dejar de utilizar |
| `ciudad` | Atención al cliente / Analítica | Atención al cliente (necesidad justificada); Analítica con datos agrupados | Limitar acceso y usar agregaciones | Eliminar o anonimizar |
| `codigo_postal` | Atención al cliente | Atención al cliente y otras áreas solo si es necesario | Control de acceso y exposición limitada | Eliminar, anonimizar o bloquear |

Los periodos de retención de cada dato son criterios generales: dependen de la finalidad y deben concretarse con las obligaciones legales y las políticas aprobadas por la organización.

### Responsabilidades de los roles

- **Atención al cliente:** consulta los datos indispensables para identificar al cliente, responder solicitudes y dar seguimiento a los servicios.
- **Facturación:** accede a los datos fiscales necesarios para elaborar comprobantes y cumplir obligaciones.
- **Analítica:** trabaja preferentemente con datos agrupados, rangos y vistas limitadas.
- **DBA:** administra la base de datos, los permisos, los respaldos y la seguridad técnica. Su función no lo autoriza a utilizar libremente los datos personales.
- **Dirección:** autoriza políticas y supervisa su cumplimiento, en coordinación con privacidad y cumplimiento.

### Reparto de decisiones

El **DBA** implementa y mantiene controles técnicos (roles, permisos, vistas, respaldos, disponibilidad, auditoría). El **responsable de privacidad** coordina las políticas de tratamiento, revisa finalidades y apoya la atención de derechos. El **área jurídica** asesora sobre obligaciones legales, bases del tratamiento y excepciones de conservación. El **propietario de los datos** (responsable del área de negocio) justifica las necesidades de información de su área y verifica que el uso corresponda a las finalidades autorizadas.

---

## 9. Evaluación integral

En el escenario integral se identificaron doce problemas y sus controles (detalle en [`evidencias/14-evaluacion-integral.md`](evidencias/14-evaluacion-integral.md)):

| # | Problema | Principio afectado | Control propuesto |
|---|---|---|---|
| 1 | Todo el personal de analítica puede consultar directamente `clientes`. | Mínimo privilegio y confidencialidad | Vista de analítica y permisos solo sobre ella. |
| 2 | Analítica accede a nombres y correos, aunque solo genera estadísticas mensuales. | Minimización | Datos agregados por ciudad, rangos de edad u otras categorías. |
| 3 | Analítica puede consultar teléfonos y RFC. | Limitación de la finalidad y mínimo privilegio | Restringir esos campos a áreas autorizadas que los necesiten. |
| 4 | Datos conservados desde hace 12 años sin justificación documentada. | Limitación del plazo de conservación | Definir periodos justificados y revisiones periódicas. |
| 5 | No existe política documentada de retención. | Responsabilidad y rendición de cuentas | Aprobar política con plazos, responsables, excepciones y disposición final. |
| 6 | Los desarrolladores reciben copias completas de la base de datos. | Minimización y confidencialidad | Entregar solo los conjuntos necesarios para cada prueba. |
| 7 | Las copias de desarrollo contienen datos personales reales. | Privacidad por diseño y seguridad | Datos sintéticos o anonimizados de forma efectiva. |
| 8 | No se especifica quién accede a las copias de desarrollo. | Control de acceso y mínimo privilegio | Permisos por rol, autenticación, almacenamiento protegido y registros de acceso. |
| 9 | Marketing usa los correos sin finalidades claras. | Limitación de la finalidad y transparencia | Revisar aviso de privacidad, finalidad original y base legal antes de las campañas. |
| 10 | No hay documentación que relacione cada dato con su finalidad. | Limitación de la finalidad y responsabilidad | Inventario y matriz de gobierno de datos. |
| 11 | No se menciona una revisión periódica de permisos. | Seguridad y mínimo privilegio | Revisar roles periódicamente y retirar permisos innecesarios. |
| 12 | No hay controles para respaldos, exportaciones y otros destinos de los datos. | Integridad, confidencialidad y ciclo de vida | Inventariar copias, restringir acceso y definir su conservación y tratamiento final. |

### Principales riesgos encontrados

1. **Acceso excesivo:** áreas que consultan datos que no necesitan (analítica, desarrollo).
2. **Conservación sin justificación:** acumulación de datos por 12 años sin política de retención.
3. **Datos reales fuera de producción:** copias completas en entornos de desarrollo con controles menos estrictos.
4. **Uso no claro de los datos:** campañas de marketing sin finalidades definidas.
5. **Falta de documentación y de revisión:** sin matriz de finalidades ni revisión periódica de permisos.
6. **Copias no controladas:** respaldos, exportaciones y otros destinos que pueden conservar datos ya eliminados del sistema principal.

### Arquitectura propuesta

Se propone separar el acceso en tres frentes (**Operación**, **Analítica** y **Auditoría**) manteniendo protegida la base original: Operación con los datos necesarios para atender clientes, Analítica con datos agregados y agrupados sin identificadores directos, y Auditoría con registros de accesos y cambios relevantes. La separación puede implementarse con esquemas, vistas, roles y permisos de PostgreSQL, además de políticas organizacionales. Es una propuesta conceptual: no significa que los controles ya estén implementados físicamente.

---

## 10. Conclusiones

La seguridad, la privacidad y la administración de bases de datos están relacionadas, pero **no son lo mismo**. La seguridad protege los datos contra accesos no autorizados, pérdidas o modificaciones; la privacidad se ocupa de que los datos personales se recopilen y utilicen de forma adecuada, con una finalidad justificada y respetando los derechos de las personas. Una base de datos puede estar muy bien protegida técnicamente y aun así incumplir la privacidad, por ejemplo si se usan los correos de los clientes para publicidad sin justificación o si los datos se conservan más tiempo del necesario.

Lo aprendido en el laboratorio:

- **La finalidad manda:** tener los datos no autoriza a usarlos para cualquier propósito. Cada dato debe relacionarse con una finalidad definida.
- **Menos es más:** recopilar y conservar solo lo necesario reduce riesgos de filtración, costos y dificultades para atender solicitudes ARCO.
- **Los permisos deben seguir las funciones:** roles, vistas y datos agregados permiten aplicar el mínimo privilegio en PostgreSQL.
- **Eliminar de una tabla no es eliminar de la organización:** respaldos, réplicas, reportes, exportaciones y sistemas externos también deben considerarse.
- **La retención forma parte del ciclo de vida de los datos** y requiere una política documentada, con responsables y procedimientos de disposición.
- **Los controles técnicos y administrativos se complementan:** los técnicos aplican la protección en los sistemas; los administrativos definen reglas, procedimientos y responsabilidades.
- **El DBA es una pieza clave, pero no decide solo:** implementa y mantiene las medidas técnicas, mientras que las decisiones sobre finalidades, legitimidad del uso, conservación y solicitudes de privacidad involucran a las áreas de negocio, privacidad y jurídica.

La protección de los datos personales requiere combinar seguridad, privacidad, minimización, control de acceso y políticas de conservación, con una adecuada distribución de responsabilidades. Así la organización puede usar la información de forma responsable, reducir riesgos y respetar los derechos de los titulares.

---

## 11. Verificación final del laboratorio

**1. Privacidad: ¿qué diferencia existe entre seguridad de la información y privacidad?**
La seguridad de la información consiste en proteger los datos contra accesos no autorizados, pérdidas, modificaciones o robos mediante controles como contraseñas, permisos, cifrado y respaldos. La privacidad se enfoca en que los datos personales se recopilen y utilicen de manera adecuada, con una finalidad justificada y respetando los derechos de las personas. Por ejemplo, una base de datos puede estar protegida con contraseñas, pero si la empresa utiliza los correos de sus clientes para enviar publicidad sin una justificación adecuada, puede existir un problema de privacidad.

**2. Finalidad: ¿por qué una organización no debería utilizar automáticamente todos los datos que posee para cualquier propósito?**
Porque los datos deben utilizarse de acuerdo con finalidades determinadas y justificadas. Que una organización tenga información no significa que pueda utilizarla para cualquier actividad. Por ejemplo, si el correo electrónico se recopiló para atender pedidos, utilizarlo posteriormente para campañas publicitarias requiere evaluar la finalidad, la base legal aplicable y los avisos o consentimientos que correspondan. Esto ayuda a evitar usos no autorizados y protege los derechos de los clientes.

**3. Minimización: ¿por qué almacenar más información no necesariamente es mejor?**
Porque recopilar y conservar datos innecesarios aumenta los riesgos de filtraciones, accesos indebidos, costos de almacenamiento y problemas para cumplir con las solicitudes de los titulares. Lo correcto es conservar únicamente los datos necesarios para cumplir una finalidad. Por ejemplo, si el área de analítica solo necesita conocer la cantidad de clientes por ciudad, puede utilizar información agrupada sin consultar nombres, teléfonos o RFC.

**4. ARCO: ¿qué implicaciones técnicas tienen los derechos de acceso, rectificación, cancelación y oposición?**
Los derechos ARCO requieren que la organización tenga procedimientos y herramientas para atender las solicitudes de los titulares. El acceso implica localizar y proporcionar la información personal que corresponda; la rectificación requiere corregir datos incorrectos; la cancelación puede implicar bloquear o eliminar datos cuando proceda, considerando las obligaciones de conservación; y la oposición requiere evaluar y, cuando corresponda, detener determinados usos de los datos. Técnicamente, pueden necesitarse consultas SQL, actualización de registros, controles de acceso, procesos de eliminación y revisión de copias en respaldos, reportes y otros sistemas.

**5. Retención: ¿por qué la conservación indefinida puede representar un riesgo?**
Porque los datos que se conservan sin una justificación pueden quedar expuestos durante más tiempo, utilizarse para finalidades incompatibles y generar dificultades para atender solicitudes de cancelación. La organización debe establecer periodos de conservación según la finalidad, las necesidades operativas y las obligaciones legales aplicables. Cuando los datos dejan de ser necesarios y no existe una obligación válida de conservarlos, debe aplicarse un procedimiento documentado de eliminación o disposición.

**6. Gobierno: ¿quién debería decidir qué datos pueden utilizarse y para qué finalidad?**
La decisión debe involucrar a las áreas responsables del negocio, privacidad o cumplimiento legal, seguridad de la información y, cuando corresponda, las áreas operativas y de analítica. Estas áreas deben determinar la finalidad, justificar el uso de los datos y establecer las reglas de acceso y conservación. La decisión no debe quedar únicamente en manos del DBA, porque también implica responsabilidades organizacionales y legales.

**7. DBA: ¿cuál es la responsabilidad del DBA y cuáles decisiones deben involucrar a otras áreas?**
El administrador de bases de datos (DBA) es responsable de implementar y mantener controles técnicos, como roles, permisos, vistas, respaldos, disponibilidad, auditoría y mecanismos de protección. También debe apoyar la ejecución controlada de modificaciones y eliminaciones autorizadas. Sin embargo, las decisiones sobre las finalidades del tratamiento, la legitimidad del uso de los datos, los periodos de conservación y la resolución de solicitudes de privacidad deben involucrar a las áreas responsables. El DBA implementa las medidas técnicas autorizadas y asesora sobre sus implicaciones, pero no debe decidir por sí solo cómo puede utilizarse la información personal.

---

## 12. Preguntas de reflexión

**1. ¿Una base de datos técnicamente segura necesariamente cumple con todos los requisitos de privacidad?**
No necesariamente. Una base de datos puede contar con contraseñas seguras, cifrado y controles de acceso, pero aun así utilizar los datos personales para finalidades no justificadas o conservarlos durante más tiempo del necesario. La seguridad protege la información, mientras que la privacidad también considera cómo, por qué y durante cuánto tiempo se utilizan los datos.

**2. ¿Por qué el principio de mínimo privilegio también contribuye a la privacidad?**
Porque establece que cada usuario debe tener acceso únicamente a la información necesaria para realizar sus funciones. Esto reduce la posibilidad de que personas no autorizadas consulten o utilicen datos personales. Por ejemplo, el área de analítica puede consultar estadísticas por ciudad sin tener acceso directo a los nombres, teléfonos y RFC de los clientes.

**3. ¿Por qué el DBA no debería decidir por sí solo la finalidad del tratamiento de los datos?**
Porque determinar la finalidad implica decisiones organizacionales y legales que van más allá de la administración técnica de una base de datos. El DBA puede explicar qué controles son posibles e implementarlos, pero las finalidades deben definirse con la participación de los responsables del negocio y de las áreas de privacidad y cumplimiento jurídico.

**4. ¿Por qué los desarrolladores no deberían recibir automáticamente copias completas de bases de datos productivas?**
Porque las bases de datos productivas pueden contener información personal y confidencial que los desarrolladores no necesitan para realizar sus tareas. Entregar copias completas aumenta el riesgo de filtraciones, accesos indebidos y uso de los datos para otras finalidades. Es preferible proporcionar datos ficticios, anonimizados o una muestra mínima que permita realizar las pruebas necesarias.

**5. ¿Por qué una copia utilizada para desarrollo también puede representar un riesgo de privacidad?**
Porque una copia puede contener los mismos datos personales que la base de datos original, aunque se utilice en un entorno diferente. Si tiene permisos menos restrictivos, se almacena en equipos personales o se comparte sin controles adecuados, la información puede quedar expuesta. Por eso, las copias deben protegerse, limitarse y eliminarse cuando dejen de ser necesarias.

**6. ¿Por qué la retención debe formar parte del ciclo de vida de los datos?**
Porque los datos no deben conservarse indefinidamente sin una finalidad justificada. Desde su recopilación hasta su eliminación, la organización debe determinar cuánto tiempo necesita conservarlos y qué hacer cuando dejan de ser necesarios. Esto ayuda a reducir riesgos, cumplir con las obligaciones aplicables y gestionar adecuadamente respaldos, archivos y otras copias.

**7. ¿Qué relación existe entre privacidad por diseño y diseño de bases de datos?**
La privacidad por diseño consiste en incorporar medidas de protección desde que se planea y construye un sistema, en lugar de agregarlas después de que ocurre un problema. En el diseño de bases de datos se refleja al recopilar solo los campos necesarios, separar la información por finalidad, establecer permisos adecuados y planear la retención y eliminación desde el inicio.

**8. ¿Qué controles técnicos implementarías para reducir el riesgo de exposición de datos personales?**
Implementaría roles y permisos basados en las funciones de cada usuario, vistas que oculten los datos innecesarios, cifrado de información sensible cuando corresponda, conexiones seguras, respaldos protegidos y registros de auditoría. También limitaría las exportaciones, revisaría periódicamente los permisos y utilizaría datos ficticios o anonimizados en los entornos de desarrollo y pruebas.

**9. ¿Qué información debería conocer un DBA para responder técnicamente a una solicitud ARCO?**
Debería conocer dónde se encuentran los datos personales, qué tablas y sistemas los contienen, quién puede consultarlos, cómo se modifican y cuánto tiempo se conservan. También necesita identificar las copias existentes en respaldos, reportes, exportaciones y sistemas relacionados, así como conocer los procedimientos autorizados para localizar, corregir, bloquear o eliminar datos y registrar las acciones realizadas. La respuesta final debe coordinarse con las áreas responsables y respetar las obligaciones legales aplicables.

**10. ¿Qué responsabilidades deberían corresponder al DBA, al responsable de privacidad, al área jurídica y al propietario de los datos?**
El DBA debe administrar las bases de datos, implementar permisos, proteger respaldos, mantener la disponibilidad y registrar las operaciones relevantes. El responsable de privacidad debe coordinar las políticas de tratamiento, revisar las finalidades y apoyar la atención de los derechos de los titulares. El área jurídica debe asesorar sobre las obligaciones legales, las bases que justifican el tratamiento y las excepciones de conservación aplicables. El propietario de los datos o responsable del área de negocio debe justificar las necesidades de información de su área y asegurarse de que su uso corresponda a las finalidades autorizadas. Estas responsabilidades deben coordinarse para proteger los datos y evitar decisiones aisladas.

---

## Evidencias del laboratorio

| Actividad | Archivo |
|---|---|
| 1. Inventario y finalidad de los datos | [`evidencias/01-inventario-datos.md`](evidencias/01-inventario-datos.md) |
| 5. Finalidad secundaria | [`evidencias/05-finalidad-secundaria.md`](evidencias/05-finalidad-secundaria.md) |
| 6. Derechos ARCO (acceso) | [`evidencias/06-derechos-arco.md`](evidencias/06-derechos-arco.md) |
| 8. Derecho de cancelación y ciclo de vida | [`evidencias/08-ciclo-vida.md`](evidencias/08-ciclo-vida.md) |
| 10. Política de retención | [`evidencias/10-retencion.md`](evidencias/10-retencion.md) |
| 11. Matriz de gobierno de datos | [`evidencias/11-gobierno-datos.md`](evidencias/11-gobierno-datos.md) |
| 12. Privacidad por diseño | [`evidencias/12-privacidad-diseno.md`](evidencias/12-privacidad-diseno.md) |
| 14. Escenario integral | [`evidencias/14-evaluacion-integral.md`](evidencias/14-evaluacion-integral.md) |
| 15. Arquitectura de datos protegidos | [`evidencias/15-arquitectura.md`](evidencias/15-arquitectura.md) |

Las actividades 2, 3, 4, 9 y 13 no generan un archivo propio en `evidencias/`; su análisis está integrado en las secciones 3 a 6 de este informe.
