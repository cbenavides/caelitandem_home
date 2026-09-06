# bash/ — Scripts de Setup y Operación LAESH

Scripts de infraestructura para los tres entornos: **Local Docker** · **OCI VM** · **Hostinger KVM 2**.
La referencia completa (runbooks, credenciales, idempotencia) está en
`portafolio-dev-2026/blocklabgd/v1.2/et/Tecnica_Infraestructura_Despliegue.html §19`.

---

## Inventario de Scripts

| Script | Qué hace | Entorno |
|--------|----------|---------|
| `01_install_auth.sh` | DDL Delight-Auth via `docker exec restaurantb_db`. Idempotente (`CREATE TABLE IF NOT EXISTS`). | **Solo local** — incompatible OCI/Hostinger |
| `02_seed_users.sh` | Seed 3 usuarios demo via `docker exec restaurantb_phpfpm`. Idempotente. | **Solo local** — incompatible OCI/Hostinger |
| `03_test_deploy.sh` | Suite 27 checks post-deploy (HTTP, assets, CSP, seguridad, PHP). `BASE=url` configurable. | **Universal** — Local + OCI + Hostinger |
| `04_export_cms_seed_local_oci.sh` | Exporta `web_contenidos` de BD local → regenera `07_seed_catalogs.sql` (REPLACE INTO). Flujo: **Local Docker → OCI**. Para KVM2, usar junto a `05_import_cms_seed_kvm2.sh`. | **Solo local** (fuente de verdad) |
| `05_import_cms_seed_kvm2.sh` | Extrae el bloque `web_contenidos` de `07_seed_catalogs.sql` y lo aplica en KVM2 via SSH sin DROP. Conserva órdenes, pacientes e histórico. | **Local → KVM2** (SSH) |
| `06_verify_traceability.sh` | Smoke-test E2E de Gaps G2–G5: verifica columnas sys_logs, event_scheduler, evt_purga_sys_logs, registros recientes con request_id/url/session_id, RBAC events. Invocado al final de `setup_hostinger.sh`. | **KVM2** (requiere `H_ROOT_PASS`) |

---

## Cuándo Usar Cada Script

### `01_install_auth.sh` — solo debugging local

**Usar cuando:** hay problema con las tablas Delight-Auth en local y se quiere recrearlas sin tocar el resto del schema.

**No usar:** en OCI ni Hostinger. Tampoco como parte del flujo normal de deploy — `setup.sh` ya lo llama.

```bash
# Aislado (solo si necesitas depurar Auth local):
bash setup/bds/laesh/bash/01_install_auth.sh
```

### `02_seed_users.sh` — solo debugging local

**Usar cuando:** se eliminaron los usuarios demo de la BD local y se quieren restaurar sin recrear toda la BD.

**No usar:** en OCI ni Hostinger. El equivalente productivo es `commons/seed_first_users.php`, llamado por `setup_oci.sh` y `setup_hostinger.sh`.

```bash
# Aislado (solo si necesitas re-sembrar usuarios en local):
bash setup/bds/laesh/bash/02_seed_users.sh
```

---

### `seed_first_users.php` — seed/reset de usuarios en OCI y KVM2

Ubicado en `www/laesh-swbldi/commons/seed_first_users.php`. Lo invoca `setup_hostinger.sh` en el paso 4 y `setup_oci.sh` en el equivalente. También se puede ejecutar directamente para **resetear contraseñas** sin destruir la BD.

**Credenciales de demo** (secuencia `04041980+n`):

| Rol | Teléfono | Contraseña | Redirect |
|-----|----------|------------|---------|
| ADMIN | `9990000001` | `04041980` | `/laesh/rc/` |
| RECEPCION | `9990000002` | `04041981` | `/laesh/rc/` |
| MÉDICO 1 | `9990000003` | `04041982` | `/laesh/md/` |
| MÉDICO 2 | `9990000004` | `04041983` | `/laesh/md/` |
| MÉDICO 3 | `9990000005` | `04041984` | `/laesh/md/` |
| MÉDICO 4 | `9990000006` | `04041985` | `/laesh/md/` |
| MÉDICO 5 | `9990000007` | `04041986` | `/laesh/md/` |

> ⚠ **Cambiar antes de entregar al cliente.** Estas son credenciales de demo, no de producción.

**Comportamiento idempotente:**
- Si el usuario **no existe** → lo crea con Delight-Auth y asigna rol/permisos RBAC.
- Si el usuario **ya existe** → resetea su contraseña al valor del seed y actualiza empleados/permisos (no lo recrea).

**Reset completo de usuarios** (cuando se necesita empezar desde cero):

```sql
-- Ejecutar en la BD antes de volver a correr seed_first_users.php:
DELETE FROM rbac_permisos_usuarios;
DELETE FROM empleados;
DELETE FROM users WHERE email LIKE '%@laesh.local';
```

Luego re-ejecutar el seed:

```bash
# KVM2 (como www-data para acceder al webroot):
sudo -u www-data env \
  LAESH_DB_HOST=127.0.0.1 LAESH_DB_PORT=3306 \
  LAESH_DB_USER=laesh_app LAESH_DB_PASS=laesh_2026_dev \
  LAESH_DB_NAME=laesh_db APP_ENV=production \
  php8.3 /opt/laesh/www/laesh-swbldi/commons/seed_first_users.php
```

```bash
# OCI (ajustar php bin y web dir según entorno):
sudo -u www-data env \
  LAESH_DB_HOST=127.0.0.1 LAESH_DB_PORT=3306 \
  LAESH_DB_USER=laesh_app LAESH_DB_PASS=laesh_oci_app_2026 \
  LAESH_DB_NAME=laesh_db APP_ENV=production \
  php8.1 /home/ubuntu/laesh-stack/www/laesh-swbldi/commons/seed_first_users.php
```

### `03_test_deploy.sh` — siempre tras cualquier deploy ✅

**Usar cuando:** después de **cualquier deploy** en cualquier entorno. También como health check manual.

**No usar:** antes de que el servidor esté respondiendo (curl fallará y generará falsos negativos).

```bash
# Local:
BASE=https://192.168.1.71:8443 bash setup/bds/laesh/bash/03_test_deploy.sh

# OCI:
BASE=https://caelitandem.lat bash setup/bds/laesh/bash/03_test_deploy.sh

# Hostinger:
BASE=https://laesh.mx bash setup/bds/laesh/bash/03_test_deploy.sh
```

### `04_export_cms_seed_local_oci.sh` — antes de rsync a OCI

**Usar cuando:** hay ediciones en el CMS local (`/laesh/adrc/` → Gestión Web) que deben propagarse a OCI. Ejecutar **antes** del rsync para generar el diff revisable en `07_seed_catalogs.sql`.

**Flujo objetivo:** Local Docker → OCI (`setup_oci.sh --drop`).
**Para KVM2:** el script exporta igualmente el seed, pero el paso de deploy final es distinto — usar `sync_to_hkvm2.sh` y luego `06_deploy_app.sh` **sin** `--drop` para no perder datos operativos.

**No usar:** directamente en OCI o Hostinger (requiere contenedor Docker local `restaurantb_db`). No sustituye a un backup de la BD de producción.

```bash
# Desde local:
bash setup/bds/laesh/bash/04_export_cms_seed_local_oci.sh

# Revisar qué cambió antes de comprometer:
git diff setup/bds/laesh/07_seed_catalogs.sql
```

---

## Flujo Operativo Típico

### Actualización de contenido CMS → OCI (reset completo)

```bash
# 1. Editar en CMS local → exportar:
bash setup/bds/laesh/bash/04_export_cms_seed_local_oci.sh
git diff setup/bds/laesh/07_seed_catalogs.sql   # revisar cambios

# 2. Rsync setup/ y código al servidor OCI
# 3. En OCI:
bash ~/laesh-stack/setup/bds/laesh/setup_oci.sh --drop

# 4. Verificar:
BASE=https://caelitandem.lat bash setup/bds/laesh/bash/03_test_deploy.sh
```

### Actualización de contenido CMS → KVM2 (sin DROP, datos vivos)

```bash
# 1. Editar en CMS local → exportar:
bash setup/bds/laesh/bash/04_export_cms_seed_local_oci.sh
git diff setup/bds/laesh/07_seed_catalogs.sql   # revisar cambios

# 2. Importar solo web_contenidos a KVM2 (SSH — no toca órdenes ni histórico):
bash setup/bds/laesh/bash/05_import_cms_seed_kvm2.sh

# 3. Verificar:
BASE=https://laesh.mx bash setup/bds/laesh/bash/03_test_deploy.sh
```

### ⚠️ Re-deploy con CMS vivo en KVM2 — elegir variante correcta

`06_deploy_app.sh` invoca `setup_hostinger.sh`, que siempre ejecuta `07_seed_catalogs.sql`
con **`REPLACE INTO web_contenidos`**. Esto **sobreescribe** todo lo editado en el CMS del servidor.
Elegir la variante según qué cambió:

| Situación | Variante | Acción |
|-----------|----------|--------|
| Solo código PHP / JS / CSS (sin cambios BD) | **C1** | `sync` + rsync manual en servidor + `reload php-fpm`. No correr `06_deploy_app.sh`. |
| Código + migraciones SQL o seed nuevos | **C2** | `sync` → backup `web_contenidos` en servidor → `06_deploy_app.sh` → restore. |

**Variante C1 — Solo código, BD y CMS intactos:**
```bash
# En el servidor, tras sync_to_hkvm2.sh desde local:
sudo rsync -a --checksum ~/laesh-src/laesh-swbldi/            /opt/laesh/www/laesh-swbldi/
sudo rsync -a --checksum ~/laesh-src/laesh-web-assets-uipv1a/ /opt/laesh/assets/laesh-web-assets-uipv1a/
sudo systemctl reload php8.3-fpm
```

**Variante C2 — Código + BD, preservando CMS:**
```bash
# En el servidor — ANTES del deploy:
sudo mysqldump -u root -p'comite_2026' laesh_db web_contenidos \
  > /tmp/wc_backup_$(date +%Y%m%d_%H%M).sql

# Deploy completo:
cd ~/laesh-kvm2-prod
LAESH_ROOT_PASS='comite_2026' LAESH_APP_PASS='laesh_2026_dev' sudo -E bash 06_deploy_app.sh

# Restaurar contenido editorial:
sudo mariadb -u root -p'comite_2026' laesh_db < /tmp/wc_backup_$(date +%Y%m%d)*.sql
```

> Referencia completa: `setup/deploy/laesh-kvm2-prod/README.md § Opción C1 / C2`.

---

## Idempotencia

### Scripts SQL individuales

| Script | Mecanismo | ¿Idempotente? |
|--------|-----------|--------------|
| `00_database.sql` | `DROP DATABASE` + `CREATE DATABASE` | ❌ El DROP destruye. Solo seguro via orquestador con `--drop` explícito. |
| `01_auth_schema.sql` | `CREATE TABLE IF NOT EXISTS` | ✅ Siempre |
| `02_core_schema.sql` | `CREATE TABLE IF NOT EXISTS` | ✅ Siempre |
| `03_transactional_schema.sql` | `CREATE TABLE IF NOT EXISTS` | ✅ Siempre |
| `04_auth_extensions.sql` | `CREATE TABLE IF NOT EXISTS` | ✅ Siempre |
| `05_system_tables.sql` | `CREATE TABLE IF NOT EXISTS` | ✅ Siempre |
| `06_indexes.sql` | `DROP INDEX IF EXISTS` + `CREATE INDEX` | ✅ Recrea índices (ms). Sin pérdida de datos. |
| `07_seed_catalogs.sql` | Mixto — ver detalle abajo | ⚠️ Parcial |
| `08_stored_procedures.sql` | `DROP PROCEDURE IF EXISTS` + `CREATE PROCEDURE` | ✅ Recrea SPs. Sin pérdida de datos. |
| `09_views.sql` | `CREATE OR REPLACE VIEW` | ✅ Siempre |

### Detalle `07_seed_catalogs.sql`

| Tabla | Mecanismo | Re-ejecución |
|-------|-----------|--------------|
| Catálogos, estudios, RBAC, UI | `INSERT IGNORE` | ✅ Sin efecto — no modifica filas existentes. |
| `configuraciones` | `ON DUPLICATE KEY UPDATE` | ✅ Sobreescribe valores con el seed — revierte ediciones CMS en esas claves. Comportamiento esperado. |
| `web_contenidos` | `REPLACE INTO` | ⚠️ Sobreescribe todo el contenido editorial. Las ediciones CMS locales no exportadas via `04_export_cms_seed.sh` se pierden. **Siempre exportar antes de re-ejecutar.** |

### Orquestadores

| Orquestador | Sin `--drop` | Con `--drop` |
|-------------|-------------|-------------|
| `setup.sh` | ❌ No seguro — ejecuta `00_database.sql` directo (incluye DROP sin flag). | N/A |
| `setup_oci.sh` | ✅ Idempotente — verifica BD existente, SQL 01–09, ALTER USER, seed. | ❌ Destructivo — DROP explícito. Solo para reset completo. |
| `setup_hostinger.sh` | ✅ Idempotente — misma lógica. | ❌ Destructivo — DROP explícito. |

**Regla práctica:** Para actualizar schema/seed sin perder datos operativos (órdenes, pacientes, histórico) → **sin `--drop`**. Solo `--drop` para primer deploy o reset completo intencionado.

---

## Variables Sobreescribibles

### Local (`01_install_auth.sh`, `02_seed_users.sh`)

```bash
DB_CONTAINER   (default: restaurantb_db)
DB_NAME        (default: laesh_db)
DB_USER        (default: root)
DB_PASS        (default: comite_2026)
WEB_CONTAINER  (default: restaurantb_phpfpm)   # 02_seed_users.sh
```

### OCI (`setup_oci.sh`)

```bash
OCI_DB_CONTAINER   (default: laesh_db)
OCI_ROOT_PASS      (default: laesh_oci_root_2026)
OCI_APP_PASS       (default: laesh_oci_app_2026)
OCI_HOST           (default: 127.0.0.1)
OCI_DB_PORT        (default: 6002)
OCI_PHP_BIN        (default: php8.1)
OCI_WEB_DIR        (default: /home/ubuntu/laesh-stack/www)
```

### Hostinger (`setup_hostinger.sh`)

```bash
H_ROOT_PASS   (sin default — OBLIGATORIO pasar)
H_APP_PASS    (sin default — OBLIGATORIO pasar)
H_DB_HOST     (default: 127.0.0.1)
H_DB_PORT     (default: 3306)
H_PHP_BIN     (default: php8.3)      # KVM2: PHP 8.3 nativo (PPA Ondrej)
H_WEB_DIR     (default: /opt/laesh/www)  # KVM2: raíz real del stack
```

---

## Incompatibilidades entre Entornos

| Script | Falla en OCI/Hostinger porque |
|--------|-------------------------------|
| `01_install_auth.sh` | Usa `docker exec restaurantb_db` — ese contenedor no existe en OCI/Hostinger. |
| `02_seed_users.sh` | Usa `docker exec restaurantb_phpfpm` — PHP-FPM corre nativo en OCI/Hostinger; la ruta del script también difiere. |

Los orquestadores `setup_oci.sh` y `setup_hostinger.sh` reemplazan ambos scripts con equivalentes nativos para cada entorno, incluyendo el paso de `ALTER USER` para corregir la contraseña de `laesh_app` que `00_database.sql` crea con el valor DEV (`laesh_2026_dev`).
