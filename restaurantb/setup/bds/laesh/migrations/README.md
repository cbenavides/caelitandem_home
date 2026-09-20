# migrations/ — Deltas Incrementales de BD · LAESH

## Propósito

Este directorio contiene cambios de BD (**schema y/o datos**) que se aplican
sobre una BD de producción existente **sin necesidad de `--drop`**.

No confundir con los scripts base `00–09`: esos son el setup desde cero.
Este directorio es solo para deltas incrementales a una BD viva.

---

## Cuándo usar cada flujo

| Necesidad | Comando |
|---|---|
| Setup desde cero (servidor nuevo, `--nuke`) | `setup_hostinger.sh --drop` |
| Cambio de schema o datos en BD viva | Crear `mNNN_*.sql` aquí → `deploy.sh bd` |
| Solo PHP / Assets | `deploy.sh webapp` / `deploy.sh assets + assets-publish` |

---

## Cómo agregar una migración

1. Crear `mNNN_descripcion_breve.sql` en este directorio (N = siguiente número)
2. **Debe ser idempotente**: `IF NOT EXISTS`, `INSERT IGNORE`, `ON DUPLICATE KEY UPDATE`,
   `ALTER TABLE ... MODIFY IF EXISTS`, etc.
3. Registrar en este README (tabla de estado abajo)
4. Hacer deploy y aplicar:
   ```bash
   # Desde local — envía scripts + aplica migraciones en KVM2:
   bash setup/deploy/laesh-kvm2-prod/deploy.sh bd
   ```
5. Verificar en KVM2 que el cambio quedó correcto
6. **Fold**: integrar el DDL/datos en el script base correspondiente (`00–09`)
   y eliminar el `mNNN_*.sql` de este directorio

---

## Estado de migraciones activas

| Archivo | Descripción | Estado |
|---|---|---|
| `m001_perfiles_medicos_cedula_especialidad.sql` | Agrega `perfiles_medicos.cedula_especialidad` — feature "Mi Perfil" Portal Médico | 🔲 Pendiente de aplicar en KVM2 |

---

## Notas

- `setup_hostinger.sh` sin `--drop` ejecuta `Paso 2b`: aplica todos los `m*.sql`
  que encuentre aquí, en orden alfabético, e informa si no hay ninguno.
- Con `--drop` el Paso 2b es no-op (la BD se recrea limpia desde 00-09).
- Una vez aplicada y validada una migración: fold al script base + borrar el archivo.
  El directorio siempre debe tender a estar vacío de `m*.sql`.
