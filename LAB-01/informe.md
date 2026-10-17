# Informe

## Clasificación

Los datos que requieren protección son todos los campos de la tabla `clientes`, aunque por motivos distintos:

- **Identifican directamente a una persona:** `nombre`, `correo`, `telefono` y `rfc`. Permiten reconocer, contactar o localizar a un cliente; el RFC es además un identificador fiscal que puede vincularse con otros datos personales.
- **Pueden contribuir a identificar (cuasi-identificadores):** `id`, `edad`, `ciudad`, `codigo_postal` y `fecha_alta`. Por separado generalmente no revelan quién es la persona, pero su combinación reduce el grupo de personas posibles y facilita la reidentificación, sobre todo si se cruzan con información externa.

La clasificación permite decidir qué información puede consultar cada usuario según sus funciones y qué medida de protección corresponde. Proteger un dato en una organización no implica que sea un dato personal sensible en sentido jurídico: esa es una categoría específica definida por la legislación aplicable.

## Enmascaramiento

- **Qué se ocultó:** parcialmente el `correo`, el `telefono` y el `rfc`. El correo muestra solo sus dos primeras letras y el dominio; el teléfono y el RFC muestran asteriscos y únicamente sus últimos cuatro caracteres.
- **Para quién:** para el área de soporte, representada por el rol `soporte_alanis`.
- **Por qué:** para limitar la exposición de información personal. Soporte necesita datos suficientes para atender consultas, pero no necesita ver los identificadores completos.
- **Qué mecanismo se utilizó:** enmascaramiento mediante una vista SQL, `v_clientes_soporte`, construida con las funciones `LEFT()`, `RIGHT()`, `SUBSTRING()`, `POSITION()` y `CONCAT()`. Al rol se le concedió `SELECT` sobre la vista y se le retiró todo acceso (`REVOKE ALL`) a la tabla original, de modo que al consultar `clientes` obtiene `permission denied`.

## Seudonimización

- **Cómo se generaron los tokens:** con la función `gen_random_uuid()`, disponible mediante la extensión `pgcrypto`. Se insertó un token aleatorio por cada cliente y se relacionó con su identificador original.
- **Dónde se encuentra el mapa de correspondencia:** en la tabla `pii.mapa_cliente`, dentro del esquema `pii`. Relaciona `token` con `cliente_id`, por lo que debe tratarse como información sensible. Los datos para análisis están aparte, en `analitica.clientes`, que usa el token en lugar del ID y conserva edad, ciudad, código postal y fecha de alta.
- **Quién debería poder acceder a él:** únicamente personal expresamente autorizado que necesite vincular tokens con clientes por una finalidad legítima. El analista no debe acceder al mapa ni a `public.clientes`.
- **Por qué se separaron los permisos:** para aplicar el principio de mínimo privilegio: cada usuario recibe solo los accesos necesarios para su función. El rol `analista_alanis_figueroa` puede consultar `analitica.clientes`, pero no `pii.mapa_cliente` ni `public.clientes`. Esto se comprobó con los errores `permission denied`. La seudonimización reduce la exposición de la identidad, pero no elimina por completo la posibilidad de reidentificación.

## Anonimización

- **Qué identificadores fueron eliminados:** `nombre`, `correo`, `telefono` y `rfc`, que se excluyen de los resultados analíticos.
- **Qué atributos fueron generalizados:** la `edad`, convertida en rangos (`18-30`, `31-45`, `46+`; en el reto, rangos más amplios `18-45` y `46+`), y el `codigo_postal`, reducido a sus dos primeros dígitos como región.
- **Qué grupos fueron suprimidos:** con la condición `HAVING COUNT(*) >= 5` se suprimen los grupos con menos de cinco registros. Como la tabla de práctica solo tiene cinco clientes, ninguna combinación de rango de edad y región alcanzó el umbral (los grupos tenían 1, 1 y 3 registros), por lo que la consulta no devolvió filas. Eso no significa que la consulta falle, sino que todos los grupos quedaron suprimidos.
- **Qué riesgo de reidentificación permanece:** no se puede afirmar que los datos sean 100 % anónimos. Permanecen cuasi-identificadores (edad, ubicación, fecha de alta) que pueden combinarse entre sí o con información externa para reconocer a una persona, y los grupos pequeños aumentan ese riesgo. Por ello es necesario evaluar el riesgo antes de publicar los datos.

## Retención

- **Qué criterio se utilizó:** un plazo hipotético de cinco años, aplicado con una consulta que compara `fecha_alta` con `CURRENT_DATE - INTERVAL '5 years'`. La consulta solo identifica registros, sin modificar ni eliminar nada. En los datos de prueba devolvió un resultado vacío, porque todos los clientes tienen fecha de alta 2026-10-13.
- **Qué información debería conservarse:** la necesaria para cumplir su finalidad y las obligaciones legales, fiscales u operativas aplicables, y la que esté sujeta a auditorías, investigaciones o procedimientos pendientes.
- **Qué información podría eliminarse:** los datos que ya no sean necesarios, de manera controlada y siempre que no exista una obligación que exija conservarlos. En un caso real, el plazo debe justificarse según la finalidad del tratamiento y las políticas de la organización; cinco años no es un plazo válido para toda clase de información.
- **Qué controles deberían existir antes de eliminarla:**
  - Justificación documentada.
  - Autorización formal del área responsable, y aprobación de cumplimiento, jurídica o seguridad de la información según las políticas.
  - Verificación de que no haya obligaciones de conservación.
  - Respaldo actualizado, íntegro, verificado y con acceso restringido.
  - Evidencia del proceso: consulta ejecutada, registros afectados, autorización, fecha y responsable.
  - Procedimiento de recuperación mediante respaldos verificados o recuperación a un punto en el tiempo, para restaurar información eliminada por error.

## Conclusiones

**¿Qué técnica utilizarías para un área de soporte?**
El enmascaramiento mediante una vista, porque permite consultar la información necesaria sin mostrar completamente los datos personales de los clientes.

**¿Qué técnica utilizarías para un área de analítica?**
La seudonimización, porque permite trabajar con tokens en lugar de identificadores directos y mantener separada la tabla que relaciona los tokens con los clientes originales. El acceso al mapa debe restringirse a personal autorizado.

**¿Qué técnica utilizarías para publicar estadísticas?**
Técnicas de anonimización, como la generalización de atributos, la agregación y la supresión de grupos pequeños, evaluando el riesgo de reidentificación antes de divulgar los resultados.

**¿Por qué ninguna de estas técnicas sustituye al control de acceso?**
Porque cada una protege la información de una manera diferente: el enmascaramiento reduce lo que se muestra, la seudonimización sustituye identificadores y la anonimización busca reducir la posibilidad de identificar a una persona. El control de acceso determina quién puede consultar o modificar los datos. Por eso deben utilizarse conjuntamente según las necesidades de protección.

---

# 20. Preguntas de reflexión

**1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?**
El enmascaramiento oculta una parte de los datos para que no se muestren completamente, como al ocultar caracteres de un teléfono o correo electrónico. La seudonimización sustituye un identificador por otro valor, como un token, y mantiene por separado la información que permite relacionarlo con la identidad original.

**2. ¿Por qué la seudonimización no significa anonimización?**
Porque existe un mapa de correspondencia que permite relacionar los tokens con los clientes originales. Si una persona autorizada obtiene ese mapa, o si se combina la información con otros datos, puede ser posible recuperar la identidad. Por eso, los datos seudonimizados todavía requieren protección.

**3. ¿Por qué eliminar `nombre` y `RFC` no garantiza que un conjunto de datos sea anónimo?**
Porque otros atributos, como la edad, la ciudad, el código postal y la fecha de alta, pueden combinarse y distinguir a una persona. Además, es posible comparar esos atributos con información disponible en otras fuentes.

**4. ¿Qué función tienen los cuasi-identificadores?**
Son atributos que no necesariamente identifican directamente a una persona, pero que pueden hacerlo cuando se combinan entre sí o con información externa. Algunos ejemplos son la edad, la ubicación geográfica y las fechas.

**5. ¿Por qué es importante separar el mapa de seudonimización?**
Porque el mapa permite relacionar los tokens con los identificadores originales. Mantenerlo separado y restringir su acceso disminuye la posibilidad de que una persona sin autorización pueda conocer la identidad de los clientes analizados.

**6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?**
El principio de mínimo privilegio, que consiste en otorgar a cada usuario solamente los permisos que necesita para realizar su trabajo. El analista puede consultar los datos seudonimizados, pero no necesita conocer la correspondencia con las identidades originales.

**7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?**
Porque una vista permite seleccionar qué columnas y qué valores puede consultar un usuario. De esta manera, se puede mostrar información enmascarada y evitar que el personal tenga acceso directo a todos los datos almacenados en la tabla original.

**8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?**
Proteger un dato para visualización significa ocultar o transformar lo que aparece en una consulta, por ejemplo, mediante el enmascaramiento. Protegerlo contra acceso no autorizado significa impedir que un usuario sin permisos pueda consultar la información, para lo cual se utilizan roles, privilegios y controles de acceso. Ambas medidas son necesarias porque ocultar datos en una vista no garantiza que la tabla original esté protegida.

**9. ¿Por qué la retención forma parte de la protección de datos?**
Porque conservar información durante más tiempo del necesario aumenta la exposición ante accesos indebidos, filtraciones y usos no autorizados. Definir periodos de conservación ayuda a determinar cuándo los datos deben revisarse y si corresponde eliminarlos de manera segura.

**10. ¿Qué riesgo existe si una organización conserva información indefinidamente?**
La organización puede acumular información que ya no necesita, aumentando el riesgo de filtraciones, accesos indebidos, uso inadecuado y costos de almacenamiento. También podría incumplir obligaciones legales o políticas de conservación. Por ello, debe establecer periodos justificados y procedimientos controlados para revisar y eliminar la información cuando corresponda.
