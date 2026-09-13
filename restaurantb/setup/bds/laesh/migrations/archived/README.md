# Migraciones Archivadas — LAESH Bloc Digital

**Fecha de archivo:** 2026-09-13  
**Motivo:** Consolidación completa del esquema. Desde esta fecha, `setup_hostinger.sh --drop`
produce una BD estructuralmente pura y con todos los datos semilla sin necesidad
de ejecutar migraciones.

---

## Estado de cada migración (todas son no-op en BDs nuevas desde --drop)

| Archivo | Descripción original | Estado tras consolidación |
|---|---|---|
| `m001_sys_logs_traceability.sql` | Columnas trazabilidad en `sys_logs` | **NO-OP** — columnas ya en `05_system_tables.sql` |
| `m002_ssot_content_population.sql` | `descripcion_breve` DDL + datos 144 estudios + fixes CMS | **FOLDED** — DDL en `02_core_schema.sql`; datos en `07_seed_catalogs.sql` |
| `m003_cms_url_and_diasemana_fix.sql` | Fix URLs RBAC + limpieza dia_semana | **NO-OP** en BD limpia — estructura ya corregida |
| `m004_promociones_schema_cleanup.sql` | DROP columnas obsoletas `catalogo_promociones` | **NO-OP** — `02_core_schema.sql` ya tiene esquema limpio |
| `m005_jwt_jti_registry_schema.sql` | `CREATE TABLE jwt_jti_registry` | **NO-OP** — tabla ya en `04_auth_extensions.sql` |

---

## ¿Cuándo ejecutar estas migraciones?

**Nunca en BDs creadas con `--drop` tras 2026-09-13.**

Solo tienen sentido como referencia histórica o si se actualiza una BD de producción
que fue instalada antes de 2026-09-13 y que NO se puede re-crear desde cero.

---

## Datos SSOT de m002 foldeados en 07_seed_catalogs.sql

Los bloques UPDATE de `m002` (descripcion_breve, detalle, tiempo_procesamiento,
muestra_requerida, preparacion para los 144 estudios + fix clave_interna LIQ-07)
fueron integrados directamente en `07_seed_catalogs.sql` como parte del seed
de datos del setup limpio.
