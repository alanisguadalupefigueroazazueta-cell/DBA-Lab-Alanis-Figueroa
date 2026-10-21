# Actividad 15 — Propuesta de arquitectura de datos protegidos

## Objetivo

Diseñar una arquitectura conceptual para separar la información de los clientes de acuerdo con su finalidad, aplicando los principios de minimización de datos, control de acceso, protección de información sensible, retención, trazabilidad y atención de solicitudes relacionadas con la privacidad.

## Procedimiento

Se propone una arquitectura para la empresa Comercializadora Norte S.A. de C.V., tomando como referencia la tabla original `clientes`, que contiene información como nombre, correo electrónico, teléfono, RFC, edad, ciudad, código postal y fecha de alta.

La propuesta consiste en separar el acceso a la información en áreas con funciones específicas. De esta manera, cada área utilizará únicamente los datos que necesita para realizar sus actividades.

### 1. Diseño conceptual de la arquitectura

```text
                    BASE DE DATOS
                          |
          +---------------+---------------+
          |               |               |
          v               v               v
      OPERACIÓN        ANALÍTICA       AUDITORÍA
          |               |               |
          v               v               v
    Datos necesarios  Datos agregados  Registros de
    para atender      y agrupados      accesos y cambios
    a los clientes    por ciudad       relevantes
          |               |               |
          v               v               v
    Acceso limitado   Sin identificadores Acceso restringido
    según funciones   directos cuando     y revisión periódica
                      sea posible
```

La base de datos original se mantendría protegida. Las áreas de operación, analítica y auditoría tendrían permisos diferentes, según sus responsabilidades. La separación puede implementarse mediante esquemas, vistas, roles y permisos de PostgreSQL, además de políticas organizacionales.

### 2. Controles de privacidad propuestos

**Control de acceso**

Se crearían roles diferentes para operación, analítica y auditoría. Cada rol recibiría únicamente los permisos necesarios. Por ejemplo, el personal de analítica podría consultar una vista con ciudad y rangos de edad, sin tener acceso directo al nombre, correo, teléfono o RFC de los clientes.

**Minimización de datos**

Cada área utilizaría solamente la información indispensable para cumplir su finalidad. Para generar estadísticas mensuales, analítica utilizaría datos agrupados, como el número de clientes por ciudad, en lugar de consultar todos los datos personales de cada cliente.

**Protección de información sensible**

Los datos personales, como el RFC, el teléfono y el correo electrónico, tendrían acceso restringido. Se aplicarían medidas como cifrado cuando corresponda, conexiones seguras, vistas con información limitada y protección de respaldos. Las contraseñas y claves criptográficas no se guardarían directamente en archivos públicos ni en el repositorio del proyecto.

**Retención**

Se establecería una política que indique qué datos se conservan, con qué finalidad, durante cuánto tiempo y quién autoriza su conservación. Los plazos se definirían de acuerdo con las necesidades operativas y las obligaciones legales aplicables, sin conservar indefinidamente la información solo porque pudiera ser útil.

**Trazabilidad**

Se registrarían los accesos y las operaciones relevantes, como consultas administrativas, modificaciones de permisos, exportaciones y eliminaciones autorizadas. Los registros tendrían acceso restringido y se revisarían periódicamente para detectar actividades inusuales.

**Eliminación**

Cuando los datos ya no sean necesarios y no exista una obligación válida de conservarlos, se aplicaría un procedimiento de eliminación segura. Antes de eliminar información, se revisarían las copias existentes en respaldos, reportes, exportaciones y otros sistemas. La eliminación de los respaldos seguiría un procedimiento documentado y compatible con su ciclo de vida.

**Atención de solicitudes**

Se establecería un procedimiento para recibir, verificar, documentar y atender las solicitudes de los titulares de los datos, incluidas las relacionadas con los derechos ARCO: acceso, rectificación, cancelación y oposición. El personal responsable evaluaría cada solicitud y coordinaría las acciones técnicas necesarias, considerando las obligaciones legales de conservación que pudieran aplicar.

### 3. Responsabilidades por área

| Área | Información utilizada | Control principal |
|---|---|---|
| Operación | Datos necesarios para atender a los clientes | Acceso limitado por función |
| Analítica | Datos agregados y agrupados | Vistas y minimización |
| Auditoría | Registros de acceso y cambios relevantes | Permisos restringidos y revisión |
| Administración de la base de datos | Acceso técnico según responsabilidades autorizadas | Roles, permisos y registro de actividades |
| Privacidad o cumplimiento | Información necesaria para evaluar solicitudes y políticas | Procedimientos documentados y seguimiento |

### 4. Aplicación en PostgreSQL

Como primera etapa, se podrían utilizar roles y vistas para limitar el acceso sin construir una infraestructura completamente nueva.

Por ejemplo, se puede preparar una vista de analítica:

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

La vista presenta ciudad y rango de edad, sin incluir directamente nombre, correo, teléfono o RFC. Para estadísticas, sería preferible consultar información agrupada y evaluar el riesgo de identificar personas en grupos pequeños.

En el proyecto existente, se utilizaría el rol `analista_alanis_figueroa` y se le concederían únicamente los permisos necesarios sobre la vista autorizada. No se deben volver a crear roles que ya existen ni otorgar acceso a la tabla original sin una justificación.

**Nota:** este código es un ejemplo conceptual. La vista y los permisos deben verificarse en PostgreSQL antes de afirmar que fueron implementados. Además, una vista que contiene filas individuales no equivale por sí sola a datos agregados; para estadísticas se pueden utilizar consultas con `GROUP BY`.

## Resultado

Se propone una arquitectura que separa los datos operativos, analíticos y de auditoría según su finalidad. La solución contempla permisos diferenciados, uso limitado de datos personales, protección de información sensible, políticas de retención, registros de actividad, eliminación controlada y atención de solicitudes de los titulares.

## Análisis

La separación por finalidad disminuye la exposición de los datos personales, ya que evita que todas las áreas tengan acceso a la información completa de los clientes. Las vistas y los roles permiten aplicar el principio de mínimo privilegio en PostgreSQL. Sin embargo, estos controles deben complementarse con procedimientos administrativos, revisiones periódicas y reglas para respaldos, exportaciones y otros sistemas.

La arquitectura es una propuesta conceptual y no significa que todas las áreas o controles estén implementados físicamente. Su implementación debe planearse de acuerdo con los recursos y las necesidades reales de la organización.

## Conclusión

Una arquitectura de datos protegidos permite relacionar los principios de privacidad con decisiones técnicas concretas. Separar la información por finalidad, limitar los permisos y utilizar únicamente los datos necesarios reduce los riesgos de acceso indebido y uso no autorizado. Para que la protección sea efectiva, también se necesitan políticas de conservación y eliminación, trazabilidad y un procedimiento formal para atender las solicitudes de los titulares.
