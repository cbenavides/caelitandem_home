# setup/bds/laesh/ — Pipeline de Setup de BD LAESH

## ¿Qué hay aquí?

Scripts de instalación de la base de datos `laesh_db` para **LAESH Bloc Digital**.
Son herramientas de **DevOps / primer arranque**, no de operación recurrente.

```
setup/bds/laesh/
├── setup.sh                  ← Orquestador principal (único punto de entrada)
├── bash/
│   ├── 01_install_auth.sh    ← Paso 0: tablas Delight-Auth
│   └── 02_seed_users.sh      ← Paso 10: usuarios semilla
├── 00_database.sql           ← BD + usuario laesh_app
├── 01_auth_schema.sql        ← Placeholder (tablas ya creadas por bash/01)
├── 02_core_schema.sql        ← CONFIGURACIONES, WEB_CONTENIDOS, ESTUDIOS, CATALOGOS_UI
├── 03_transactional_schema.sql ← ORDENES, NOTIFICACIONES, HISTORIAL
├── 04_auth_extensions.sql    ← EMPLEADOS, PERFILES_MEDICOS, RBAC
├── 05_system_tables.sql      ← SYS_LOGS, FALLBACK_LOG + Event Scheduler
├── 06_indexes.sql            ← Índices de rendimiento
├── 07_seed_catalogs.sql      ← Catálogos, estudios, configuraciones
├── 08_stored_procedures.sql  ← Procedimientos: CrearOrden, ProcesarPDF
└── 09_views.sql              ← Vistas: vw_ordenes_completas, vw_pacientes_historial
```

---

## ¿Quién ejecuta esto y cuándo?

| Momento | Responsable | Acción |
|---------|-------------|--------|
| **Primer arranque** del stack en una máquina nueva | Desarrollador / DevOps | `bash setup.sh` desde el host |
| **Reseteo de datos** en desarrollo | Desarrollador | `bash setup.sh` (idempotente) |
| **Deploy a OCI / producción** | DevOps (manual, con vars de entorno) | Ver sección Variables más abajo |
| Operación diaria | Nadie | Estos scripts no se ejecutan en runtime |

> **Regla**: Solo se ejecutan desde el **host** (fuera de los contenedores).  
> `setup.sh` llama a los scripts `bash/` que usan `docker exec` para entrar a los contenedores.

---

## Uso

```bash
# Desde la raíz del repo restaurantb/
bash setup/bds/laesh/setup.sh
```

### Pipeline que ejecuta internamente

```
Paso 0  │ bash/01_install_auth.sh   → 7 tablas Delight-Auth (CREATE IF NOT EXISTS)
Paso 01 │ 00_database.sql           → BD laesh_db + usuario laesh_app
Paso 02 │ 01_auth_schema.sql        → placeholder (tablas ya creadas en paso 0)
Paso 03 │ 02_core_schema.sql        → core schema
Paso 04 │ 03_transactional_schema.sql
Paso 05 │ 04_auth_extensions.sql    → empleados + RBAC
Paso 06 │ 05_system_tables.sql      → logs + event scheduler
Paso 07 │ 06_indexes.sql
Paso 08 │ 07_seed_catalogs.sql      → catálogos semilla
Paso 09 │ 08_stored_procedures.sql  → SP CrearOrdenLaboratorio + ProcesarCargaResultadoPDF
Paso 10 │ 09_views.sql               → vw_ordenes_completas, vw_pacientes_historial
Paso 11 │ bash/02_seed_users.sh      → 3 usuarios demo (ADMIN, RECEPCION, MEDICO)
```

Todo es **idempotente**: puede re-ejecutarse sin errores ni datos duplicados.

---

## Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `DB_HOST` | `127.0.0.1` | Host para conexión mysql directa (puerto expuesto) |
| `DB_PORT` | `6002` | Puerto expuesto de MariaDB en docker-compose |
| `DB_USER` | `root` | Usuario mysql para setup |
| `DB_PASS` | `comite_2026` | Contraseña root mysql |
| `DB_CONTAINER` | `restaurantb_db` | Nombre del contenedor MariaDB (usado por bash/01) |
| `WEB_CONTAINER` | `restaurantb_phpfpm` | Nombre del contenedor PHP-FPM (usado por bash/02) |

Sobreescribir en línea:
```bash
DB_PASS=mi_pass_prod bash setup/bds/laesh/setup.sh
```

---

## Pre-requisitos

1. Contenedores corriendo: `cd contenedor/ && docker compose up -d`
2. Verificar: `docker ps` — deben aparecer `restaurantb_db` y `restaurantb_phpfpm`
3. Cliente `mysql` disponible en el host (para los pasos SQL directos)

---

## Usuarios semilla creados (solo dev)

| Rol | Teléfono | Contraseña | Cambiar en producción |
|-----|----------|------------|----------------------|
| ADMIN | 9990000001 | 010120001! | ✅ Obligatorio |
| RECEPCION | 9990000002 | 010120002! | ✅ Obligatorio |
| MEDICO | 9990000003 | 010120003! | ✅ Obligatorio |

Login: `https://192.168.0.120:8443/laesh/`

---

## Relación con `www/laesh-swbldi/commons/`

| Script | Naturaleza | Ejecutado por | Contexto |
|--------|-----------|---------------|----------|
| `bash/01_install_auth.sh` | Setup BD | Host (docker exec) | Fuera del contenedor |
| `bash/02_seed_users.sh` | Setup BD | Host (docker exec) | Fuera del contenedor |
| `commons/seed_first_users.php` | Idem (invocado por bash/02) | PHP-FPM (dentro del contenedor) | Runtime web |
| `commons/DB.php`, `RbacManager.php`… | Runtime web | PHP-FPM en cada request | Runtime web |

Los `.sh` **no pertenecen** a `commons/` porque necesitan acceso al Docker socket del host
para ejecutar `docker exec`. Si vivieran dentro del volumen web, no podrían hacerlo.

---

## Changelog de Fixes Estructurales

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
