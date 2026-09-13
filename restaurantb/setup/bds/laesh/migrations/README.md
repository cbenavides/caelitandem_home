# Migraciones — LAESH Bloc Digital

## Estado actual (2026-09-13)

**No hay migraciones activas.**

Todas las migraciones (m001–m005) fueron archivadas en `archived/` porque
sus cambios quedaron consolidados en los scripts base (00–09).

Desde `setup_hostinger.sh --drop` la BD nace estructuralmente pura con todos
los datos semilla incluidos — no se requiere ejecutar ninguna migración.

Ver: [archived/README.md](archived/README.md) para el detalle de cada una.

---

## Cómo agregar una nueva migración (si fuera necesario)

1. Crear `mNNN_descripcion_breve.sql` en este directorio
2. Marcarla como idempotente (IF NOT EXISTS, INSERT IGNORE, ON DUPLICATE KEY, etc.)
3. Agregar entrada a este README
4. Ejecutar en KVM2:
   ```bash
   mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db \
       < ~/staging/setup/bds/laesh/migrations/mNNN_descripcion_breve.sql
   ```
5. Una vez validada, fold el DDL/datos en el script base correspondiente
   y mover el archivo a `archived/`
