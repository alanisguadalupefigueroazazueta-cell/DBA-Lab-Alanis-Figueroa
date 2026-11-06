# LAB-01 — Bitácoras y auditoría del dato en PostgreSQL

**Estudiante:** [Tu nombre — matrícula]
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos — Unidad III
**Fecha de ejecución:** 2026-11-06 14:32 UTC

## Despliegue del servidor

| Dato | Valor |
|---|---|
| Forma de despliegue (Anexo A) | Instalación nativa en Ubuntu 24.04 con los paquetes de la distribución (postgresql-16) |
| Versión | `PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit` |
| Directorio de datos | `/var/lib/postgresql/16/main` |
| Archivo de configuración | `/etc/postgresql/16/main/postgresql.conf` |
| Reglas de autenticación | `/etc/postgresql/16/main/pg_hba.conf` |
| Zona horaria de la bitácora | `Etc/UTC` |

Ninguna regla `host` usaba `trust`; no fue necesario modificar `pg_hba.conf` (evidencia 01, sección 6.4).

## Estructura

```
LAB-01/
├── README.md
├── informe.md
├── sql/
│   ├── 01-colector-y-vista.sql
│   ├── 02-configuracion-bitacora.sql
│   ├── 03-privilegios-estructura.sql
│   ├── 04-esquema-auditoria.sql
│   ├── 05-funcion-disparador.sql
│   └── 06-campos-modificados.sql
└── evidencias/
    ├── 01-configuracion-inicial.md ... 15-cronologia.md
    ├── 16-pgaudit.md
    ├── bitacora-lab01.log
    ├── bitacora-lab01.sha256
    └── capturas/
```

## Evidencias

Cada archivo de `evidencias/` contiene el comando enviado al servidor y la salida que devolvió, sin editar, seguidos de su interpretación. Las contraseñas de práctica se sustituyeron por `<REDACTED>`. La carpeta `capturas/` contiene una imagen por cada bloque de salida.

## Integridad de la bitácora exportada

`evidencias/bitacora-lab01.log` se exportó desde el propio servidor con las contraseñas sustituidas antes de salir del motor. Contiene los 1 archivo(s) del colector en orden. Para verificarlo:

```bash
sha256sum -c evidencias/bitacora-lab01.sha256     # Linux
shasum -a 256 -c evidencias/bitacora-lab01.sha256 # macOS
```

```
5f45caa7ba7c43db0f1440ee2442af2afd272adbccaa4e2d10f12f96591d19b1  evidencias/bitacora-lab01.log
```

> El servidor se conserva para el LAB-03.
