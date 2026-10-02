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

> `m010_optimizacion_indices_modelo.sql` (2026-10-02, **aplicada y foldeada**):
> - `rel_igabinete_vinculos`: PK autoincremental física `id` + unicidad virtual `uq_vinculo_unico` sobre `(igabinete_id, gabinete_id, IFNULL(subgabinete_id, 0))`.
> - Depuración de 6 índices secundarios redundantes (`idx_cms_sec_sub_clave`, `idx_seccion` en `web_contenidos`; `idx_medico`, `idx_estado` en `ordenes`; `idx_user` en `notificaciones`; `idx_orden` en `historial_estados_orden`).
> - `jwt_jti_registry`: índice compuesto `idx_user_revoked (user_id, is_revoked)` y retiro de `idx_is_revoked` e `idx_user_id`.
> - `catalogo_promociones`: tipo `dia_semana` optimizado a `VARCHAR(255)` (almacenamiento in-row sin off-page storage, preservando HTML de CKEditor).
> - `vw_estudios_catalogo` y `UpsertEstudioCatalogo`: retiro de `descripcion_breve` y `fecha_modificacion`.
> - `cat_estudios`: retiro de `categoria_id`, `descripcion_breve`, `detalle`, `fecha_creacion`, `fecha_modificacion` y estandarización a `created_at`/`updated_at`.
> - `cat_categorias`: retiro de tabla obsoleta y FK `fk_estudio_categoria`.
> Foldeada a `02_core_schema.sql`, `03_transactional_schema.sql`, `04_auth_extensions.sql`, `06_indexes.sql`, `08_stored_procedures.sql` y `09_views.sql`.

> **Números reutilizados (m006–m009), 2026-10-01 tarde/noche** — no confundir con las entradas de
> `m006`–`m009` de más abajo (mismo día, más temprano): esos ya se foldearon y se borraron, liberando
> los números, que una sesión paralela de Claude Code volvió a usar para 4 migraciones nuevas y
> distintas (autodiagnóstico post-PEN-LAESH-01/02/03/04):
> - `m006_add_notificaciones_subtipo.sql`: columna `notificaciones.subtipo` + backfill por `tipo`/`titulo`/`mensaje`
>   (P-LAESH-NOTIF-SUBTIPO-01). Ya vivía en `03_transactional_schema.sql` desde su creación — solo se
>   confirmó la paridad y se borró el archivo de aquí.
> - `m007_session_lifetime_roles.sql`: `session_expiration_time` + `session_lifetime_{medico,recepcion,admin}_dias`.
>   Ya vivía en `07_seed_catalogs.sql`, pero con las descripciones de Recepción/Admin **desactualizadas**
>   ("1 a 3 días" / "1 a 7 días" — rango viejo, antes de ampliarse a 1-90 en `admrc/views/sistema.php`).
>   Corregido el texto para que coincida con el rango real validado por el código.
> - `m008_parametrizaciones_admin.sql` (PEN-LAESH-01/02/03/04): `notif_polling_http_interval_sec`,
>   `auto_cierre_resultados_dias`, `draft_order_ttl_horas`, `notif_retencion_dias`. No existía en
>   `07_seed_catalogs.sql` — agregado.
> - `m009_notif_panel_y_ws_reconnect.sql` (autodiagnóstico post-PEN-LAESH): `notif_panel_ventana_dias`,
>   `notif_panel_limit_anteriores`, `ws_reconnect_interval_sec`. Tampoco existía — agregado.
>
> Las 4 ya estaban aplicadas e idénticas en Docker local y KVM2 antes del fold (verificado por conteo
> de filas/columnas en ambas BDs). Fold validado corriendo `07_seed_catalogs.sql` completo contra
> Docker local (`mysql` exit 0, sin errores) antes de borrar los 4 archivos. No se tocó producción en
> este fold — `07_seed_catalogs.sql` solo corre bajo `--drop`, nunca en el camino incremental normal
> (`deploy.sh bd`), así que ningún valor personalizado por el admin en KVM2 (ej. los días de sesión
> que el cliente ya ajustó manualmente) corre riesgo de revertirse a estos defaults de seed.

> `m009_ws_fallback_stats_sin_sesion.sql` (2026-10-01, **aplicada**): `vw_ws_fallback_stats` deja de contar
> `no_recipients_connected` como fallback (nueva columna `sin_sesion`; % sobre destinatarios conectados).
> Aplicada en local y KVM2; ya en `09_views.sql`. Archivo eliminado.
> Mismo día, Gemini aplicó en KVM2 un `m009_view_ordenes_folio_extraido.sql` (agrega `folio_extraido` a
> `vw_ordenes_completas`), que solo existió en el staging; su DDL **sí** está en `09_views.sql` (commit `372d78d`).
> Faltaba aplicarlo en Docker local y OCI — aplicado el 2026-10-01 (PEN-LAESH-16).

> `m008_drop_vistas_retiradas.sql` (2026-10-01, **aplicada**, PEN-LAESH-08): `DROP VIEW IF EXISTS`
> `vw_notificaciones_pendientes` y `vw_ordenes_estadisticas`. `09_views.sql` ya las retiraba, pero
> sin migración seguían en KVM2 y local. Sin dependencias (código, vistas, SPs). Verificado: KVM2,
> Docker local y OCI con las mismas 8 vistas; portales sin errores. Archivo eliminado.

> `m007_depuracion_auditoria_20261001.sql` (2026-10-01, **aplicada y foldeada**): DROP `sys_catalog_version`
> (tabla siempre vacía), DROP `folios_control.prefijo/longitud` y DELETE `configuraciones.anios_experiencia`.
> Orden usado: primero el PHP sin `CatalogBuilder::updateVersion()` (`deploy.sh webapp`), luego `deploy.sh bd`.
> Verificado en KVM2: tabla inexistente, columnas retiradas, contador de folios 34/34, perfiles intactos.
> Validada también con instalación limpia 00–09 en contenedor desechable (folios 1, 2 consecutivos).

> `m006_rol_sitioweb.sql`: aplicada en KVM2 el 2026-09-30 (`deploy.sh bd`) y ya incluida en `04_auth_extensions.sql`; archivo eliminado.

> PEN-LAESH-06 (corregido 2026-09-30): `deploy.sh bd` ya no modifica usuarios existentes — su Paso 4
> (`seed_first_users.php`) solo crea los que falten. Vuelve a ser el camino normal para aplicar migraciones.

> Nota 2026-09-30 (m006 — `m006_notificaciones_titulo_semantica.sql`, **aplicada y foldeada**): agregó columna
> `titulo VARCHAR(100)` a la tabla `notificaciones` y saneó el histórico existente para desacoplar el encabezado
> del cuerpo del mensaje, eliminando repeticiones redundantes de folios y frases vacías. Aplicada en KVM2 vía
> `deploy.sh bd` / MariaDB y foldeada a `03_transactional_schema.sql`; archivo eliminado de aquí tras verificación.

> Nota 2026-09-30 (m005 — `m005_drop_detalle_ordenes.sql`, **aplicada y foldeada**): retiró `detalle_ordenes`,
> tabla de solo escritura que nunca tuvo filas en KVM2 (los estudios viven en `ordenes.estudios`). Aplicada en
> Docker local y en KVM2 el 2026-09-30 — en KVM2 directamente como root (sin `deploy.sh bd`, por PEN-LAESH-06).
> Verificado: tabla inexistente, sin procedimiento auxiliar residual, 29 órdenes intactas, suite de búsqueda 161/161.
> El DDL ya había salido de `03_transactional_schema.sql`; archivo eliminado de aquí.
> En Docker local la tabla tenía 3 765 filas la tabla tenía 3 765 filas, **todas** de órdenes simuladas `[SIM2Y]` (las insertaba `www/tests/seed_dataset_2years.php`, que ya no lo hace). Se respaldaron y borraron antes de aplicar m005. `cat_categorias` se evaluó y **se conserva**: los 1 055 estudios tienen `categoria_id` asignado (R14.2), aunque ninguna pantalla la lea desde m002.

> Nota 2026-09-28: `m004_notif_actualizado_en.sql` (columna `notificaciones.actualizado_en`,
> `TIMESTAMP ... ON UPDATE CURRENT_TIMESTAMP`, BUG-NOTIF-LEIDO-SYNC-01 — permite
> que el poll incremental de `GET /api/notificaciones` detecte una transición
> no-leído→leído hecha desde otra pestaña/dispositivo y reenvíe la fila una vez
> más) se creó, se aplicó en KVM2 vía `deploy.sh bd` (confirmado `✓ ... OK`) y
> se foldeó de inmediato a `03_transactional_schema.sql` — eliminado de aquí
> tras validar con una prueba end-to-end real (130s, marcado desde "otro
> dispositivo" vía API, confirmado visualmente en el cliente).
>
> Hallazgo durante esta migración (no del schema, del código que la consume):
> `rc/index.php`/`md/index.php` reutilizaban el mismo placeholder con nombre
> `:since` dos veces en la misma consulta — con prepared statements nativos
> (sin emulación) esto revienta con `SQLSTATE[HY093]: Invalid parameter
> number`, y como el fetch del cliente traga el error en `.catch()`, el
> endpoint devolvía 500 en silencio sin ningún síntoma visible en consola.
> Se corrigió usando placeholders con nombre distinto (`:since_creado`,
> `:since_upd`) para el mismo valor. Relevante para cualquier query futura
> que necesite repetir un mismo valor en más de una condición del WHERE.
>
> Nota 2026-09-27/28 (previa): `m002_fix_rel_estudio_gabinete_pk.sql` (PRIMARY KEY en
> `rel_estudio_gabinete`, reescritura de `UpsertEstudioCatalogo` /
> `SyncJerarquiaGabinete` / `vw_estudios_catalogo` para usar Gabinete/Subgabinete
> en vez de `cat_categorias`) y `m003_website_igabinetes_curacion.sql`
> (renombrado de `cat_igabinetes`, rebalanceo de `rel_igabinete_vinculos`,
> curaduría fina de `rel_estudio_gabinete` por ficha + 5ª pestaña "Salud
> Biologia Molecular") se crearon, se aplicaron en KVM2 vía `deploy.sh bd`
> (confirmado `✓ ... OK` en ambos) y se foldearon de inmediato — m002 ya vivía
> en `02_core_schema.sql`/`08_stored_procedures.sql`/`09_views.sql` (fuente
> de la migración), m003 en `07_seed_catalogs.sql` — eliminados de aquí tras
> validar.
>
> Hallazgo durante m003: `cat_subgabinetes` en KVM2 tenía una fila huérfana
> `id=9 'subg'` (datos de prueba sin ninguna referencia real) que no existía
> ni en git ni en el Docker local — se eliminó como parte de m003. También se
> encontró la 5ª pestaña ("Salud Biologia Molecular" / Gabinete 13 / Subgabinete
> 10 "BM1") solo en el Docker local, nunca capturada en `07_seed_catalogs.sql`
> — se foldeó al script base en esta misma sesión. Ver [[project_laesh_ssot_drift]]
> para el patrón general: cambios hechos directo en una BD (local o KVM2) sin
> pasar por el script de seed correspondiente divergen silenciosamente hasta
> que alguien los audita a mano.
>
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
