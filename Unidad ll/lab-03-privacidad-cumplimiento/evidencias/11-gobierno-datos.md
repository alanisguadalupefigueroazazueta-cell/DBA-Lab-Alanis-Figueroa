# Actividad 11 — Diseñar una matriz de gobierno de datos

## Objetivo

Establecer reglas para administrar y proteger los datos personales de los clientes, relacionando cada dato con su finalidad, los responsables de su tratamiento, los usuarios autorizados, las medidas de protección y el periodo de retención.

## Matriz de gobierno de datos

| Dato | Finalidad | Responsable | Usuarios autorizados | Protección | Retención | Acción al finalizar |
|---|---|---|---|---|---|---|
| nombre | Identificar al cliente y atender sus solicitudes. | Atención al cliente | Atención al cliente; facturación cuando sea necesario | Control de acceso por roles y acceso limitado. | Mientras sea necesario para la finalidad y durante los plazos aplicables. | Eliminar o bloquear cuando corresponda, salvo obligación de conservación. |
| correo | Contactar al cliente y enviar comunicaciones autorizadas. | Atención al cliente | Atención al cliente; marketing únicamente para finalidades autorizadas | Acceso restringido, protección de credenciales y registro de accesos. | Durante el tiempo necesario para las comunicaciones autorizadas y las obligaciones aplicables. | Eliminar o dejar de utilizar para la finalidad correspondiente cuando proceda. |
| telefono | Contactar al cliente para atender solicitudes o dar seguimiento a servicios. | Atención al cliente | Atención al cliente y otras áreas cuando exista una necesidad justificada | Acceso por roles y uso limitado a la finalidad autorizada. | Mientras sea necesario para la atención y durante los plazos aplicables. | Eliminar o bloquear cuando deje de ser necesario, según corresponda. |
| rfc | Identificación fiscal y cumplimiento de obligaciones de facturación. | Facturación | Personal autorizado de facturación y DBA únicamente para tareas técnicas justificadas | Acceso restringido, permisos específicos y protección de respaldos. | Durante los plazos fiscales y legales aplicables. | Eliminar o bloquear cuando corresponda y hayan terminado las obligaciones de conservación. |
| edad | Clasificación estadística o segmentación justificada por una finalidad autorizada. | Analítica | Analítica mediante datos agrupados o una vista limitada; otras áreas solo si lo necesitan | Utilizar rangos de edad cuando sean suficientes y evitar exponer datos identificables. | Durante el tiempo necesario para la finalidad estadística autorizada. | Eliminar, anonimizar o dejar de utilizar cuando corresponda. |
| ciudad | Atención relacionada con ubicación y elaboración de estadísticas geográficas. | Atención al cliente / Analítica | Atención al cliente para necesidades justificadas y Analítica mediante datos agrupados | Limitar el acceso y utilizar agregaciones cuando sea posible. | Mientras sea necesaria para la finalidad autorizada. | Eliminar o anonimizar cuando proceda y deje de ser necesaria. |
| codigo_postal | Ubicación aproximada para servicios, entregas u operaciones justificadas. | Atención al cliente | Atención al cliente y otras áreas únicamente cuando sea necesario | Control de acceso y exposición limitada; evitar combinarlo innecesariamente con otros identificadores. | Durante el tiempo necesario para el servicio y los plazos aplicables. | Eliminar, anonimizar o bloquear cuando corresponda. |

## Responsabilidades de los roles

**Atención al cliente:** consulta los datos indispensables para identificar al cliente, responder solicitudes y dar seguimiento a los servicios.

**Facturación:** accede a los datos fiscales necesarios para elaborar comprobantes y cumplir las obligaciones correspondientes.

**Analítica:** trabaja preferentemente con datos agrupados, rangos y vistas limitadas, evitando acceder a identificadores directos cuando no sean necesarios.

**DBA:** administra la base de datos, los permisos, los respaldos y la seguridad técnica. Su función administrativa no implica autorización para utilizar libremente los datos personales.

**Dirección:** autoriza políticas y supervisa su cumplimiento, en coordinación con las áreas responsables de privacidad y cumplimiento.

## Resultado

Se elaboró una matriz que relaciona cada campo de la tabla `clientes` con su finalidad, responsable, usuarios autorizados, medidas de protección, criterios de retención y acciones al finalizar su periodo de uso.

## Análisis

La matriz permite establecer que no todos los usuarios necesitan acceso a todos los datos. Por ejemplo, facturación requiere el RFC para cumplir sus funciones, mientras que analítica puede trabajar con rangos de edad y estadísticas por ciudad. La aplicación de permisos específicos, vistas limitadas y periodos de retención justificados reduce la exposición innecesaria de información personal.

Los periodos de retención indicados son criterios generales y deben concretarse de acuerdo con las finalidades, las obligaciones legales y las políticas aprobadas por la organización.

## Conclusión

El gobierno de datos permite definir quién puede utilizar cada dato, para qué finalidad y bajo qué condiciones. Relacionar los permisos con las necesidades funcionales ayuda a aplicar la minimización de datos, el mínimo privilegio y la responsabilidad sobre la información personal.
