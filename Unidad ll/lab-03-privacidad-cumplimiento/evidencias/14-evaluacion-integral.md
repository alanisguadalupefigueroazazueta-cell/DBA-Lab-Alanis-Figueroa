# Actividad 14 — Escenario integral

## Objetivo

Evaluar los riesgos de privacidad, seguridad y gobierno de datos de una empresa que almacena información personal de 50,000 clientes, identificando los problemas existentes y proponiendo controles para reducirlos.

## Procedimiento

Se analizó el escenario de Comercializadora Norte S.A. de C.V., considerando los permisos de acceso, las finalidades del tratamiento, la conservación de los datos, el uso de copias en desarrollo y las actividades de marketing.

## Matriz de problemas, riesgos y controles

| Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|
| 1. Todo el personal de analítica puede consultar directamente la tabla `clientes`. | Mínimo privilegio y confidencialidad. | Exposición de información personal que no se necesita para elaborar estadísticas. | Crear una vista de analítica con los campos necesarios y otorgar permisos únicamente sobre ella. |
| 2. Analítica tiene acceso a nombres y correos electrónicos, aunque solo genera estadísticas mensuales. | Minimización de datos. | Identificación de clientes y uso innecesario de sus datos personales. | Utilizar datos agregados por ciudad, rangos de edad u otras categorías pertinentes. |
| 3. El área de analítica puede consultar teléfonos y RFC. | Limitación de la finalidad y mínimo privilegio. | Exposición de datos de contacto y fiscales sin una necesidad funcional. | Restringir el acceso a esos campos y reservarlos para áreas autorizadas que los necesiten. |
| 4. Los datos se conservan desde hace 12 años sin una justificación documentada. | Limitación del plazo de conservación. | Acumulación de información que podría haber dejado de ser necesaria. | Revisar las finalidades y obligaciones aplicables, definir periodos justificados y establecer revisiones periódicas. |
| 5. No existe una política documentada de retención. | Responsabilidad y rendición de cuentas. | No hay criterios claros para determinar cuándo revisar, bloquear o eliminar datos. | Aprobar una política de retención con plazos, responsables, excepciones y procedimientos de disposición final. |
| 6. Los desarrolladores reciben copias completas de la base de datos. | Minimización y confidencialidad. | Mayor número de copias y más oportunidades de acceso no autorizado o filtraciones. | Entregar únicamente conjuntos de datos necesarios para cada prueba y restringir su acceso. |
| 7. Las copias de desarrollo contienen datos personales reales. | Privacidad por diseño y seguridad. | La información puede exponerse en entornos con controles distintos a los de producción. | Utilizar datos sintéticos o anonimizados de forma efectiva y evitar información real cuando no sea necesaria. |
| 8. No se especifica quién puede acceder a las copias de desarrollo. | Control de acceso y mínimo privilegio. | Personas no autorizadas podrían consultar, copiar o compartir información personal. | Aplicar permisos por rol, autenticación adecuada, almacenamiento protegido y registros de acceso. |
| 9. Marketing utiliza los correos para campañas promocionales sin que estén claras las finalidades. | Limitación de la finalidad y transparencia. | Uso incompatible con lo informado al cliente o incumplimiento de los requisitos aplicables. | Revisar el aviso de privacidad, la finalidad original y la base legal correspondiente antes de realizar las campañas. |
| 10. No existe documentación clara que relacione cada dato con su finalidad. | Limitación de la finalidad y responsabilidad. | Los datos pueden utilizarse para objetivos no justificados y resulta difícil demostrar el cumplimiento. | Crear un inventario y una matriz de gobierno que indiquen finalidad, responsable, acceso, protección y retención de cada dato. |
| 11. No se menciona una revisión periódica de permisos. | Seguridad y mínimo privilegio. | Los permisos pueden mantenerse aunque una persona cambie de puesto o deje de necesitar el acceso. | Revisar periódicamente los roles y retirar los permisos que ya no sean necesarios. |
| 12. No se describen controles para revisar y proteger las copias de respaldo, exportaciones y otros destinos de los datos. | Integridad, confidencialidad y ciclo de vida de los datos. | La información podría permanecer en copias o archivos después de que se haya eliminado o dejado de utilizar en el sistema principal. | Inventariar las copias, restringir su acceso, establecer periodos de conservación y documentar su tratamiento al finalizar el periodo correspondiente. |

## Resultado

Se identificaron doce problemas relacionados con el acceso excesivo, la recopilación y conservación de información personal, el uso de datos en desarrollo, las campañas de marketing y la falta de documentación. Para cada problema se propuso un control técnico o administrativo orientado a reducir los riesgos.

## Análisis

El escenario muestra que la empresa no tiene suficiente separación entre las finalidades y los permisos de acceso. El área de analítica necesita estadísticas, pero puede consultar información identificable que no requiere. Además, las copias de desarrollo y la conservación prolongada aumentan la exposición de los datos.

La ausencia de una política de retención y de documentación sobre las finalidades dificulta demostrar que la información se utiliza de manera justificada. Los controles deben combinar medidas técnicas, como vistas, roles y protección de copias, con medidas administrativas, como políticas, responsabilidades y revisiones periódicas.

## Conclusión

La empresa debe adoptar un enfoque de privacidad y seguridad desde el diseño. Las acciones prioritarias son limitar el acceso de analítica, evitar el uso de datos reales en desarrollo cuando no sean necesarios, revisar la finalidad de las campañas promocionales y establecer una política de retención documentada. También debe identificar las copias de información existentes y asignar responsables para verificar el cumplimiento de las medidas implementadas.
