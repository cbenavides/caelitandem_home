# setup/bds/laesh/ — Pipeline de Setup de BD LAESH

## ¿Qué hay aquí?

Scripts de inicialización de la base de datos `laesh_db` para **LAESH Bloc Digital**.
Son herramientas de **DevOps / primer arranque o deploy incremental**, no de operación recurrente.

```
setup/bds/laesh/
├── setup_hostinger.sh        ← Orquestador KVM2/Producción (SSOT)
├── setup.sh                  ← Orquestador local / Docker (dev)
├── setup_oci.sh              ← Orquestador OCI (alternativo)
├── migrations/               ← Deltas incrementales a BD viva (vacío = sin pendientes)
│   └── README.md
├── bash/
│   ├── docker-local/         ← Solo dev Docker (01_install_auth, 02_seed_users)
│   ├── cms-sync/             ← Propagación CMS local → KVM2
│   ├── verify/               ← Smoke-tests universales (03_test_deploy)
│   └── kvm2/                 ← Específico KVM2 (06_verify_traceability)
├── 00_database.sql           ← BD + usuario laesh_app
├── 01_auth_schema.sql        ← Auth schema (tablas Delight-Auth)
├── 02_core_schema.sql        ← CONFIGURACIONES, WEB_CONTENIDOS, ESTUDIOS, CATALOGOS_UI
├── 03_transactional_schema.sql ← ORDENES, NOTIFICACIONES, HISTORIAL
├── 04_auth_extensions.sql    ← EMPLEADOS, PERFILES_MEDICOS, RBAC, jwt_jti_registry
├── 05_system_tables.sql      ← SYS_LOGS, FALLBACK_LOG + Event Scheduler
├── 06_indexes.sql            ← Índices de rendimiento
├── 07_seed_catalogs.sql      ← Catálogos, estudios, configuraciones, web_contenidos
├── 08_stored_procedures.sql  ← Procedimientos: CrearOrden, ProcesarPDF
└── 09_views.sql              ← Vistas: vw_ordenes_completas, vw_pacientes_historial
```

---

## Dos flujos de uso

| Escenario | Cuándo | Comando |
|---|---|---|
| **Setup desde cero** (servidor nuevo / `--nuke`) | Primera instalación, reset total | `setup_hostinger.sh --drop` — corre 00–09 + seed |
| **Deploy incremental** (BD viva, sin `--drop`) | Cambios de schema o datos en producción | Crear `migrations/mNNN_*.sql` → `deploy.sh bd` |

> **Regla:** Los scripts 00–09 son la **fuente de verdad del schema completo**.  
> `migrations/` solo contiene deltas activos aún no foldeados al script base.  
> Tras validar una migración en producción: integrar el cambio al 00–09 correspondiente y eliminar el `mNNN_*.sql`.

---

## ¿Quién ejecuta esto y cuándo?

| Momento | Entorno | Orquestador | Acción |
|---------|---------|-------------|--------|
| **Setup desde cero KVM2** (producción) | KVM2 nativo | `setup_hostinger.sh --drop` | Via `kvm2_setup.sh --nuke` o directo |
| **Deploy incremental KVM2** (BD viva) | KVM2 nativo | `deploy.sh bd` (local) | Crea `migrations/mNNN.sql` → `deploy.sh bd` |
| **Primer arranque local** (dev Docker) | Docker | `setup.sh` | Desde el host; usa `docker exec` |
| **Reseteo local** (dev) | Docker | `setup.sh` | Idempotente |
| Operación diaria | — | Nadie | No se ejecutan en runtime |

---

## Uso

### A) Producción KVM2 — setup desde cero

Invocado automáticamente por `kvm2_setup.sh --nuke`. También ejecutable directo:

```bash
# En KVM2 (creds leídas de /opt/laesh/configs/.env y .mariadb-root.cnf):
bash ~/staging/setup/bds/laesh/setup_hostinger.sh --drop

# Pipeline interno (setup_hostinger.sh --drop):
Paso 1  │ DROP DATABASE laesh_db + recrear
Paso 2  │ 00–09 scripts en orden (schema completo + seed)
Paso 2b │ migrations/m*.sql (no-op si directorio vacío)
Paso 3  │ ALTER USER laesh_app → contraseña producción
Paso 3b │ Least Privilege: REVOKE ALL + GRANT SELECT,INSERT,UPDATE,DELETE
Paso 4  │ php8.3 commons/seed_first_users.php → 7 usuarios
```

### B) Producción KVM2 — deploy incremental (BD viva)

```bash
# 1. Crear migrations/mNNN_descripcion.sql (idempotente)
# 2. Desde local:
bash setup/deploy/laesh-kvm2-prod/deploy.sh bd

# deploy.sh bd hace:
#   → rsync setup/bds/ → KVM2 staging
#   → setup_hostinger.sh sin --drop en KVM2
#   → Paso 2b aplica los m*.sql nuevos
#   → Pasos 3, 3b, 4 idempotentes

# 3. Tras validar: fold el cambio al script base 00-09 + eliminar mNNN_*.sql
```

### C) Local Docker — desarrollo

```bash
# Desde la raíz del repo restaurantb/
bash setup/bds/laesh/setup.sh
```

Pipeline interno (setup.sh):
```
Paso 0  │ bash/docker-local/01_install_auth.sh   → 7 tablas Delight-Auth (docker exec)
Paso 01 │ 00_database.sql                       → BD laesh_db + usuario laesh_app
Paso 02–10 │ 01–09_*.sql                        → schema completo
Paso 11 │ bash/docker-local/02_seed_users.sh    → usuarios demo (docker exec)
```

Todo es **idempotente**: puede re-ejecutarse sin errores ni datos duplicados.

---

## Variables de entorno

### KVM2 / Producción (`setup_hostinger.sh`)

| Variable | Fuente | Descripción |
|----------|--------|-------------|
| `H_ROOT_PASS` | `/opt/laesh/configs/.mariadb-root.cnf` (auto) o env var | Contraseña root MariaDB |
| `H_APP_PASS` | `/opt/laesh/configs/.env` (auto) o env var | Contraseña laesh_app producción |
| `H_PHP_BIN` | `php8.3` (default) | Binario PHP nativo |
| `H_WEB_DIR` | `/opt/laesh/www` (default) | Raíz www en servidor |

### Local / Docker (`setup.sh`)

| Variable | Default | Descripción |
|----------|---------|-------------|
| `DB_HOST` | `127.0.0.1` | Host MariaDB (puerto expuesto) |
| `DB_PORT` | `6002` | Puerto expuesto de MariaDB en docker-compose |
| `DB_PASS` | `comite_2026` | Contraseña root mysql |
| `DB_CONTAINER` | `restaurantb_db` | Nombre contenedor MariaDB |
| `WEB_CONTAINER` | `restaurantb_phpfpm` | Nombre contenedor PHP-FPM |

---

## Pre-requisitos

### KVM2
- Stack instalado (Nginx, PHP-FPM, MariaDB): pipeline `01–05` ya corrido
- `/opt/laesh/configs/.env` con `LAESH_APP_PASS` y `LAESH_SMTP_PASS`
- `/opt/laesh/configs/.mariadb-root.cnf` con contraseña root

### Local Docker
1. Contenedores corriendo: `cd contenedor/ && docker compose up -d`
2. Verificar: `docker ps` — deben aparecer `restaurantb_db` y `restaurantb_phpfpm`
3. Cliente `mysql` disponible en el host

---

## Usuarios semilla creados (solo dev)

| Rol | Teléfono | Contraseña | Cambiar en producción |
|-----|----------|------------|----------------------|
| ADMIN | 9990000001 | `04041980` | ✅ Obligatorio |
| RECEPCION | 9990000002 | `04041981` | ✅ Obligatorio |
| MEDICO | 9990000003 | `04041982` | ✅ Obligatorio |

> Generadas por `commons/seed_first_users.php` (secuencia `04041980+n`).
> Documentación completa de seed (incluye 7 usuarios) en `bash/README.md`.

Login:
- **Local Docker:** `https://localhost:8443/laesh/`
- **Producción (KVM2):** `https://laesh.mx/`

---

## Relación con `www/laesh-swbldi/commons/`

| Script | Naturaleza | Ejecutado por | Contexto |
|--------|-----------|---------------|----------|
| `bash/docker-local/01_install_auth.sh` | Setup BD | Host (docker exec) | Fuera del contenedor |
| `bash/docker-local/02_seed_users.sh` | Setup BD | Host (docker exec) | Fuera del contenedor |
| `commons/seed_first_users.php` | Idem (invocado por bash/02) | PHP-FPM (dentro del contenedor) | Runtime web |
| `commons/DB.php`, `RbacManager.php`… | Runtime web | PHP-FPM en cada request | Runtime web |

Los `.sh` **no pertenecen** a `commons/` porque necesitan acceso al Docker socket del host
para ejecutar `docker exec`. Si vivieran dentro del volumen web, no podrían hacerlo.

---

## Changelog de Fixes Estructurales

### 2026-09-06 (sesión 2) — G1 logAlways() + G-DEV-01 Modal Perfil Médico

| Archivo | Cambio | Gap |
|---------|--------|-----|
| `commons/Logger.php` | `log()` refactorizado → extrae `doWrite()` privado. Nuevo método público `logAlways()` que llama `doWrite()` sin filtro de nivel. | G1 |
| `website/login/login.php` | Login exitoso → `Logger::logAlways('INFO', ...)` | G1 |
| `website/login/logout.php` | Sesión cerrada → `Logger::logAlways('INFO', ...)` | G1 |
| `rc/negocio/Ordenes.php` | Orden recepción creada, cambio estado, médico registrado, admin cambió estado médico → `logAlways` | G1 |
| `md/negocio/Ordenes.php` | Solicitud médica digital creada → `logAlways` | G1 |
| `admrc/index.php` | CMS sección publicada → `logAlways` | G1 |
| `laesh-web-assets-uipv1a/js/labadmin.js` | Stub `console.log` en `guardarPerfilMedico` reemplazado por interceptor `submit` + `fetch('/laesh/rc/medico/crear')`. Validación celular `\d{10}`. Distinción éxito (HX-Refresh:true) / error. | G-DEV-01 |

> ⚠️ Requiere deploy a KVM2.

### 2026-09-06 (sesión 1) — Trazabilidad E2E (G2–G5) + Purga Automática

| Archivo | Cambio | Gap / Issue |
|---------|--------|-------------|
| `05_system_tables.sql` | `sys_logs`: 4 columnas nuevas (`request_id`, `url`, `metodo`, `session_id`) + `KEY idx_request_id`. `SET GLOBAL event_scheduler = ON`. Evento purga extendido: WARN → 90d. | G3, G4, G5 |
| `bash/06_verify_traceability.sh` | **NUEVO** — Smoke-test G2–G5: columnas, event_scheduler, evt_purga, registros recientes, RBAC events, formato app.log. | Verificación |
| `setup_hostinger.sh` | Schema consolidado en scripts 00–09. Sin concepto de migrations (setup siempre desde cero con --drop). | Orquestación |

**Cambios en código PHP (desplegados en KVM2):**
- `commons/Logger.php`: INSERT extendido con `request_id` (G3), `url`/`metodo` (G4), `session_id` (G5). `logToFile()` con formato `[REQ:id] [LEVEL] [METHOD /url]`.
- `commons/RbacManager.php`: `requirePermission()` ahora emite `Logger::log('WARN',...)` en denegaciones y `Logger::log('INFO',...)` en redirects por no-autenticado (G2).
- `commons/commons.php`: **Bug fix** — `Flight::map('rbac',...)` movido fuera del `try/catch` de `DB::connect()`. Antes, si la BD fallaba transitoriamente, `rbac` no quedaba mapeado y cualquier ruta lanzaba "rbac must be a mapped method".

**Cambio operativo en KVM2:**
- Cron `laesh-backup`: `0 * * * *` (horario) → `0 20 * * *` (diario 8 PM) + log: `backup-db.log`
- `event_scheduler = ON` activado vía `SET GLOBAL` (manual 2026-09-06; permanente via `05_system_tables.sql` en re-deploys).

### 2026-09-03 — Sesión de Corrección de Gaps de Congruencia

| Script | Cambio | Gap corregido |
|--------|--------|--------------|
| `03_transactional_schema.sql` | `notificaciones.tipo` ENUM ampliado: añadido `'orden_actualizada'` | GAP-05: el evento de cambio de estado no se podía persistir en BD |
| `08_stored_procedures.sql` | `CrearOrdenLaboratorio`: historial usa `COALESCE(p_recepcion_id, p_medico_id)` como `cambiado_por_user_id` | GAP-04: solicitudes digitales del médico quedaban sin actor en el historial |

**Cambios en BD de producción (ya ejecutados vía `ALTER`):**
- `ALTER TABLE notificaciones MODIFY COLUMN tipo ENUM('nueva_orden','resultados_listos','orden_actualizada')` — alineado en script 03.
- `UPDATE perfiles_medicos SET total_ordenes = (SELECT COUNT(*) FROM ordenes o WHERE o.medico_id = pm.user_id)` — retroactivo, no requiere cambio de schema.

**Cambios en lógica PHP (no reflejados en SQL scripts — son código de aplicación):**
- `commons/notifier.php`: eliminado `user_id = 2` hardcoded; ahora consulta dinámica de todos los `RECEPCION`/`ADMIN` activos (GAP-02).
- `rc/negocio/Ordenes.php:cambiarEstado`: eliminado `SELECT id FROM empleados` innecesario; usa `$userId` directo (GAP `cambiarEstado`).
- `rc/negocio/Ordenes.php:crearOrden` y `md/negocio/Ordenes.php:crearSolicitudDigital`: añadido `UPDATE perfiles_medicos SET total_ordenes = total_ordenes + 1` (GAP-03).
- `md/negocio/Ordenes.php:obtenerPacientesMedico`: corregido nombre de tabla `cat_estados_orden` → `catalogo_estados` (GAP-01) y placeholders PDO duplicados `:medico_id` → `:mid1/:mid2/:mid3` (GAP-06).
