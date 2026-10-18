# LAB-01 — Protección de datos en PostgreSQL

**Estudiante:** Alanis Guadalupe Figueroa Zazueta
**Institución:** Universidad Autónoma de Sinaloa (UAS)
**Entorno:** PostgreSQL / pgAdmin 4 — base de datos `db_19409168_alanis_figueroa`, tabla `public.clientes`

## Estructura del repositorio

```
LAB-01/
├── README.md
├── informe.md
├── sql/
│   ├── 01-clasificacion.sql
│   ├── 02-enmascaramiento.sql
│   ├── 03-seudonimizacion.sql
│   ├── 04-anonimizacion.sql
│   └── 05-retencion.sql
└── evidencias/
    ├── 01-clasificacion.pdf
    ├── 02-enmascaramiento.pdf
    ├── 03-seudonimizacion.pdf
    ├── 04-anonimizacion.pdf
    └── 05-retencion.pdf
```

## Cómo reproducir

1. Conectarse a pgAdmin 4 con el usuario propietario de la base de datos.
2. Ejecutar los scripts de `sql/` en orden numérico (el 02 crea el rol `soporte_alanis` y la vista `v_clientes_soporte`).
3. Las pruebas con el rol de soporte se hacen con `SET ROLE soporte_alanis;` y se regresa con `RESET ROLE;`.

## Evidencia mínima

Cada PDF de `evidencias/` identifica: estudiante, actividad, consulta o comando ejecutado, resultado obtenido y fecha o contexto de ejecución. Las capturas acompañan a los scripts SQL y a la explicación técnica; no los sustituyen. El rechazo de acceso directo a `clientes` se muestra con el intento y el mensaje `ERROR: permission denied for table clientes (SQLSTATE 42501)`.

## Informe

Ver [`informe.md`](informe.md).
