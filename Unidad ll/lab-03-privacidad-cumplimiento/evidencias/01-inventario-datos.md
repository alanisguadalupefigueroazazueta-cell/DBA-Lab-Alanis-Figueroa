# Evidencia 01. Inventario y finalidad de los datos

## 1. Objetivo

Identificar y clasificar los datos almacenados por Comercializadora Norte S.A. de C.V., estableciendo su finalidad, necesidad, nivel de acceso y periodo de conservación. El propósito es aplicar los principios de minimización de datos, privacidad y acceso limitado según las funciones de cada área.

## 2. Procedimiento

Se revisaron los nueve campos que contiene el registro de clientes de la empresa. Para cada campo se analizó si permite identificar a una persona, qué uso justificado puede tener, si es indispensable para los procesos del negocio, qué áreas deben tener acceso y bajo qué criterios debe conservarse.

Se consideraron las funciones de Atención al cliente, Facturación, Analítica y el administrador de bases de datos (DBA).

## 3. Matriz de inventario de datos

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retención |
|---|---|---|---|---|---|
| `id` | No directamente, pero puede identificar indirectamente al cliente al relacionarse con otros datos. | Identificar cada registro de forma única. | Sí, para administrar los registros. | Atención al cliente, Facturación y DBA; Analítica solo si lo requiere técnicamente. | Mientras existan registros que lo necesiten; eliminar o anonimizar cuando corresponda. |
| `nombre` | Sí, identifica a una persona física. | Identificar y atender al cliente; elaborar facturas cuando corresponda. | Sí, para atención y facturación. | Atención al cliente, Facturación y DBA autorizado. Analítica no necesita verlo. | Mientras sea necesario para la relación comercial y durante el periodo exigido por las obligaciones aplicables. |
| `correo` | Sí, permite contactar e identificar a una persona. | Enviar comunicaciones relacionadas con el servicio y atender solicitudes. | Sí, si se utiliza como medio de contacto; de lo contrario, debe evaluarse su necesidad. | Atención al cliente y DBA autorizado; otras áreas solo con justificación. | Mientras sea necesario para la finalidad de contacto y las obligaciones aplicables. |
| `telefono` | Sí, permite contactar a una persona. | Realizar llamadas o comunicaciones necesarias para la atención. | Condicional; depende de que el proceso requiera este medio de contacto. | Atención al cliente y DBA autorizado; acceso adicional únicamente justificado. | Mientras sea necesario para el contacto y las obligaciones aplicables. |
| `rfc` | Sí, cuando identifica o se vincula con una persona física. | Identificación fiscal y elaboración de facturas. | Sí, para los procesos fiscales que lo requieran; no para todas las áreas. | Facturación y personal autorizado; DBA sujeto a controles. Analítica sin acceso directo. | Durante el periodo requerido por las obligaciones fiscales y demás disposiciones aplicables. |
| `edad` | Sí, cuando está asociada con una persona identificada o identificable. | Estadísticas demográficas o procesos que justifiquen conocer la edad. | No necesariamente; debe justificarse antes de recopilarla o conservarla. | Personal autorizado cuando exista una finalidad válida. Analítica preferentemente mediante grupos agregados. | Hasta que deje de ser necesaria para la finalidad justificada, salvo obligación aplicable. |
| `ciudad` | Puede serlo cuando se relaciona con otros datos que permiten identificar al cliente. | Atención relacionada con ubicación y elaboración de estadísticas. | Sí, cuando se necesite para el servicio o para estadísticas; de lo contrario, puede omitirse. | Atención al cliente y Facturación cuando corresponda; Analítica mediante datos agregados. | Mientras sea necesaria para la finalidad y las obligaciones aplicables. |
| `codigo_postal` | Puede serlo cuando se vincula con otros datos personales y permite identificar o localizar a alguien. | Procesos postales, comerciales o fiscales que lo requieran. | Condicional; no es necesario para todas las operaciones. | Personal autorizado según el proceso; Analítica solo si aporta valor estadístico. | Mientras sea necesario para el proceso correspondiente y las obligaciones aplicables. |
| `fecha_alta` | Puede serlo cuando está vinculada al registro de un cliente identificable. | Conocer la fecha de registro, antigüedad y evolución de la relación comercial. | Sí, si se necesita administrar la relación o generar estadísticas justificadas. | Atención al cliente, Facturación cuando corresponda, Analítica y DBA según sus funciones. | Mientras se necesite para la administración, las estadísticas justificadas y las obligaciones aplicables. |

## 4. Justificación de las decisiones

### 4.1. Identificador (`id`)

Aunque el identificador no contiene necesariamente el nombre del cliente, puede relacionarse con el registro original y permitir su identificación indirecta. Por ello, no debe considerarse automáticamente anónimo. Se conserva mientras sea necesario para relacionar y administrar registros.

### 4.2. Nombre

Es necesario para reconocer al cliente durante la atención y para los procesos de facturación que lo requieran. No se justifica que el área de Analítica consulte nombres si únicamente necesita producir estadísticas generales.

### 4.3. Correo electrónico

Se utiliza para contactar al cliente y responder solicitudes. El acceso debe limitarse a quienes necesitan comunicarse con él. Si la empresa puede cumplir una finalidad sin conservar el correo, debe evaluar su eliminación o la limitación de su uso.

### 4.4. Teléfono

Permite realizar comunicaciones relacionadas con el servicio. Su recopilación y conservación deben justificarse según las necesidades reales de Atención al cliente. No debe estar disponible para todas las áreas por defecto.

### 4.5. RFC

Es necesario para las operaciones fiscales que lo requieran. Debe tener acceso restringido porque es un dato de identificación fiscal y puede vincularse con una persona física. Analítica debe trabajar con información agregada o transformada cuando no necesite conocer el RFC.

### 4.6. Edad

La edad no siempre es indispensable para administrar una relación comercial. Antes de recopilarla o conservarla, debe identificarse una finalidad concreta. Si solo se necesitan estadísticas, se pueden utilizar grupos de edad para reducir la exposición de datos individuales.

### 4.7. Ciudad

Puede servir para atender necesidades de ubicación y realizar estadísticas comerciales. Cuando se utiliza para análisis, es preferible presentar cantidades por ciudad en lugar de registros individuales identificables.

### 4.8. Código postal

Puede ser necesario para envíos o trámites que requieran información postal. Si ningún proceso lo necesita, debe evaluarse su eliminación. Combinado con otros datos, puede facilitar la identificación o localización de una persona.

### 4.9. Fecha de alta

Ayuda a administrar la antigüedad del cliente y a elaborar estadísticas sobre registros nuevos. Debe conservarse durante el tiempo necesario para esos fines y las obligaciones aplicables, sin mantener indefinidamente los registros personales solo porque la información pueda resultar útil en el futuro.

## 5. Resultado

Se identificaron los nueve campos de la base de datos y se establecieron criterios iniciales de clasificación, finalidad, necesidad, acceso y retención.

El análisis permite distinguir los datos que requieren acceso operativo, como el nombre y los medios de contacto, de aquellos que deben limitarse a procesos específicos, como el RFC. También identifica campos cuya necesidad debe justificarse, como la edad y el código postal.

Los periodos definitivos de conservación no se establecen únicamente por decisión técnica: deben verificarse con las obligaciones legales, la finalidad del tratamiento y las políticas de retención de la empresa.

## 6. Análisis

El inventario muestra que almacenar un dato no significa que todas las áreas deban consultarlo. Cada permiso debe responder a una necesidad funcional y cada campo debe tener una finalidad definida.

La minimización de datos puede aplicarse reduciendo la información recopilada, restringiendo las consultas y utilizando resultados agregados para Analítica. El acceso administrativo del DBA también debe estar sujeto a controles, auditoría y procedimientos autorizados.

La retención debe considerar tanto la necesidad de conservar los datos como las obligaciones aplicables. Cuando la finalidad termina y no existe otra obligación válida de conservación, deben evaluarse la eliminación o la anonimización irreversible, según corresponda.

## 7. Conclusión

El inventario de datos permite identificar qué información utiliza la empresa, para qué la necesita y quién debe acceder a ella. Se concluye que la privacidad debe incorporarse desde el diseño de la base de datos mediante minimización, permisos limitados y periodos de conservación justificados. Estas medidas reducen la exposición de información personal y ayudan a mantener una administración más segura y responsable de los datos.
