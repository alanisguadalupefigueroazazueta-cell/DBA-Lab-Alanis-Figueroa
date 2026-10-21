# Actividad 5 — Analizar una finalidad secundaria

## Objetivo

Analizar si la empresa puede utilizar los datos personales de sus clientes para una nueva finalidad, como enviar promociones personalizadas según la edad, ciudad y comportamiento de compra, identificando los datos necesarios y los controles que deben aplicarse para proteger la privacidad.

## Procedimiento

Se analizó la propuesta de utilizar la información de los clientes para actividades de marketing. Se consideraron los principios de limitación de la finalidad, minimización de datos, control de acceso y protección de los datos personales.

### 1. ¿El hecho de que la organización ya tenga los datos significa automáticamente que puede utilizarlos para cualquier finalidad?

No. El hecho de que la empresa tenga los datos personales de sus clientes no significa que pueda utilizarlos para cualquier propósito. La información debe tratarse de acuerdo con la finalidad para la que fue recopilada, el aviso de privacidad aplicable y las obligaciones legales correspondientes. Antes de utilizarla para enviar promociones personalizadas, la empresa debe revisar si este nuevo uso es compatible con la finalidad original y si necesita informar al cliente u obtener su consentimiento.

### 2. ¿Qué preguntas debería realizar la organización antes de implementar este tratamiento?

La organización debería preguntarse para qué se utilizarán las promociones, si esta nueva finalidad es compatible con la finalidad original, qué datos son indispensables para personalizarlas y si existe una base legal para realizar el tratamiento. También debe revisar qué se informó a los clientes en el aviso de privacidad, si se requiere su consentimiento, quién tendrá acceso a los datos, cómo se protegerá la información y cómo podrán los clientes oponerse a recibir publicidad.

### 3. ¿Qué datos serían realmente necesarios?

Para realizar una segmentación básica podrían utilizarse la ciudad, un rango de edad y las categorías generales de productos comprados. Si es necesario identificar al destinatario para enviarle una promoción, podría utilizarse su correo electrónico o un identificador interno, siempre que exista una justificación para ello. El nombre completo, el teléfono y el RFC no serían necesarios para realizar la segmentación básica, salvo que exista una necesidad específica y justificada. Se debe evitar recopilar o utilizar información adicional que no aporte al objetivo de la campaña.

### 4. ¿Necesitaría el área de marketing acceso directo a `clientes`?

No necesariamente. El área de marketing no debería tener acceso directo a toda la tabla `clientes` si puede realizar sus funciones mediante una vista o una tabla preparada con los datos estrictamente necesarios. De esta manera, se evita que el personal consulte información personal o fiscal que no necesita para sus actividades. Si se requiere identificar a los destinatarios, el acceso a esos datos debe estar justificado, limitado y autorizado.

### 5. ¿Qué controles técnicos podrían limitar la información entregada?

La empresa podría implementar vistas SQL que muestren únicamente los datos necesarios para las campañas, permisos específicos mediante roles, consultas que agrupen a los clientes por rangos de edad o ciudad, seudonimización mediante identificadores internos y restricciones para impedir el acceso a la tabla original. También puede aplicar registros de auditoría para revisar quién consulta la información y utilizar controles de acceso basados en el principio de mínimo privilegio.

## Resultado

El análisis permitió identificar que el uso de los datos para promociones personalizadas constituye una finalidad que debe evaluarse antes de implementarse. No se debe asumir que disponer de los datos autoriza automáticamente su reutilización. También se determinó que es posible reducir la exposición de información personal mediante vistas, permisos limitados y datos agrupados o seudonimizados.

## Análisis

La propuesta puede ser útil para la empresa, pero debe implementarse de manera responsable. La organización necesita justificar la finalidad, determinar qué datos son indispensables y revisar las obligaciones de privacidad aplicables. El acceso directo a la tabla original aumentaría el riesgo de exposición de información innecesaria. Por ello, es preferible proporcionar al área de marketing una fuente de datos limitada a sus funciones.

## Conclusión

La empresa no debe utilizar los datos personales para cualquier finalidad únicamente porque ya los posee. Antes de enviar promociones personalizadas, debe evaluar la compatibilidad de la nueva finalidad, cumplir las obligaciones de información y consentimiento que correspondan y aplicar medidas técnicas para limitar el acceso. La minimización de datos, el control de acceso y el principio de mínimo privilegio ayudan a reducir los riesgos y proteger la privacidad de los clientes.
