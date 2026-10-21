# Actividad 12 — Privacidad por diseño

## Objetivo

Analizar el diseño de una tabla para registrar clientes e identificar los riesgos de recopilar información personal innecesaria, aplicando los principios de minimización de datos, limitación de la finalidad y privacidad por defecto.

## Procedimiento

Se revisó la propuesta de crear una tabla que almacene diversos datos personales, como nombre, correo, teléfono, RFC, edad, dirección, fecha de nacimiento, ocupación, salario y estado civil. El desarrollador justifica su inclusión indicando que podrían ser útiles en el futuro.

### 1. ¿Qué problemas identificas?

El principal problema es que se propone almacenar demasiada información personal sin definir para qué se utilizará cada dato. Esto puede provocar una recopilación innecesaria de información, aumentar los riesgos de filtración o acceso no autorizado y generar mayores responsabilidades de almacenamiento, protección y eliminación.

También existe el riesgo de que los datos se utilicen posteriormente para finalidades distintas de aquellas para las que fueron recopilados. Además, algunos campos, como el salario, la ocupación, el estado civil y la fecha de nacimiento, pueden revelar información adicional sobre la vida de una persona y requieren especial atención.

### 2. ¿Qué principio de privacidad se está ignorando?

Se está ignorando principalmente el principio de **minimización de datos**, porque se propone recopilar información sin comprobar que sea necesaria para una finalidad concreta.

También se relaciona con el principio de limitación de la finalidad, ya que los datos deben recopilarse para propósitos determinados y no simplemente porque podrían resultar útiles en el futuro.

### 3. ¿Qué preguntas realizarías antes de aprobar el diseño?

Antes de aprobar la tabla, realizaría las siguientes preguntas:

- ¿Cuál es la finalidad principal de la aplicación?
- ¿Qué función cumple cada dato que se propone almacenar?
- ¿Es indispensable cada campo para prestar el servicio?
- ¿Quién tendrá acceso a cada dato?
- ¿Durante cuánto tiempo será necesario conservar la información?
- ¿Se utilizarán los datos para otras finalidades, como publicidad o análisis?
- ¿Qué información se comunicará a los clientes en el aviso de privacidad?
- ¿Qué medidas de seguridad protegerán los datos almacenados?
- ¿Existen alternativas que permitan trabajar con menos información, como rangos o datos agregados?

Las respuestas permitirían justificar los campos necesarios y eliminar aquellos que no aporten a la finalidad de la aplicación.

### 4. ¿Qué datos eliminarías?

Si la aplicación únicamente necesita registrar clientes y permitir el contacto básico, eliminaría inicialmente los campos que no sean indispensables para esa función, como RFC, edad, dirección completa, fecha de nacimiento, ocupación, salario y estado civil.

Conservaría un identificador único y los datos mínimos necesarios para el servicio, por ejemplo, nombre y correo electrónico. El teléfono se incluiría solo si existe una necesidad concreta de comunicación mediante ese medio.

Esta decisión depende de la finalidad real: si la aplicación también realiza facturación, podría necesitar el RFC y otros datos fiscales justificados. Por ello, no se deben eliminar campos automáticamente sin analizar primero los requisitos del servicio.

### 5. ¿Qué datos requerirían una justificación adicional?

Los siguientes campos necesitarían una justificación específica antes de incorporarse:

- **RFC:** para procesos fiscales o de facturación que realmente lo requieran.
- **Edad y fecha de nacimiento:** para verificar requisitos de edad u otra finalidad concreta. En algunos casos, bastaría con conocer si la persona cumple una condición de edad.
- **Dirección y código postal:** para entregas, facturación u operaciones que requieran ubicación.
- **Ocupación:** únicamente si una función específica necesita esa información.
- **Salario:** si existe una finalidad legítima y claramente definida que lo requiera.
- **Estado civil:** si es indispensable para un trámite o servicio concreto.

La empresa debe evitar recopilar datos sensibles o de carácter personal adicional sin una necesidad clara, una finalidad definida y las medidas de protección correspondientes.

### 6. ¿Cómo aplicarías privacidad por defecto?

Aplicaría privacidad por defecto configurando la aplicación para que recopile únicamente los datos indispensables y limite su acceso desde el inicio. Cada área tendría permisos acordes con sus funciones y no podría consultar automáticamente todos los campos de la tabla.

También establecería periodos de retención justificados, protección de credenciales, controles de acceso, registros de auditoría y mecanismos para atender solicitudes relacionadas con los datos personales. Si una función opcional requiere información adicional, se solicitaría únicamente cuando sea necesaria y se informaría al usuario sobre su finalidad.

Por ejemplo, el área de atención al cliente podría utilizar una vista con el identificador, nombre y correo, mientras que el área de facturación tendría acceso a los datos fiscales que necesite. Los permisos deberían configurarse de forma restrictiva desde la creación del sistema, en lugar de permitir todo y limitarlo posteriormente.

## Resultado

Se identificaron riesgos asociados con la recopilación excesiva de información personal y se propusieron criterios para determinar qué campos deben incluirse, cuáles requieren una justificación adicional y qué medidas técnicas pueden limitar el acceso.

## Análisis

Guardar todos los datos por si fueran útiles en el futuro no constituye una justificación suficiente. Cada campo debe responder a una necesidad concreta y relacionarse con una finalidad definida. Una tabla con información excesiva incrementa los riesgos de privacidad y seguridad, mientras que un diseño basado en la minimización permite reducir la exposición de datos desde el inicio.

## Conclusión

La privacidad por diseño consiste en incorporar la protección de los datos personales desde la planificación de una aplicación. Para ello, se deben definir las finalidades, recopilar solo la información necesaria, justificar los campos adicionales y establecer controles de acceso, seguridad y retención. De esta manera, la organización puede desarrollar un sistema funcional sin almacenar información personal innecesaria.
