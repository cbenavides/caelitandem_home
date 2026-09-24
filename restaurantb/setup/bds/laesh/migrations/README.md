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

_Ninguna — directorio vacío de `m*.sql`. Toda migración aplicada y validada se folda al script base correspondiente (`00–09`) y se elimina de aquí._

> Nota 2026-09-24: `m001_folio_extraido.sql` (`resultados_pdf.folio_extraido`,
> P-LAESH-FOLIO-EXTRAIDO-01) se creó, se aplicó en KVM2 vía `deploy.sh bd`
> (Paso 2b, confirmado `✓ m001_folio_extraido.sql OK`) y se foldeó de
> inmediato a `03_transactional_schema.sql` (ya vivía ahí duplicado, para
> instalaciones `--drop`) — eliminado de aquí tras validar. Fue la PRIMERA
> vez que Paso 2b se ejecutó en la práctica: se encontró y corrigió un bug
> real — el archivo no traía `USE \`laesh_db\`;` (a diferencia de TODOS los
> scripts base 00–09, que sí lo tienen) y `.mariadb-root.cnf` no fija una BD
> por defecto → `ERROR 1046: No database selected`. Toda migración futura
> en este directorio DEBE incluir `USE \`laesh_db\`;` al inicio.
>
> Efecto secundario encontrado al correr `deploy.sh bd` (no introducido por
> esta migración, es el comportamiento ya existente de `setup_hostinger.sh`
> sin `--drop`): Paso 3/3b/4 corren SIEMPRE, sin importar si hay migraciones
> — Paso 4 resembró y **reseteó las contraseñas de los 7 usuarios demo**
> (ADMIN/RECEPCIÓN/MÉDICO×5) a sus valores hardcodeados. Si alguno de esos
> usuarios ya tenía contraseña real de cliente, quedó revertida a la demo.
> Ver hallazgo completo en la sesión del 2026-09-24 — pendiente decidir si
> `deploy_bd()` debe aislar Paso 2b del resto del pipeline.

> Nota 2026-09-20: existió `m001_fase_a_h1_h8_y_limpieza_2026_09_20.sql` (cambios
> de FASE A H1-H8 + limpieza de código muerto), pero se eliminó sin aplicar —
> el siguiente setup a KVM2 será un rebuild completo (`--drop`), y se verificó
> que el 100% de su contenido ya vive en los scripts base `03/04/07/08/09`
> (comparación línea por línea). Un `--drop` no lee `migrations/`, así que el
> archivo era pura redundancia bajo ese escenario. Si en el futuro se necesita
> un deploy incremental (sin `--drop`) antes de que los cambios de esos scripts
> base lleguen a una BD viva, habrá que recrear una migración equivalente —
> el guard `_check_pending_migrations()` en `deploy.sh` sigue activo para
> avisar de esa situación.

---

## Notas

- `setup_hostinger.sh` sin `--drop` ejecuta `Paso 2b`: aplica todos los `m*.sql`
  que encuentre aquí, en orden alfabético, e informa si no hay ninguno.
- Con `--drop` el Paso 2b es no-op (la BD se recrea limpia desde 00-09).
- Una vez aplicada y validada una migración: fold al script base + borrar el archivo.
  El directorio siempre debe tender a estar vacío de `m*.sql`.
