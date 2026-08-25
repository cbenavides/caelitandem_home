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
| `04_export_cms_seed.sh` | Exporta `web_contenidos` de BD local → regenera `07_seed_catalogs.sql` (REPLACE INTO). | **Solo local** (fuente de verdad) |

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

**No usar:** en OCI ni Hostinger. El equivalente productivo está integrado en `setup_oci.sh` y `setup_hostinger.sh`.

```bash
# Aislado (solo si necesitas re-sembrar usuarios en local):
bash setup/bds/laesh/bash/02_seed_users.sh
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

### `04_export_cms_seed.sh` — antes de rsync a producción

**Usar cuando:** hay ediciones en el CMS local (`/laesh/adrc/` → Gestión Web) que deben propagarse a OCI o Hostinger. Ejecutar **antes** del rsync para generar el diff revisable.

**No usar:** directamente en OCI o Hostinger (no tiene acceso a la BD local). No sustituye a un backup de la BD de producción.

```bash
# Desde local:
bash setup/bds/laesh/bash/04_export_cms_seed.sh

# Revisar qué cambió antes de comprometer:
git diff setup/bds/laesh/07_seed_catalogs.sql
```

---

## Flujo Operativo Típico

```bash
# ── Antes de cualquier deploy a producción ──────────────────────────────

# 1. Si hay cambios de contenido en CMS local → exportar:
bash setup/bds/laesh/bash/04_export_cms_seed.sh
git diff setup/bds/laesh/07_seed_catalogs.sql   # revisar cambios

# 2. Rsync al servidor destino (ver §19.2 o §19.3 del doc técnico)

# 3. En el servidor → ejecutar orquestador:
#    OCI:
bash ~/laesh-stack/setup/bds/laesh/setup_oci.sh --drop
#    Hostinger:
H_ROOT_PASS='<root>' H_APP_PASS='<app>' bash .../setup_hostinger.sh --drop

# 4. Verificar (siempre, sin excepción):
BASE=https://caelitandem.lat bash setup/bds/laesh/bash/03_test_deploy.sh
```

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
H_PHP_BIN     (default: php8.1)
H_WEB_DIR     (default: /var/www/laesh-stack/www)
```

---

## Incompatibilidades entre Entornos

| Script | Falla en OCI/Hostinger porque |
|--------|-------------------------------|
| `01_install_auth.sh` | Usa `docker exec restaurantb_db` — ese contenedor no existe en OCI/Hostinger. |
| `02_seed_users.sh` | Usa `docker exec restaurantb_phpfpm` — PHP-FPM corre nativo en OCI/Hostinger; la ruta del script también difiere. |

Los orquestadores `setup_oci.sh` y `setup_hostinger.sh` reemplazan ambos scripts con equivalentes nativos para cada entorno, incluyendo el paso de `ALTER USER` para corregir la contraseña de `laesh_app` que `00_database.sql` crea con el valor DEV (`laesh_2026_dev`).
