# laesh-kvm2-prod — Pipeline de Instalación

Setup nativo de **LAESH Bloc Digital v1.2** en Hostinger KVM2 (Ubuntu 24.04 LTS).
Sin Docker. Instalación idempotente paso a paso.

> **Principio de idempotencia**: Cada script verifica el estado antes de actuar.
> Re-ejecutar un script que ya corrió no produce efectos secundarios ni errores.

---

## Servidor

| Parámetro | Valor |
|-----------|-------|
| Proveedor | Hostinger KVM2 |
| SO | Ubuntu 24.04 LTS |
| IP pública | `83.136.219.193` |
| Hostname | `srv1930905.hstgr.cloud` |
| Usuario | `sysadmin` (sudo) |
| RAM | 8 GB · CPU 4 vCPU · Disco 100 GB NVMe |
| Dominio activo | `laesh.mx` → `83.136.219.193` · cert LE emitido 2026-09-05 |
| Alias SSH | `laesh-kvm2` (ver ~/.ssh/config en local) |

---

## Stack tecnológico

| Componente | Versión | Puerto / Socket |
|------------|---------|-----------------|
| Nginx | latest stable | 80, 443 |
| PHP-FPM | 8.3 (PPA Ondrej) | `/run/php/php8.3-fpm.sock` |
| MariaDB | 11.8 (repo oficial) | `127.0.0.1:3306` (solo loopback) |
| Swoole | 6.2.2 (via PECL) | `127.0.0.1:9502` |
| Composer | 2.x | — |
| certbot | latest | — |

---

## Diseño de disco `/opt/laesh/`

Todo el stack vive bajo `/opt/laesh/`. MariaDB usa un **symlink AppArmor-compatible**:
`/var/lib/mysql` → `/opt/laesh/laesh-db/` (AppArmor sigue viendo la ruta esperada).

```
/opt/laesh/
├── www/                      # permisos 755 root:root — sysadmin necesita poder traversar
│   └── laesh-swbldi/         #   código fuente PHP (portales md/rc/adrc/login/website)
│                             #   775 sysadmin:sysadmin — rsync vía sysadmin funciona
├── assets/                   # ← alias nginx para /laesh-web-assets-uipv1a/
│   └── laesh-web-assets-uipv1a/  #   CSS, JS, imágenes estáticos
│       ├── cms/              #   imágenes subidas por CMS — NUNCA en rsync (--exclude='cms/')
│       └── cms-trash/        #   papelera soft-delete (www-data:www-data 750) — NUNCA en rsync (--exclude='cms-trash/')
├── laesh-db/                 # datadir MariaDB (symlink ← /var/lib/mysql)
├── logs/                     # nginx, php-fpm, swoole, mariadb, backup, cert, monitor
├── https/                    # self-signed.crt/key (Modo A) · live/ symlink LE (Modo B)
├── backups/
│   └── db/                   # dumps .sql.gz rotados (7 días / 4 semanas)
├── uploads/
│   └── pdfs/                 # PDFs subidos (acceso interno via Nginx)
├── configs/                  # app-log-level.php, .mariadb-root.cnf, swaks.conf
├── cache/                    # CMS L2 cache (PrivateTmp-safe; LAESH_CACHE_DIR)
├── monitor/                  # cooldown state por servicio (*.last_alert)
├── scripts/                  # operacionales (start/stop/status/backup/restore/monitor)
└── crones/                   # systemd units, logrotate, cert check
```

> **⚠️ Permisos `/opt/laesh/www/`:** el directorio es `750 www-data:www-data` por defecto.
> Sysadmin necesita poder traversarlo para que rsync funcione. Verificar/corregir con:
> ```bash
> sudo chmod 755 /opt/laesh/www/
> ```
> `laesh-swbldi/` dentro es `775 sysadmin:sysadmin` — rsync puede leer/escribir sin sudo.

> **⚠️ Rutas críticas:**
> - PHP app → `/opt/laesh/www/laesh-swbldi/` (nginx `root`)
> - Assets CSS/JS → `/opt/laesh/assets/laesh-web-assets-uipv1a/` (nginx `alias`)
> - **No existe** `/opt/laesh/laesh-swbldi/` — desplegar ahí no tiene efecto.

---

## SERVER_MAP.env — Rutas Canónicas

Archivo bash-sourceable con **todas las rutas del proyecto** (local, KVM2 sistema, KVM2 app,
staging, stray). Es la única fuente de verdad de rutas — ningún script debe hardcodear paths.

```bash
# Ubicación en el repo local:
setup/deploy/laesh-kvm2-prod/SERVER_MAP.env

# En KVM2 (tras deploy):
~/staging/setup/deploy/laesh-kvm2-prod/SERVER_MAP.env
```

Variables principales:

| Variable | Valor |
|----------|-------|
| `KVM2_SSH` | `laesh-kvm2` (alias ~/.ssh/config) |
| `KVM2_STAGING_ROOT` | `/home/sysadmin/staging` |
| `KVM2_SETUP_DIR` | `${KVM2_STAGING_ROOT}/setup` |
| `KVM2_ASSETS_STAGING` | `${KVM2_STAGING_ROOT}/laesh-src/laesh-web-assets-uipv1a` |
| `KVM2_WEBAPP` | `/opt/laesh/www/laesh-swbldi` |
| `KVM2_ASSETS` | `/opt/laesh/assets/laesh-web-assets-uipv1a` |
| `KVM2_ASSETS_CMS` | `${KVM2_ASSETS}/cms` |
| `KVM2_BACKUPS_DB` | `/opt/laesh/backups/db` |
| `KVM2_MARIADB_ROOT_CNF` | `/opt/laesh/configs/.mariadb-root.cnf` |

---

## Estructura Staging en KVM2 (`~/staging/`)

Todo el material intermedio vive bajo `~/staging/` con dos roles distintos:

```
/home/sysadmin/staging/
├── setup/                              # scripts/pipeline — directorio FÍSICO (sin symlink)
│   ├── bds/
│   │   └── laesh/
│   │       ├── migrations/             #   m*.sql activos (vacío = sin pendientes)
│   │       ├── 00–09_*.sql             #   schema completo
│   │       └── setup_hostinger.sh      #   orquestador BD
│   └── deploy/
│       └── laesh-kvm2-prod/            #   pipeline 01–08 + SERVER_MAP.env + deploy.sh
└── laesh-src/                          # assets staging (paso 1 de deploy de assets)
    └── laesh-web-assets-uipv1a/        #   CSS/JS/img — revisión previa antes de publicar a prod
```

- **`~/staging/setup/`** — destino de `deploy.sh scripts`; desde aquí se ejecuta el pipeline.
- **`~/staging/laesh-src/laesh-web-assets-uipv1a/`** — staging intermedio de assets (`deploy.sh assets` → aquí; `deploy.sh assets-publish` → `/opt/laesh/assets/`).

El pipeline se ejecuta **directamente** desde `~/staging/setup/deploy/laesh-kvm2-prod/`.

> **Nota histórica:** Antes de 2026-09-09 existían `~/staging/laesh-setup/` (stale) y
> `~/staging/laesh-src/setup/`. Ambos eliminados/movidos en 2026-09-09:
> `mv ~/staging/laesh-src/setup ~/staging/setup && rm -rf ~/staging/laesh-setup`

---

## SSH — Alias canónico

El alias `laesh-kvm2` en `~/.ssh/config` del host local evita hardcodear IP/usuario:

```
Host laesh-kvm2
    HostName 83.136.219.193
    User sysadmin
    Port 22
    IdentityFile ~/.ssh/id_laesh_kvm2
    IdentitiesOnly yes
```

Todos los comandos en esta documentación usan `ssh laesh-kvm2` / `rsync ... laesh-kvm2:`.
Para regenerar la llave o configurarla de nuevo: `~/staging/setup/scripts/keyssh.sh`.

---

## Pre-requisitos antes de ejecutar el pipeline

### 1 — Variables de entorno obligatorias

Exportar en la sesión SSH antes de cualquier script:

```bash
# LAESH_ROOT_PASS — contraseña que TÚ defines para el usuario root de MariaDB.
#   Ubuntu 24.04 instala MariaDB con unix_socket (sin contraseña).
#   04_configure_stack.sh la establece automáticamente y guarda en .mariadb-root.cnf.
export LAESH_ROOT_PASS='comite_2026'

# LAESH_APP_PASS — contraseña que TÚ defines para el usuario laesh_app (usuario de la app PHP).
#   00_database.sql crea laesh_app con contraseña dev temporal.
#   setup_hostinger.sh paso 3 la sobreescribe con este valor.
#   04_configure_stack.sh la inyecta en php-fpm-laesh.conf.
#   El paso 06_deploy_app.sh falla con error explícito si no está definida.
export LAESH_APP_PASS='laesh_2026_dev'

# LAESH_SMTP_PASS — app-password Yahoo para alertas SMTP (monitor_services.sh).
#   07_security_harden.sh sustituye __SMTP_PASS__ en swaks.conf con este valor.
export LAESH_SMTP_PASS='hdkgcwhfadxzeyid'

# ── Modo B (dominio + Let's Encrypt) — solo cuando DNS laesh.mx apunte al server ──
# ⚠️ Omitir si DNS aún no está configurado — el paso 5 fallará al validar el dominio.
# Sin LAESH_DOMAIN → Modo A (self-signed, pura IP). Activar Modo B después:
#   export LAESH_DOMAIN='laesh.mx' && sudo -E bash 05_tls_certbot.sh
# export LAESH_DOMAIN='laesh.mx'
export LAESH_ADMIN_EMAIL='cbena999@gmail.com'   # ya es el default en 00_run_all.sh
```

Sin `LAESH_DOMAIN` → el pipeline corre en **Modo A** (self-signed, pura IP).

### 2 — Transferir código y scripts a KVM2: `deploy.sh`

El script canónico de deploy hace rsync de los componentes desde el repo local hacia KVM2:

```bash
# Desde la raíz del repo local (restaurantb/):

# ── Setup desde cero / re-deploy código ────────────────────────────────────
# Todo en un solo comando (webapp + assets paso-1 + scripts):
bash setup/deploy/laesh-kvm2-prod/deploy.sh all

# O componentes individuales:
bash setup/deploy/laesh-kvm2-prod/deploy.sh webapp          # PHP app → /opt/laesh/www/laesh-swbldi/ + reload php-fpm
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets          # CSS/JS → staging KVM2 (paso 1/2, sin cms/)
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets-publish  # staging → producción KVM2 (paso 2/2)
bash setup/deploy/laesh-kvm2-prod/deploy.sh scripts         # setup/ → ~/staging/setup/

# ── Deploy incremental de BD (BD viva, sin --drop) ─────────────────────────
# Prerrequisito: crear migrations/mNNN_descripcion.sql (idempotente)
bash setup/deploy/laesh-kvm2-prod/deploy.sh bd
# Hace: rsync bds/ → staging + setup_hostinger.sh sin --drop en KVM2
# Paso 2b aplica los m*.sql activos. Tras validar: fold al script base + borrar m*.sql
```

### Deploy de assets — flujo en dos pasos

Assets **no van directo a producción** para poder revisarlos antes de publicar:

| Paso | Comando | Origen | Destino |
|------|---------|--------|---------|
| **1/2** | `deploy.sh assets` | `www/laesh-web-assets-uipv1a/` (local) | `~/staging/laesh-src/laesh-web-assets-uipv1a/` (KVM2 staging) |
| **2/2** | `deploy.sh assets-publish` | staging KVM2 | `/opt/laesh/assets/laesh-web-assets-uipv1a/` (KVM2 producción) |

Ambos pasos usan `--exclude='cms/'` y `--exclude='cms-trash/'` — las imágenes del CMS y su papelera de soft-delete nunca se tocan en deploy.

`deploy.sh all` ejecuta webapp + assets paso-1 + scripts. **El paso 2 (`assets-publish`) siempre
es explícito** para dar oportunidad de revisar staging antes de publicar.

| Comando | Origen local | Destino KVM2 | Efecto adicional |
|---------|-------------|-------------|-----------------|
| `webapp` | `www/laesh-swbldi/` | `/opt/laesh/www/laesh-swbldi/` | reload php8.3-fpm |
| `assets` (paso 1/2) | `www/laesh-web-assets-uipv1a/` | `~/staging/laesh-src/laesh-web-assets-uipv1a/` | — |
| `assets-publish` (paso 2/2) | staging KVM2 | `/opt/laesh/assets/laesh-web-assets-uipv1a/` | — |
| `bd` | `setup/bds/` | `~/staging/setup/bds/` | + `setup_hostinger.sh` sin `--drop` en KVM2 |
| `scripts` | `setup/` | `~/staging/setup/` | — |
| `all` | webapp + assets + scripts | — | no incluye `assets-publish` ni `bd` |

> **`deploy.sh webapp`** también recarga `php8.3-fpm` automáticamente (requiere sudo sin contraseña
> para ese comando — ver §Sudoers más abajo).

> **Pre-requisito:** `/opt/laesh/www/` debe tener permisos `755`:
> ```bash
> ssh laesh-kvm2 "sudo chmod 755 /opt/laesh/www/"
> ```

> **Cuándo ejecutarlo:** siempre que cambies código PHP, assets o scripts en local y necesites
> propagar a producción. Con `--checksum` detecta solo archivos realmente modificados.

### 3 — Dar permisos de ejecución al pipeline

Una vez que el rsync completa, **en el servidor**:

```bash
ssh laesh-kvm2 "chmod +x ~/staging/setup/*.sh ~/staging/setup/scripts/*.sh 2>/dev/null; echo OK"
```

### 4 — Verificar pre-requisitos en el servidor antes de ejecutar

```bash
ssh laesh-kvm2 "
  echo 'ROOT: ${LAESH_ROOT_PASS:+[OK — definida]}'
  echo 'APP:  ${LAESH_APP_PASS:+[OK — definida]}'
  echo 'SMTP: ${LAESH_SMTP_PASS:+[OK — definida]}'
  ls ~/staging/setup/bds/laesh/setup_hostinger.sh
  ls ~/staging/setup/06_deploy_app.sh
"
```

---

## Sudoers — operaciones sin contraseña

`/etc/sudoers.d/laesh-deploy` cubre los casos que requieren sudo desde SSH no-interactivo
(deploy.sh, inspección remota de logs). **Configurar/actualizar en terminal interactiva KVM2:**

```bash
sudo bash -c 'cat > /etc/sudoers.d/laesh-deploy << "EOF"
# PHP-FPM reload — deploy.sh webapp
sysadmin ALL=(ALL) NOPASSWD: /bin/systemctl reload php8.3-fpm
# Swoole restart — deploy.sh webapp (2026-09-18, Gap 6: reload NO recarga código,
# ver Especificacion_Tecnica §2.4c — se requiere restart real tras cada deploy)
sysadmin ALL=(ALL) NOPASSWD: /bin/systemctl restart swoole-laesh
# Lectura de logs restringidos — inspección remota sin terminal interactiva
sysadmin ALL=(ALL) NOPASSWD: /bin/cat /opt/laesh/logs/*
sysadmin ALL=(ALL) NOPASSWD: /usr/bin/tail /opt/laesh/logs/*
EOF
chmod 440 /etc/sudoers.d/laesh-deploy'
# Verificar sintaxis:
sudo visudo -c -f /etc/sudoers.d/laesh-deploy
```

> **Hallazgo 2026-09-18:** sin esta línea, `deploy.sh webapp` reportaba
> `✓ swoole-laesh reiniciado y respondiendo` **falsamente** — el `sudo systemctl restart`
> fallaba silenciosamente (`2>/dev/null || true`) por falta de sudoers, y el `curl /status`
> posterior solo confirmaba que el proceso VIEJO seguía vivo, no que hubiera código nuevo.
> Verificar con `systemctl show swoole-laesh -p ActiveEnterTimestamp` que el timestamp
> sea reciente tras cada deploy que toque `swoole_server.php`/`notifier.php`/`JwtManager.php`.

Una vez instalada, la inspección de logs funciona vía SSH no-interactivo:
```bash
ssh laesh-kvm2 "sudo tail -20 /opt/laesh/logs/monitor-services.log"
ssh laesh-kvm2 "sudo cat /opt/laesh/logs/nginx-error.log"
```

---

## Modos TLS

| Modo | Cuándo | Cert | HSTS |
|------|--------|------|------|
| **A — IP / self-signed** | Pre-DNS, pruebas del stack | `openssl req -x509` en `/opt/laesh/https/` | ❌ no |
| **B — Dominio + LE** | DNS `laesh.mx` apunta al VPS | Let's Encrypt via certbot | ✅ sí (1 año) |

El script `05_tls_certbot.sh` detecta el modo automáticamente por la presencia de `LAESH_DOMAIN`.
Pasar de Modo A a Modo B: `export LAESH_DOMAIN=laesh.mx && sudo -E bash 05_tls_certbot.sh`.

---

## Secuencia de ejecución

### Opción A — Pipeline completo automático

```bash
ssh laesh-kvm2
cd ~/staging/setup
export LAESH_ROOT_PASS='comite_2026'
export LAESH_APP_PASS='laesh_2026_dev'
export LAESH_SMTP_PASS='hdkgcwhfadxzeyid'
sudo -E bash 00_run_all.sh
```

### Opción B — Paso a paso (recomendado en primera instalación)

```bash
# Asegurar que las variables están definidas (ver §Pre-requisitos):
export LAESH_ROOT_PASS='comite_2026'
export LAESH_APP_PASS='laesh_2026_dev'
export LAESH_SMTP_PASS='hdkgcwhfadxzeyid'

cd ~/staging/setup

sudo bash 01_preflight.sh
sudo bash 02_install_stack.sh
sudo bash 03_install_swoole.sh
sudo -E bash 04_configure_stack.sh  # inyecta LAESH_APP_PASS en php-fpm-laesh.conf
sudo bash 05_tls_certbot.sh         # Modo A (self-signed) por defecto
sudo -E bash 06_deploy_app.sh       # rsync + BD + Composer; usa LAESH_ROOT_PASS/APP_PASS
sudo -E bash 07_security_harden.sh  # UFW, SMTP conf, log-levels, OPcache, cron backup
sudo bash 08_verify.sh              # 15 checks internos + 27 checks HTTP
```

### Flags de `06_deploy_app.sh` — Referencia rápida

| Flag | Efecto | Cuándo usar |
|------|--------|-------------|
| _(sin flags)_ | rsync código + assets (`--exclude='cms/'`) + permisos + Composer + BD (INSERT IGNORE) + Swoole restart | Primera instalación limpia o al aplicar migraciones SQL nuevas |
| `--skip-bd` | Igual que sin flags pero **omite pasos 6 y 6b** — BD no se toca | **Flujo normal de re-deploy de código** (PHP, JS, CSS) |
| `--drop` | Igual que sin flags pero destruye y recrea la BD completa | **Solo primera instalación** o reset intencional total |

> ⚠️ **Advertencias críticas:**
>
> - **`--drop` es DESTRUCTIVO** — elimina toda la BD (`DROP DATABASE`). Usar **únicamente** en primera
>   instalación en servidor limpio o cuando se requiere un reset total explícito. Nunca en producción
>   con datos vivos.
>
> - **Sin flags en producción**: `setup_hostinger.sh` ejecuta `07_seed_catalogs.sql` con
>   `INSERT IGNORE` (seguro desde 2026-09-06, commit `fe5b925`). **Preserva** los datos editados
>   en el CMS. Sin embargo, **sí sobreescribe** filas de `configuraciones` con `ON DUPLICATE KEY UPDATE`
>   — si cambiaste valores de configuración desde el CMS, revisa antes de correr sin `--skip-bd`.
>
> - **`--skip-bd` protege el CMS**: el rsync de assets ya incluye `--exclude='cms/'` — las imágenes
>   subidas por el CMS (hero slides, galería, OG image) sobreviven en todos los modos. Pero el
>   directorio `cms/` en el servidor **nunca llega al staging local** — no se respalda con `deploy.sh`.
>   Hacer SCP/rsync aparte si necesitas un backup local de esas imágenes.

---

### Opción C — Re-deploy de código (flujo normal de actualización)

> **Cuándo usar:** cambiaste PHP, assets o SQL localmente y necesitas aplicar en producción.
> El stack ya está instalado — **no** reinstalar Nginx/MariaDB/PHP.
>
> `deploy.sh scripts` sincroniza setup/ al **staging** del servidor (`~/staging/setup/`).
> `06_deploy_app.sh` toma el staging y lo despliega al webroot real (`/opt/laesh/www/`).
> Son pasos complementarios — uno no reemplaza al otro.

---

#### Opción C1 — Solo código PHP / JS / CSS (sin cambios de BD)

> **Cuándo usar:** los cambios son únicamente de código (`*.php`, `*.js`, `*.css`, `*.html`).
> No hay nuevas tablas ni seeds que aplicar. El CMS del servidor está vivo y **no debe tocarse**.
> **Este es el flujo más común en desarrollo activo.**

```bash
# ── Paso 1: Desde tu máquina local ──────────────────────────────────────────────
# webapp + assets(staging) + scripts en un comando:
bash setup/deploy/laesh-kvm2-prod/deploy.sh all

# O solo lo que cambió:
bash setup/deploy/laesh-kvm2-prod/deploy.sh webapp          # PHP cambió
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets          # CSS/JS cambió → staging KVM2 (paso 1/2)
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets-publish  # staging → producción (paso 2/2)

# ── Si necesitas también ejecutar 06_deploy_app.sh (permisos, Composer, Swoole) ──
ssh laesh-kvm2
echo 'laesh-26' | sudo -S env \
    LAESH_ROOT_PASS='comite_2026' \
    LAESH_APP_PASS='laesh_2026_dev' \
    bash ~/staging/setup/06_deploy_app.sh --skip-bd
```

> **`deploy.sh webapp` garantiza:**
> - ✅ rsync PHP → `/opt/laesh/www/laesh-swbldi/` (con `--delete`, elimina archivos obsoletos)
> - ✅ recarga `php8.3-fpm` automáticamente (requiere sudoers configurado — ver §Sudoers)
> - ✅ assets con `--exclude='cms/'` — imágenes CMS intactas

> **Flujo dos pasos para assets:**
> `deploy.sh assets` → staging en `~/staging/laesh-src/laesh-web-assets-uipv1a/`  
> `deploy.sh assets-publish` → producción en `/opt/laesh/assets/laesh-web-assets-uipv1a/`  
> El paso 2 es **siempre explícito** — nunca se ejecuta solo con `all`.

---

#### Opción C2 — Código + cambios de BD (deploy incremental)

> **Cuándo usar:** hay cambios de schema o datos (`migrations/m*.sql`) que deben aplicarse en
> producción además del código. La BD está viva — **sin `--drop`**.

```bash
# ── Paso 1: Crear la migración (local) ──────────────────────────────────────────
# setup/bds/laesh/migrations/mNNN_descripcion.sql — debe ser idempotente:
# ALTER TABLE ... IF NOT EXISTS, INSERT IGNORE, ON DUPLICATE KEY UPDATE, etc.

# ── Paso 2: Deploy completo desde local ─────────────────────────────────────────
bash setup/deploy/laesh-kvm2-prod/deploy.sh webapp   # PHP si hubo cambios
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets   # Assets si hubo cambios
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets-publish
bash setup/deploy/laesh-kvm2-prod/deploy.sh bd       # BD incremental: sync + setup_hostinger.sh

# deploy.sh bd hace:
#   1. rsync setup/bds/ → ~/staging/setup/bds/ (incluye el m*.sql nuevo)
#   2. bash ~/staging/setup/bds/laesh/setup_hostinger.sh  (sin --drop)
#      → Paso 2b aplica m*.sql en orden
#      → Pasos 3, 3b, 4 idempotentes (no-op si ya están aplicados)

# ── Paso 3: Tras validar ────────────────────────────────────────────────────────
# Fold el DDL/datos al script base 00-09 correspondiente
# Eliminar mNNN_*.sql de migrations/
# El directorio migrations/ debe tender a estar vacío de m*.sql
```

> Las migraciones `m*.sql` son **idempotentes** — pueden aplicarse múltiples veces sin efecto
> secundario. Ver `setup/bds/laesh/migrations/README.md` para guía completa.

---

#### Opción C3 — Hot-patch de un único archivo (sin rsync completo)

> **Cuándo usar:** corrección urgente de un solo archivo CSS/JS/PHP que no justifica
> correr el pipeline completo. El archivo debe estar ya modificado en local.
> **Flujo habitual para `landing.css`, `style.css`, scripts JS, PHP de cron, etc.**

```bash
# ── Paso 1: Subir el archivo al directorio temporal del servidor ─────────────────
# CSS / JS / asset (va a /opt/laesh/assets/):
scp laesh-web-assets-uipv1a/css/landing.css laesh-kvm2:/tmp/landing.css

# PHP de la app (va a /opt/laesh/www/):
scp laesh-swbldi/crons/cms_cleanup.php laesh-kvm2:/tmp/cms_cleanup.php

# ── Paso 2: Copiar del tmp al destino real con sudo ──────────────────────────────
# CSS / asset:
ssh laesh-kvm2 \
  "echo 'laesh-26' | sudo -S cp /tmp/landing.css \
   /opt/laesh/assets/laesh-web-assets-uipv1a/css/landing.css && echo OK"

# PHP cron (en www/):
ssh laesh-kvm2 \
  "echo 'laesh-26' | sudo -S cp /tmp/cms_cleanup.php \
   /opt/laesh/www/laesh-swbldi/crons/cms_cleanup.php && echo OK"

# PHP portal (en www/):
ssh laesh-kvm2 \
  "echo 'laesh-26' | sudo -S cp /tmp/admrc_index.php \
   /opt/laesh/www/laesh-swbldi/admrc/index.php && echo OK"
```

> **Rutas de destino (recordatorio):**
> - CSS/JS/img → `/opt/laesh/assets/laesh-web-assets-uipv1a/<subcarpeta>/`
> - PHP portales/crons → `/opt/laesh/www/laesh-swbldi/<ruta>/`
> - **No existe** `/opt/laesh/laesh-swbldi/` — desplegar ahí no tiene efecto visible.

> **Cuándo NO usar C3:** si hay más de 3 archivos modificados, usa `deploy.sh` (C1)
> para evitar inconsistencias entre local y servidor.

---

### Reanudar desde un paso fallido

```bash
ssh laesh-kvm2 "cd ~/staging/setup && sudo -E bash 00_run_all.sh --from=4"  # retoma desde 04
ssh laesh-kvm2 "cd ~/staging/setup && sudo -E bash 00_run_all.sh --only=6"  # solo 06
ssh laesh-kvm2 "cd ~/staging/setup && sudo -E bash 00_run_all.sh --skip=3"  # todos menos 03
```

---

## Scripts del pipeline

> **Leyenda:** `[SI]` = Instalación del Stack (apt/PECL) · `[DEPLOY]` = Despliegue de código/BD · `[CFG]` = Configuración · `[SEC]` = Seguridad/Hardening · `[VER]` = Verificación

| Script | Qué hace |
|--------|----------|
| `00_run_all.sh` | Orquestador — ejecuta 01→08 en orden; acepta `--from/--only/--skip` |
| `01_preflight.sh` | `[SI]` Swap 4 GB, sysctl, ulimits, árbol de directorios `/opt/laesh/`, copia configs (`.cnf` `.ini` `.conf` `.path` `.service`) / crones / scripts |
| `02_install_stack.sh` | `[SI]` **Instalación del Stack principal** — Nginx, MariaDB 11.8, PHP 8.3-FPM + extensiones apt, Composer, herramientas auxiliares; mueve datadir MariaDB con symlink AppArmor; usa `php8.3 -n` para evitar hang en re-runs post paso 7 — ver detalle abajo |
| `03_install_swoole.sh` | `[SI]` **Instalación Swoole** — Swoole 6.2.x via PECL; verifica versión via `strings` (no `php -r`) para ser seguro en re-runs con JIT+CLI activo |
| `04_configure_stack.sh` | `[CFG]` Copia configs al sistema, reemplaza `__LAESH_APP_PASS__`, establece contraseña root MariaDB, crea `.mariadb-root.cnf`, habilita systemd units, valida nginx/fpm |
| `05_tls_certbot.sh` | `[CFG]` **Dual-mode idempotente**: Modo A (self-signed) o Modo B (Let's Encrypt) según `LAESH_DOMAIN` |
| `06_deploy_app.sh` | `[DEPLOY]` rsync código fuente (con `--exclude='cms/'` en assets) + **mini-frameworks PHP vendored** (Flight, Plates, Delight-Auth en `libs/`), Composer install, inicializa BD (10 SQL + `INSERT IGNORE` seed), actualiza rutas KVM2 en BD, arranca Swoole · Flags: `--skip-bd` (omite BD — flujo normal C1), `--drop` (reset total — solo primera instalación) |
| `07_security_harden.sh` | `[SEC]` UFW, OPcache FPM (JIT tracing) + CLI (sin JIT — P-INFRA-02), cron backup diario 20:00 (backup-db.log), cron cms-cleanup 1 AM, cron expiry cert, monitor SMTP, log-levels systemd path unit, SSH hardening opcional |
| `08_verify.sh` | `[VER]` 28 checks internos (Sistema/Stack/Servicios/BD/Logs/Infra) + suite `bash/verify/03_test_deploy.sh`. PHP CLI via `php8.3 -n`; Swoole via `strings` (sin invocar PHP) |

### Detalle instalación del stack — `02_install_stack.sh` + `03_install_swoole.sh`

#### PHP 8.3 — extensiones instaladas vía apt

| Paquete apt | Función |
|---|---|
| `php8.3-fpm` | FastCGI Process Manager (pool `laesh`) |
| `php8.3-mysql` | Driver MariaDB/MySQL |
| `php8.3-curl` | HTTP cliente (monitor, cache warm-up) |
| `php8.3-mbstring` | Strings multibyte |
| `php8.3-xml` | Procesamiento XML/DOM |
| `php8.3-zip` | Manejo de archivos ZIP |
| `php8.3-intl` | Internacionalización ICU |
| `php8.3-gd` | Procesamiento de imágenes |
| `php8.3-opcache` | OPcache bytecode + JIT tracing |
| `php8.3-fileinfo` | Detección MIME real (validación CMS upload) |
| `php8.3-dev` | Headers de desarrollo (requerido para compilar Swoole PECL) |
| **Swoole 6.2.x** | via PECL — `03_install_swoole.sh` — WebSocket + HTTP IPC |

#### Herramientas auxiliares instaladas vía apt

| Paquete | Para qué se usa |
|---|---|
| `nginx` | Servidor web / reverse proxy |
| `mariadb-server` | Base de datos principal |
| `composer` | Gestor de dependencias PHP |
| `certbot` + `python3-certbot-nginx` | TLS Let's Encrypt (Modo B) |
| `gcc` `make` `autoconf` `libc-dev` `pkg-config` | Build tools para compilar Swoole PECL |
| `libssl-dev` | OpenSSL headers (Swoole `--enable-openssl`) |
| `libpcre2-dev` | PCRE2 headers (Nginx, PHP) |
| `libbrotli-dev` | Brotli headers (Swoole `--enable-brotli=yes`) |
| `unzip` | Descompresión (Composer, assets) |
| `jq` | Parseo JSON en scripts bash |
| `swaks` | Cliente SMTP — alertas de `monitor_services.sh` |
| `inotify-tools` | Utilidades inotify de diagnóstico (systemd path unit usa kernel inotify nativo) |
| `curl` | HTTP en `monitor_services.sh` y cache warm-up |

#### Mini-frameworks PHP — vendored (no se instalan, se despliegan)

Los tres mini-frameworks **ya están en el repo** (`www/laesh-swbldi/libs/`) y llegan a KVM2 vía rsync en `06_deploy_app.sh` paso 2/7. No requieren `apt` ni `pecl`.

| Framework | Rol |
|---|---|
| **Flight PHP** | Micro-router HTTP (rutas, middleware, request/response) |
| **Plates** | Motor de plantillas PHP nativo (layouts, partials) |
| **Delight-Auth** | Autenticación segura (sesiones, RBAC base, tokens) |

> `composer install` en paso 5/7 de `06_deploy_app.sh` instala las dependencias de `composer.json`
> de `laesh-swbldi`, pero los tres frameworks anteriores son **vendored directamente en `libs/`**
> — no pasan por Composer.

---

## Archivos de configuración (`configs/`)

| Archivo | Destino en servidor | Descripción |
|---------|--------------------|----|
| `mariadb-99-laesh.cnf` | `/etc/mysql/mariadb.conf.d/99-laesh.cnf` | bind 127.0.0.1, **2 GB pool**, NVMe IO capacity, tmp_table 64M |
| `php-99-laesh.ini` | `/etc/php/8.3/fpm/conf.d/99-laesh.ini` | hardened, timezone `America/Mexico_City`, session secure |
| `php-fpm-laesh.conf` | `/etc/php/8.3/fpm/pool.d/laesh.conf` | pool `laesh`, **30 workers**, unix socket, env vars DB, `__LAESH_APP_PASS__` |
| `nginx-base.conf` | `/etc/nginx/nginx.conf` | `user www-data`, **4096 conns**, gzip, open_file_cache, **limit_req_zone** login/api |
| `nginx-laesh-ip.conf` | `/etc/nginx/sites-available/laesh` | Modo A: `server_name _`, self-signed, sin HSTS; URL raíz `/` (no `/laesh/`); injection `$laesh_uri` para PHP routing; compat block `/laesh/` → `/`; ACME exception en HTTP |
| `nginx-laesh-domain.conf` | `/etc/nginx/sites-available/laesh` | Modo B: `__LAESH_DOMAIN__` placeholder (sed en 05), LE certs, HSTS 1 año; mismo layout `/` que ip.conf; ACME exception en HTTP para renovación |
| `10-opcache-laesh.ini` | FPM: `/etc/php/8.3/fpm/conf.d/10-opcache-laesh.ini` | OPcache 128 MB, JIT tracing 64 MB, `enable_cli=1` |
| _(generado por paso 7)_ | CLI: `/etc/php/8.3/cli/conf.d/10-opcache-laesh.ini` | **Sin JIT** (`opcache.jit=0`) — P-INFRA-02: JIT + Swoole en CLI = hang indefinido |
| `.mariadb-root.cnf` | `/opt/laesh/configs/.mariadb-root.cnf` | Credenciales root MariaDB via socket; `600 root:root`; usado por pasos 7/8 y logrotate |
| `laesh-log-levels.path` | `/etc/systemd/system/` | Systemd path unit — watch inotify sobre `log-levels.conf` |
| `laesh-log-levels.service` | `/etc/systemd/system/` | Systemd service — ejecuta `apply_log_levels.sh` en cambio de archivo |

---

## Crones y systemd (`crones/`)

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `swoole-laesh.service` | systemd unit | Swoole WS + HTTP IPC — `User=www-data`, `Restart=always`, `ExecStartPost` health check curl, `ExecReload` SIGHUP |
| `logrotate-laesh.conf` | logrotate | nginx, php-fpm, swoole (`systemctl reload` SIGHUP), mariadb, backup-db, cert-expiry, cms-cleanup — daily/weekly, compress |
| `check_cert_expiry.sh` | cron semanal (root) | Alerta si TLS vence en < 14 días; intenta auto-renew · log: `cert-expiry.log` |
| `cache_renew.cron` | cron diario 5 AM + @reboot (www-data) | Warm-up Cache L2 OPcache File Store — purge + re-fetch 4 datasets + curl FPM warm-up (~13 ms) |

### CMS Cleanup cron (`/etc/cron.d/laesh-cms-cleanup`)

```
0 1 * * * www-data /usr/bin/php8.3 /opt/laesh/www/laesh-swbldi/crons/cms_cleanup.php --dry-run >> /opt/laesh/logs/cms-cleanup.log 2>&1
```

**`cms_cleanup.php` soporta doble prefijo** (desde 2026-09-09):
- Canónico: `/laesh-web-assets-uipv1a/cms/`
- Legacy: `/laesh-web-assets-uipv1a/img/cms/`

Ambos prefijos son reconocidos como "en uso" — evita borrar imágenes con URLs legacy
que aún existan en BD aunque no hayan sido normalizadas por m003.

#### Cuándo mantener `--dry-run` (no borrar nada)

Mantener `--dry-run` activo mientras:
- Se están haciendo **pruebas activas del CMS** — riesgo de subir una imagen y que el
  cron nocturno la marque como huérfana antes de que se publique y quede referenciada en BD.
- Se están **re-subiendo imágenes** perdidas (galería calidad, hero slides, OG image).
- No se ha revisado el log al menos **un ciclo completo** (mínimo 2–3 días de log acumulado).

Durante `--dry-run` el script registra en el log qué borraría, pero no borra nada.
Revisar el log para confirmar que solo lista imágenes realmente huérfanas:

```bash
ssh laesh-kvm2 "tail -50 /opt/laesh/logs/cms-cleanup.log"
# Buscar líneas: "[DRY-RUN] borraría: ..." — verificar que NO aparezcan imágenes activas
```

#### Cuándo activar (quitar `--dry-run`)

Quitar `--dry-run` cuando se cumplan **todas** estas condiciones:
1. ✅ Las imágenes perdidas del deploy C1 ya fueron re-subidas vía CMS (galería calidad, hero).
2. ✅ El log muestra al menos 3 ejecuciones con resultados coherentes (solo lista candidatos
   genuinamente huérfanos — sin nombres de imágenes activas visibles en el sitio).
3. ✅ Ya no hay pruebas intensivas de subida/edición en curso.

```bash
# Activar en producción:
ssh laesh-kvm2 "sudo sed -i 's/ --dry-run//' /etc/cron.d/laesh-cms-cleanup && cat /etc/cron.d/laesh-cms-cleanup"
```

#### Reactivar `--dry-run` (volver al modo seguro)

Útil antes de cualquier migración de imágenes, redeploy masivo, o período de pruebas nuevo:

```bash
# Volver a modo seguro:
ssh laesh-kvm2 "sudo sed -i 's|cms_cleanup.php|cms_cleanup.php --dry-run|' /etc/cron.d/laesh-cms-cleanup && cat /etc/cron.d/laesh-cms-cleanup"
```

---

## Scripts operacionales (`scripts/`)

> **Despliegue al servidor:** llegan a `/opt/laesh/scripts/` vía `deploy.sh scripts`
> (rsync de `setup/`), **no** directamente por el pipeline `07_security_harden.sh`.
> Ejecutar `deploy.sh scripts` antes de usarlos si se modificaron localmente.

### Arranque / parada del stack

```bash
sudo bash /opt/laesh/scripts/laesh-start.sh      # arranca: mariadb → php-fpm → swoole → nginx
sudo bash /opt/laesh/scripts/laesh-stop.sh       # detiene: nginx → swoole → php-fpm → mariadb
sudo bash /opt/laesh/scripts/laesh-status.sh     # semáforo ✓/△/✗ + últimas líneas de logs
sudo bash /opt/laesh/scripts/swoole-restart.sh   # reinicia solo Swoole
```

### Backup y restore

```bash
sudo bash /opt/laesh/scripts/backup_db.sh                 # dump laesh_db → /opt/laesh/backups/db/
sudo bash /opt/laesh/scripts/backup_db.sh --weekly        # retención semanal (35 días)

# Prerrequisito restore: /opt/laesh/configs/.mariadb-root.cnf debe existir (creado en paso 04)
sudo bash /opt/laesh/scripts/restore_db.sh /opt/laesh/backups/db/laesh_db_YYYYMMDD_HHMMSS.sql.gz
```

### Clave SSH (`scripts/keyssh.sh`)

Script de conveniencia para generar la llave SSH local y configurar el alias:

```bash
# Generar llave ed25519 y agregar a ~/.ssh/config:
bash ~/staging/setup/scripts/keyssh.sh
# O desde local:
bash setup/deploy/laesh-kvm2-prod/scripts/keyssh.sh
```

---

## ⚠️ Acceso a MariaDB desde la terminal (KVM2)

En este servidor el usuario `root` de MariaDB **no usa el plugin `unix_socket`** — requiere
contraseña incluso en sesión local. `sudo mariadb` sin `-p` devuelve:

```
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
```

**Forma correcta** para cualquier comando SQL en el servidor:

```bash
# Usando .mariadb-root.cnf (recomendado — no expone password en ps aux):
sudo mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db

# Una sola consulta:
sudo mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db \
  -e "SELECT COUNT(*) FROM web_contenidos;"

# Alternativa con -p (expone password en shell history):
sudo mariadb -u root -p'comite_2026' laesh_db
```

> **Credencial root**: `comite_2026` (definida por `LAESH_ROOT_PASS` en el paso 4 del pipeline).
> También disponible en `/opt/laesh/configs/.mariadb-root.cnf` (solo root:root, modo 600).

---

## Arquitectura Swoole — doble rol

```
Browser  ──WS──►  Nginx :443 /ws  ──proxy──►  Swoole :9502  (WebSocket server)
PHP-FPM  ──HTTP─► http://127.0.0.1:9502/publish              (HTTP IPC bridge)
```

- **Fast-path**: PHP-FPM llama `/publish` → Swoole reenvía por WebSocket a los clientes conectados.
- **Slow-path fallback**: si Swoole no responde, `notifier.php` escribe en tabla `notificaciones` (BD).
- `notifier.php` detecta si está en Docker (`/.dockerenv`) o nativo; en nativo usa `127.0.0.1:9502`.

---

## Puertos y UFW

| Puerto | Servicio | Acceso |
|--------|----------|--------|
| 22 | SSH | ✅ público |
| 80 | Nginx HTTP | ✅ público (redirect → 443) |
| 443 | Nginx HTTPS | ✅ público |
| 3306 | MariaDB | 🔒 solo loopback (`bind-address=127.0.0.1`) |
| 9502 | Swoole | 🔒 solo loopback (Nginx proxy `/ws` expone WS) |

---

## Verificación final esperada (Modo A)

Tras `08_verify.sh`, el resultado esperado es **28/28 internos OK** + **26/27 HTTP** (solo HSTS falla por diseño):

```
✓ 28 OK  |  △ 0 Avisos  |  ✗ 0 Errores  |  Total: 28 — STACK OPERATIVO
Suite HTTP: 26/27 pruebas pasaron
```

| Check HTTP | Por qué falla en Modo A | Acción |
|------------|------------------------|--------|
| HSTS (`max-age=31536000`) | Sin LE cert; `nginx-laesh-ip.conf` no emite HSTS (self-signed no confiado) | Esperado — se activa en Modo B |

En Modo B (dominio + LE configurado): todos los 27 HTTP checks pasan.

---

## Caché L2 — OPcache PHP File Store (§15.9)

Implementada en el código fuente (`commons/Cache.php`). El pipeline la activa vía OPcache ini y el cron.

> **⚠️ PrivateTmp isolation**: `php8.3-fpm.service` tiene `PrivateTmp=true` en Ubuntu 24.04.
> Los workers FPM ven un `/tmp` aislado (namespace de kernel). El caché DEBE estar en
> `/opt/laesh/cache/` — **nunca en `/tmp/`** — para que FPM y el cron www-data vean
> el mismo directorio físico. El env var `LAESH_CACHE_DIR=/opt/laesh/cache` se inyecta
> en `php-fpm-laesh.conf` y en `/etc/cron.d/laesh-cache-renew`.

### Cómo funciona

```
1ª visita:  PHP → MariaDB → array → serialize → /opt/laesh/cache/laesh_cache_prod_LAESH_CMS.php
Siguientes: PHP → Cache::get() → include archivo → OPcache RAM hit (~0.07 ms)
CMS publica: admrc/index.php → Cache::invalidate([KEY_CMS]) → opcache_invalidate(archivo, true)
5 AM diario: cache_renew.php → purge + warm-up 4 datasets desde MariaDB (~13 ms)
```

### 4 datasets cacheados (portal público website/index.php)

| Clave | Tabla(s) | TTL | Invalidación |
|-------|----------|-----|-------------|
| `KEY_CFG` | `configuraciones` (52 filas, 3.4 KB) | 12 h | Sección configuracion-general CMS |
| `KEY_CMS` | `web_contenidos` (133 filas, 54 KB) | 10 min | Cualquier publicación CMS |
| `KEY_TREE` | `catalogo_grupos/categorias/estudios` (144 filas, 58 KB) | 24 h | Sección especialidades |
| `KEY_PROMOS` | `catalogo_promociones` (1–10 filas) | 10 min | Sección promociones |

**Benchmark:** 4 queries/request → 0 queries/request en cache hit. Latencia: 7.6 ms → 0.07 ms.

### Directorio de caché

`/opt/laesh/cache/` — creado en `01_preflight.sh` con `chown www-data:www-data / chmod 0750`.
El env var `LAESH_CACHE_DIR` apunta aquí; FPM y el cron lo ven en el mismo path físico.

### Warm-up y cron

```bash
# Verificar que el cron esté instalado
cat /etc/cron.d/laesh-cache-renew

# Forzar warm-up manual
sudo -u www-data LAESH_CACHE_DIR=/opt/laesh/cache php8.3 \
    /opt/laesh/www/laesh-swbldi/crons/cache_renew.php

# Ver log
tail -20 /opt/laesh/logs/cache-renew.log
```

---

## Monitoreo de Servicios y Alertas SMTP

`07_security_harden.sh` instala un cron `*/10 * * * *` que ejecuta `scripts/monitor_services.sh`.

### Servicios monitoreados

| Servicio | Verificación |
|----------|-------------|
| nginx | `systemctl` + `curl http://127.0.0.1/` |
| mariadb | `systemctl` + query `SELECT 1` via `.mariadb-root.cnf` |
| swoole-laesh | `systemctl` + `curl http://127.0.0.1:9502/status` |
| https_e2e | `curl -k https://127.0.0.1/` (stack completo — URL raíz activa) |

### Lógica de reintento y anti-spam

- **3 reintentos** con **30 s entre intentos** (`RETRY_WAIT=30`). Total máximo de espera antes de alertar: ~60 s.
- Si el servicio se recupera en algún reintento → no se envía alerta (blip transitorio).
- **Cooldown 30 min** por servicio — estado en `/opt/laesh/monitor/<svc>.last_alert`.
- `flock` evita ejecuciones solapadas si un ciclo tarda más de 10 min.

```bash
# Ver log de monitor:
tail -50 /opt/laesh/logs/monitor-services.log

# Forzar re-alerta (borrar cooldown de nginx):
sudo rm /opt/laesh/monitor/nginx.last_alert
```

---

## Log-Levels en Caliente (Hot Reload)

### Mecanismo

```
admin edita /opt/laesh/logs/log-levels.conf (o usa admrc UI, tab "Infra")
    → inotify detecta cambio (kernel) → laesh-log-levels.path dispara
    → laesh-log-levels.service ejecuta scripts/apply_log_levels.sh
    → MariaDB: SET GLOBAL slow_query_log / general_log / log_error_verbosity
    → Nginx: nginx -s reload (aplica error_log level al vuelo)
    → PHP-FPM: reload (aplica php.ini error_reporting al vuelo)
    → escribe /opt/laesh/configs/app-log-level.php (leído por Logger.php)
```

### Formato de `log-levels.conf`

```ini
nginx_error_level=warn          # debug|info|notice|warn|error|crit|alert|emerg
mariadb_slow_query_log=OFF      # ON|OFF
mariadb_slow_query_time=2       # segundos (0-300)
mariadb_log_error_verbosity=2   # 1=errores, 2=+warnings, 3=+notas
mariadb_general_log=OFF         # ON|OFF — activar solo para debugging breve
php_error_reporting=production  # production|development|off
app_log_level=WARN              # DEBUG|INFO|WARN|ERROR|CRITICAL|OFF
```

```bash
# Ver nivel activo:
sudo cat /opt/laesh/configs/app-log-level.php

# Aplicar cambio manualmente:
sudo bash /opt/laesh/scripts/apply_log_levels.sh
```

---

## Seguridad — Directivas adicionales en Nginx

### Verbos HTTP restringidos

Solo `GET`, `POST`, `HEAD` permitidos. `TRACE`, `OPTIONS`, `DELETE`, `PUT` devuelven `405`:
```nginx
if ($request_method !~ ^(GET|POST|HEAD)$) { return 405; }
```

### Rate limiting login

```nginx
# base.conf:
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
# site conf (location /login/):
limit_req zone=login burst=3 nodelay;
```

### Least Privilege MariaDB

`laesh_app` tiene solo permisos DML: `SELECT, INSERT, UPDATE, DELETE ON laesh_db.*`.
`07_security_harden.sh` paso 5 verifica que no haya `DROP`, `ALTER`, `ALL PRIVILEGES`.

### SSH Hardening (§1.5)

`07_security_harden.sh` paso 6. Requiere llave pública en `authorized_keys` antes de deshabilitar contraseña:
```bash
# Pre-requisito (desde tu máquina local):
bash setup/deploy/laesh-kvm2-prod/scripts/keyssh.sh
# Luego en el servidor:
sudo bash 07_security_harden.sh  # SSH hardening ON por default
```
Aplica: `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`.

#### ⚠ Conflicto cloud-init — `50-cloud-init.conf` (aplicado 2026-09-13)

Ubuntu 24.04 en Hostinger crea `/etc/ssh/sshd_config.d/50-cloud-init.conf` con
`PasswordAuthentication yes`. OpenSSH aplica la **primera ocurrencia** de cada directiva
y el `Include` está al inicio de `sshd_config` (línea 12), por lo que ese archivo anula
tanto `60-cloudimg-settings.conf` como el propio `sshd_config` — dejando password auth
efectivamente habilitada a pesar del hardening.

**Fix ya aplicado en KVM2 (2026-09-13):**
```bash
# Respaldo
sudo cp /etc/ssh/sshd_config.d/50-cloud-init.conf \
        /etc/ssh/sshd_config.d/50-cloud-init.conf.bak

# Corregir yes → no
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' \
    /etc/ssh/sshd_config.d/50-cloud-init.conf

# Validar y recargar
sudo sshd -t && sudo systemctl reload ssh

# Confirmar resultado efectivo (debe decir: passwordauthentication no)
sudo sshd -T | grep passwordauthentication
```

> **Nota para reinstalaciones:** tras un reset de OS en Hostinger, cloud-init regenera
> `50-cloud-init.conf` con `yes`. Repetir este fix **antes** de exponer el puerto 22.

---

## Reinstalación desde cero (OS reset → servidor limpio)

> **Cuándo usar:** reinstalación del SO en Hostinger panel, migración a servidor nuevo,
> o reset completo intencional. Para rollback parcial, ver sección **Rollback**.

### Paso 0 — Limpieza del servidor anterior (si aplica)

```bash
# 0a. Detener servicios
sudo systemctl stop swoole-laesh php8.3-fpm nginx mariadb 2>/dev/null || true
sudo systemctl disable swoole-laesh 2>/dev/null || true

# 0b. ⚠ BACKUP antes de limpiar — copiar backups y uploads a local:
scp -r laesh-kvm2:/opt/laesh/backups/db/ ./backup-pre-reinstall/
scp -r laesh-kvm2:/opt/laesh/uploads/    ./uploads-pre-reinstall/

# 0c. Limpiar árbol /opt/laesh/ completo
sudo rm -rf /opt/laesh/

# 0d. Limpiar crons y systemd
sudo rm -f /etc/cron.d/laesh-*
sudo rm -f /etc/systemd/system/swoole-laesh.service
sudo rm -f /etc/logrotate.d/laesh
sudo rm -f /etc/sudoers.d/laesh-deploy
sudo systemctl daemon-reload

# 0e. Limpiar nginx
sudo rm -f /etc/nginx/sites-available/laesh
sudo rm -f /etc/nginx/sites-enabled/laesh

# 0f. Limpiar cert LE (si se va a reutilizar el mismo dominio):
#   NO borrar — certbot reutiliza el cert existente mientras no haya caducado.
#   Solo borrar si cambias de dominio:
# sudo certbot delete --cert-name laesh.mx

# 0g. Limpiar staging en el home de sysadmin
rm -rf ~/staging/

# 0h. Verificar que quedó limpio
ls /opt/laesh/ 2>/dev/null && echo "WARN: /opt/laesh/ aún existe" || echo "OK: /opt/laesh/ limpio"
ls ~/staging/   2>/dev/null && echo "WARN: ~/staging/ aún existe" || echo "OK: ~/staging/ limpio"
```

### Paso 1 — Transferir pipeline y fuente (desde local)

```bash
# Desde la raíz del repo local — deploy completo (pipeline + app + assets + BD):
bash setup/deploy/laesh-kvm2-prod/deploy.sh all

# Verifica que llegó todo:
ssh laesh-kvm2 "ls ~/staging/setup/bds/laesh/setup_hostinger.sh && ls ~/staging/setup/deploy/laesh-kvm2-prod/SERVER_MAP.env"
```

### Paso 2 — Definir variables de entorno en el servidor

```bash
ssh laesh-kvm2
export LAESH_ROOT_PASS='comite_2026'
export LAESH_APP_PASS='laesh_2026_dev'
export LAESH_SMTP_PASS='hdkgcwhfadxzeyid'
export LAESH_ADMIN_EMAIL='cbena999@gmail.com'
export LAESH_DOMAIN='laesh.mx'   # solo si DNS apunta al servidor
```

### Paso 3 — Configurar permisos del pipeline y ejecutar

```bash
# deploy.sh scripts ya sincronizó setup/ a ~/staging/setup/ en el Paso 1.
# Solo dar permisos de ejecución:
chmod +x ~/staging/setup/*.sh ~/staging/setup/scripts/*.sh

# Configurar sudoers (PHP-FPM reload + restart Swoole + lectura de logs — ver § Sudoers):
# NOTA (2026-09-18): la línea de swoole-laesh es OBLIGATORIA — sin ella, deploy.sh
# falla en el restart del código nuevo del bridge WS con error silencioso (ver
# hallazgo Gap 6 §4.9 en Tecnica_Seguridad_Integral.html — deploy.sh reportaba
# éxito falso porque el proceso VIEJO seguía respondiendo a /status).
sudo bash -c 'cat > /etc/sudoers.d/laesh-deploy << "EOF"
sysadmin ALL=(ALL) NOPASSWD: /bin/systemctl reload php8.3-fpm
sysadmin ALL=(ALL) NOPASSWD: /bin/systemctl restart swoole-laesh
sysadmin ALL=(ALL) NOPASSWD: /bin/cat /opt/laesh/logs/*
sysadmin ALL=(ALL) NOPASSWD: /usr/bin/tail /opt/laesh/logs/*
EOF
chmod 440 /etc/sudoers.d/laesh-deploy'

# Ejecutar pipeline completo:
cd ~/staging/setup
sudo -E bash 00_run_all.sh

# Corregir permisos www/ para deploy futuro:
sudo chmod 755 /opt/laesh/www/
```

### Paso 4 — Solo si se necesita reset de BD con datos previos

```bash
# ⚠ DESTRUCTIVO — borra toda la BD y la recrea desde el seed.
LAESH_ROOT_PASS='comite_2026' LAESH_APP_PASS='laesh_2026_dev' sudo -E bash ~/staging/setup/06_deploy_app.sh --drop
```

### Paso 5 — Verificación final

```bash
# Suite 27 checks (HTTP, assets, CSP, PHP, seguridad):
BASE=https://laesh.mx bash ~/staging/setup/bds/laesh/bash/verify/03_test_deploy.sh

# Monitor manual inmediato:
sudo bash /opt/laesh/scripts/monitor_services.sh
tail -20 /opt/laesh/logs/monitor-services.log

# Backup inicial manual:
sudo bash /opt/laesh/scripts/backup_db.sh
ls -lh /opt/laesh/backups/db/
```

### Tiempo estimado de reinstalación

| Fase | Tiempo aprox. |
|------|--------------|
| Paso 0 (limpieza) | 2–3 min |
| Paso 1 (deploy local→servidor) | 3–5 min (depende de red) |
| Paso 2–3 (pipeline 01–04, 06–08) | 5–10 min |
| Paso 3 solo Swoole (compilación PECL) | 10–20 min |
| **Total** | **~25–40 min** |

---

## Rollback — Procedimientos ante fallo

### Rollback de configuración Nginx

```bash
sudo nginx -t                              # ver error exacto
sudo cp /etc/nginx/nginx.conf.bak nginx.conf
sudo systemctl reload nginx
```

### Rollback de deploy de código (rsync)

```bash
sudo rsync -av /opt/laesh/backups/www-FECHA/ /opt/laesh/www/
sudo systemctl restart php8.3-fpm
```

### Rollback de BD

```bash
ls -lh /opt/laesh/backups/db/
sudo bash /opt/laesh/scripts/restore_db.sh /opt/laesh/backups/db/laesh_db_YYYYMMDD_HHMMSS.sql.gz
# El script crea un backup previo automático antes de restaurar
```

### Rollback de versión PHP-FPM

```bash
sudo cp /etc/php/8.3/fpm/conf.d/99-laesh.ini.bak /etc/php/8.3/fpm/conf.d/99-laesh.ini
sudo systemctl reload php8.3-fpm
```

---

## Propagación de contenido CMS local → KVM2

### Flujo estándar (sin DROP)

```bash
# Paso 1 — Exportar web_contenidos de BD local a 07_seed_catalogs.sql
bash setup/bds/laesh/bash/cms-sync/04_export_cms_seed.sh

git diff setup/bds/laesh/07_seed_catalogs.sql

# Paso 2 — Importar solo web_contenidos en KVM2 vía SSH (sin DROP)
bash setup/bds/laesh/bash/cms-sync/05_import_cms_seed_kvm2.sh

# Paso 3 — Verificar en producción
BASE=https://laesh.mx bash setup/bds/laesh/bash/verify/03_test_deploy.sh
```

### Qué sobreescribe / qué conserva

| Flujo | `web_contenidos` | Config KVM2 | Datos operativos |
|-------|-----------------|-------------|-----------------|
| `04_export` + `05_import` | `REPLACE INTO` — propaga CMS local intencional | ✅ intacta | ✅ intactos |
| `06_deploy_app.sh` (sin `--skip-bd`) | `INSERT IGNORE` — solo inserta si no existe | ✅ intacta | ✅ intactos |

> **Regla:** El flujo export/import es el canal correcto para propagar contenido editorial CMS local → KVM2.
> El deploy no es el canal para propagar contenido CMS — solo instala filas iniciales que aún no existen.

---

## Gaps detectados y fixes aplicados (deploy 2026-09-04 / stabilización 2026-09-05)

### G-01 — HTTP 404 en `/laesh/`, `/laesh/adrc/`, `/laesh/login/login.php`

**Fix:** `nginx-laesh-ip.conf` y `nginx-laesh-domain.conf` — 3 location handlers específicos
declarados **antes** del genérico.

### G-02 — HTTP 404 en `/laesh-web-assets-uipv1a/css/portal.css` y `app.js`

**Fix:** `location ^~ /laesh-web-assets-uipv1a/` — el modificador `^~` detiene la
evaluación de regex para ese prefijo, forzando el bloque `alias` correcto.

### G-03 — `01_preflight.sh` no copiaba `.path`/`.service` a `/opt/laesh/configs/`

**Fix:** Agregadas 2 líneas en paso 5/5:
```bash
cp -v "${SETUP_DIR}"/configs/*.path    /opt/laesh/configs/ 2>/dev/null || true
cp -v "${SETUP_DIR}"/configs/*.service /opt/laesh/configs/ 2>/dev/null || true
```

### G-04 — `07_security_harden.sh` falso positivo en Least Privilege check

**Fix:** Preferir `.mariadb-root.cnf` (socket auth con contraseña) si existe;
fallback `-u root` solo en fresh install pre-paso-4.

### G-05 — P-INFRA-02: PHP CLI hang con OPcache JIT + Swoole

**Fix:** Paso 7 genera **dos** ini distintos: FPM con JIT tracing, CLI sin JIT.

### G-06 — `08_verify.sh` check Swoole devuelve versión errónea

**Fix:** `grep -oE '6[.][0-9]+[.][0-9]+' | sort -V | tail -1`.

### G-07 — `03_install_swoole.sh` y `02_install_stack.sh` usan `php8.3 -r` en re-runs

**Fix:** Idempotency checks usan `strings` sobre el `.so`; `php8.3 -n` donde procede.

### G-08 — URL raíz: app servida en `/laesh/` en vez de `/` (2026-09-05)

**Fix:** Todos los location blocks cambiados a raíz `/X`. Mecanismo `$laesh_uri` inyecta
el prefijo `/laesh` a PHP sin afectar la URL del browser.

### G-CERTBOT-01 — certbot `--nginx` crea duplicados TLS en nginx config (2026-09-05)

**Fix `05_tls_certbot.sh`:** Cambiado `certbot --nginx` → `certbot certonly --webroot`.

### G-BACKUP-01 — `backup_db.sh` producía dumps vacíos (20 bytes) sin alerta (2026-09-05)

**Fix:** `--defaults-extra-file=.mariadb-root.cnf` + trap EXIT + validación post-dump `stat -c%s`.

---

## Gaps y cambios — 2026-09-06b (Deploy C1 damage + 3 fixes)

### G-DEPLOY-C1 — Deploy C1 destruyó datos CMS en KVM2 (2026-09-06)

**3 fixes aplicados (commit `fe5b925`):**

| Fix | Archivo | Cambio |
|-----|---------|--------|
| **1** | `06_deploy_app.sh` | Flag `--skip-bd` — omite pasos 6 y 6b |
| **2** | `06_deploy_app.sh` | `--exclude='cms/'` en rsync assets |
| **3** | `07_seed_catalogs.sql` | `REPLACE INTO` → `INSERT IGNORE` en `web_contenidos` |

---

## Gaps y cambios — stabilización 2026-09-06 (Trazabilidad E2E + Fixes)

### G-RBAC-01 — "rbac must be a mapped method" con BD caída transitoriamente

**Fix:** `Flight::map('rbac', ...)` movido fuera del try/catch — closure lazy.

### G2 — RBAC silent denials (sin trazabilidad de accesos denegados)

**Fix:** `commons/RbacManager.php` emite `Logger::log('WARN', "RBAC: denegado...")` antes de halt(403).

### G3 — Sin request_id

**Fix:** `commons/Logger.php` — `$requestId = bin2hex(random_bytes(8))` estático por proceso.

### G4 — Sin url ni metodo en logs

**Fix:** `commons/Logger.php` — captura `$_SERVER['REQUEST_URI']` y `REQUEST_METHOD`.

### G5 — Sin session_id

**Fix:** `commons/Logger.php` — captura `session_id()` cuando hay sesión activa.

### Backup cron — cambio horario → diario 8 PM

**Antes:** `0 * * * *` · **Ahora:** `0 20 * * *` · Log: `backup.log` → `backup-db.log`.

### Event Scheduler MariaDB — activación permanente

`SET GLOBAL event_scheduler = ON` en `05_system_tables.sql` y `04_configure_stack.sh`.

---

## Gaps y cambios — Estabilización Swoole 2026-09-08

### G-SWOOLE-01 — binding `0.0.0.0` → `127.0.0.1` (Docker-aware)

**Fix:** `getenv('LAESH_WS_HOST') ?: ($inDocker ? '0.0.0.0' : '127.0.0.1')`.

### G-SWOOLE-02 — logrotate: SIGUSR1 incorrecto + 3 nombres de log erróneos

**Fix:** `systemctl reload` en postrotate; `backup.log`→`backup-db.log`, `cert-check.log`→`cert-expiry.log`, `cms-cleanup.log` añadido.

### G-SWOOLE-03 — sin health check post-arranque

**Fix:** `ExecStartPost=/bin/bash -c 'sleep 3 && curl -sf http://127.0.0.1:9502/status > /dev/null'`.

### G-SWOOLE-04 — ExecReload no declarado

**Fix:** `ExecReload=/bin/kill -HUP $MAINPID`.

### G-SWOOLE-05 — echo continuo en callbacks WS saturaba journald

**Fix:** 4 `echo` → `// Logger::log(..., 'DEBUG')` (comentados).

---

## Gaps y cambios — Estabilización KVM2 2026-09-09

### G-DEPLOY-02 — `/opt/laesh/www/` permissions bloquean rsync de sysadmin

**Causa raíz:** `/opt/laesh/www/` era `750 www-data:www-data`. Sysadmin no podía traversar
el directorio aunque `laesh-swbldi/` (dentro) fuera `775 sysadmin:sysadmin`.

**Fix (permanente):**
```bash
sudo chmod 755 /opt/laesh/www/
```

### G-DEPLOY-03 — sudo PHP-FPM reload falla en SSH no-interactivo

**Causa raíz:** `deploy.sh webapp` ejecuta `ssh laesh-kvm2 "sudo systemctl reload php8.3-fpm"`.
Sin TTY disponible, sudo requiere contraseña y falla con "a terminal is required".

**Fix (permanente — aplicar en terminal interactiva KVM2):** ver § Sudoers para el bloque completo actualizado (incluye lectura de logs).

### G-CMS-01 — `cms_cleanup.php` borraba imágenes con URLs legacy `/img/cms/`

**Causa raíz:** `cms_cleanup.php` solo reconocía el prefijo canónico `/laesh-web-assets-uipv1a/cms/`.
URLs con el prefijo legacy `/laesh-web-assets-uipv1a/img/cms/` (uploader antiguo) no eran
detectadas como "en uso" → el script las marcaba como huérfanas y las borraba.

**Fix (`crons/cms_cleanup.php`):**
```php
const CMS_URL_PREFIX        = '/laesh-web-assets-uipv1a/cms/';
const CMS_URL_PREFIX_LEGACY = '/laesh-web-assets-uipv1a/img/cms/';
$prefixes = [CMS_URL_PREFIX, CMS_URL_PREFIX_LEGACY];
// queries a web_contenidos, configuraciones, catalogo_promociones usan ambos prefijos
```

### G-CMS-02 — URLs legacy `/img/cms/` en BD + HTML en `dia_semana` (migration m003)

**Causa raíz (A/B):** El uploader antiguo guardaba rutas `/laesh-web-assets-uipv1a/img/cms/`
en `web_contenidos` y `configuraciones`. Causa raíz (C): CKEditor guardaba HTML en `dia_semana`
de `catalogo_promociones`.

**Fix (`setup/bds/laesh/migrations/m003_cms_url_and_diasemana_fix.sql`):**
```sql
-- A: normalizar web_contenidos
UPDATE `web_contenidos`
SET `valor` = REPLACE(`valor`, '/laesh-web-assets-uipv1a/img/cms/', '/laesh-web-assets-uipv1a/cms/')
WHERE `valor` LIKE '/laesh-web-assets-uipv1a/img/cms/%';
-- B: misma corrección en configuraciones
-- C: limpiar HTML de dia_semana
UPDATE `catalogo_promociones`
SET `dia_semana` = TRIM(REGEXP_REPLACE(`dia_semana`, '<[^>]+>', ''))
WHERE `dia_semana` REGEXP '<[^>]+>';
```

**Aplicar en KVM2:**
```bash
sudo mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db \
  < ~/staging/setup/bds/laesh/migrations/m003_cms_url_and_diasemana_fix.sql
```

### Reorganización de directorios en KVM2 (2026-09-09)

| Estado anterior | Estado final |
|----------------|-------------|
| `~/laesh-src/` | Movido a `~/staging/laesh-src/` (solo assets staging) |
| `~/laesh-setup/` (suelto) | Eliminado |
| `~/staging/laesh-setup/` (stale) | Eliminado |
| `~/staging/laesh-src/setup/` | Movido a `~/staging/setup/` (directorio físico, sin symlink) |
| `~/laesh-kvm2-prod/` | Eliminado (era duplicado de laesh-setup/) |
| `~/backups/` | Eliminado (dumps vacíos; backup real en `/opt/laesh/backups/db/`) |
| `/opt/laesh/laesh-web-assets-uipv1a/` | Eliminado (stray — imágenes rescatadas al path canónico) |
| `/opt/laesh/www/laesh-web-assets-uipv1a/` | Eliminado (stray) |

---

---

## Gaps y cambios — Estabilización BD 2026-09-13

### G-BD-01 — ERROR 1136: column count mismatch en `07_seed_catalogs.sql` línea 159

**Causa raíz:** La migration `m002` agregó la columna `descripcion_breve` a `catalogo_estudios`,
dejando la tabla con 11 columnas. El `INSERT IGNORE` sin lista de columnas explícita asumía 10
valores y fallaba con `ERROR 1136 (21S01): Column count doesn't match value count at row 1`.

**Fix (`setup/bds/laesh/07_seed_catalogs.sql`):**  
INSERT usa lista explícita de columnas omitiendo `descripcion_breve` (que se puebla
en los bloques UPDATE B1/B2 después del INSERT):

```sql
INSERT IGNORE INTO `catalogo_estudios`
  (id, categoria_id, clave_interna, nombre, tiempo_procesamiento, muestra_requerida,
   preparacion, detalle, precio, activo)
VALUES (1,1,'HEM-01', ...);
```

Además, ID 122 tenía `clave_interna='GEN-7428'` incorrecto — corregido a `'LIQ-07'`
para coincidir con la categoría Líquidos Corporales.

### G-BD-02 — `seed_first_users.php` en directorio incorrecto (`docs-dev/` → `commons/`)

**Causa raíz:** El script usaba `require __DIR__ . '/autoload.php'` pero residía en
`docs-dev/seed_first_users.php` donde no existe `autoload.php`. Sólo `commons/` lo tiene.

**Fix:** Script movido a `www/laesh-swbldi/commons/seed_first_users.php`.  
`setup_hostinger.sh` apunta correctamente a `commons/seed_first_users.php` desde 2026-09-13.

### G-BD-03 — `LAESH_DB_PASS` vs `H_APP_PASS` (variable name mismatch)

**Causa raíz:** `config.php` lee `getenv('LAESH_DB_PASS')` pero `setup_hostinger.sh`
exportaba `H_APP_PASS`. El seed PHP fallaba con `Access denied for user 'laesh_app'@'127.0.0.1'`.

**Fix:** `setup_hostinger.sh` ahora pasa explícitamente `LAESH_DB_PASS="${H_APP_PASS}"` al invocar
el script PHP. Alternativa documentada: el valor default `laesh_2026_dev` en `config.php`
actúa como fallback cuando la env var no está definida.

### G-BD-04 — `setup_hostinger.sh` apuntaba a `docs-dev/seed_first_users.php` (exit 255)

**Causa raíz:** El Paso 4 de `setup_hostinger.sh` tenía:
```bash
PHP_SCRIPT="${H_WEB_DIR}/laesh-swbldi/docs-dev/seed_first_users.php"
```
El script existe en `docs-dev/` pero intenta `require __DIR__ . '/autoload.php'` que solo
existe en `commons/` → PHP Fatal error → exit code 255. Los usuarios NO se sembraban.

**Fix (`setup_hostinger.sh` línea 181):**
```bash
PHP_SCRIPT="${H_WEB_DIR}/laesh-swbldi/commons/seed_first_users.php"
```

### G-BD-05 — `setup_hostinger.sh` H_ROOT_PASS vacía (PCRE2 variable-width lookbehind + set -e)

**Causa raíz:** El grep para leer la contraseña root usaba:
```bash
grep -Po '(?<=^password\s*=\s*).*' .mariadb-root.cnf
```
El lookbehind `\s*` es variable-width, no soportado en PCRE2 estricto. `grep` retornaba
exit code 2 (error). Con `set -euo pipefail`, la asignación `H_ROOT_PASS=$(...)` salía
con código 2 y bash terminaba el script silenciosamente (antes del primer `echo`).

**Fix (`setup_hostinger.sh` línea 50):** Cambiado a `sed` con POSIX character classes:
```bash
H_ROOT_PASS="$(sed -n 's/^[[:space:]]*password[[:space:]]*=[[:space:]]*//p' \
    "${MARIADB_ROOT_CNF}" 2>/dev/null | head -1 | tr -d $'\r')" || true
```
El `|| true` previene que `set -e` mate el script si sed no encuentra match.

### G-INFRA-01 — `kvm2_setup.sh` fase 5 fallaba con `systemctl reload` cuando PHP-FPM estaba parado

**Causa raíz:** Después de `--nuke` (que elimina el pool PHP-FPM), `php8.3-fpm` no está
activo. `systemctl reload` falla con "is not active, cannot reload" → `set -e` → script termina
antes de fases 6 y 7 (crons, hardening, servicios).

**Fix (`kvm2_setup.sh` fase 5):** Detectar estado antes de recargar:
```bash
if systemctl is-active --quiet "${PHP_FPM_SERVICE}"; then
    systemctl reload "${PHP_FPM_SERVICE}"
else
    systemctl start "${PHP_FPM_SERVICE}"
fi
```

### G-BD-06 — `rbac_permisos_usuarios` faltaba en el schema (seed PHP retornaba exit 255)

**Causa raíz:** `04_auth_extensions.sql` creaba `rbac_permisos` (catálogo de permisos)
pero no la tabla de asignación `rbac_permisos_usuarios` (user↔permiso). El seed PHP
fallaba en todos los `INSERT INTO rbac_permisos_usuarios` → exit code 255.
Los usuarios sí se creaban (Delight-Auth + empleados + perfiles_medicos) pero sin permisos RBAC.

**Fix (`setup/bds/laesh/04_auth_extensions.sql` — después de `rbac_permisos`):**
```sql
CREATE TABLE IF NOT EXISTS `rbac_permisos_usuarios` (
    `user_id`      INT UNSIGNED NOT NULL,
    `permiso_id`   INT UNSIGNED NOT NULL,
    `otorgado_en`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `permiso_id`),
    CONSTRAINT `fk_rpu_user`    FOREIGN KEY (`user_id`)    REFERENCES `users`(`id`)         ON DELETE CASCADE,
    CONSTRAINT `fk_rpu_permiso` FOREIGN KEY (`permiso_id`) REFERENCES `rbac_permisos`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Aplicar en BD existente (sin DROP):**
```bash
echo 'laesh-26' | sudo -S mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db \
  < ~/staging/setup/bds/laesh/04_auth_extensions.sql
```
Luego re-ejecutar `seed_first_users.php` para asignar permisos a los 7 usuarios existentes.

### G-DEPLOY-01 — `deploy.sh` fallaba con "Operation not permitted" en dirs root/www-data (2026-09-13)

**Causa raíz:** `rsync -avz` incluye `--group --owner --perms --times`. Al deployar como
`sysadmin` a directorios cuyo dueño es `root` o `www-data`, rsync intenta `chgrp`/`chown`/
`chmod`/`utimes` en el directorio raíz de destino y falla con code 23.
Además `--delete` + `uploads/resultados` (750 www-data) causaba "Permission denied" al
intentar traversar ese directorio.

**Fix (`deploy.sh` RSYNC_OPTS):** Agregar `--no-group --no-owner --no-perms --omit-dir-times`
y `--exclude='uploads/'` en `deploy_webapp()`. Los permisos y ownership los gestiona
`kvm2_setup.sh`, no rsync. El contenido de archivos se transfiere sin tocar metadatos.

**Fix complementario (`kvm2_setup.sh` DIR_SPEC):** Cambiar `WEBAPP_DIR` y `ASSETS_DIR`
de `www-data:www-data:0755` a `sysadmin:sysadmin:0755`. PHP-FPM (www-data) puede leer
vía bits `other` (rwxr-xr-x). Sysadmin puede rsync sin sudo post-nuke.

**Workaround pre-nuke (solo primera vez):** Si el dir ya existe como www-data, hacer chown
manual antes del primer deploy (ver §Paso 1b en "Acción inmediata").

### G-README-01 — Query de verificación de usuarios usaba columna `curp` inexistente (2026-09-13)

**Causa raíz:** El README documentaba `SELECT id, curp, rol FROM users` pero Delight-Auth
no tiene columna `curp`; el identificador se guarda en `username`.

**Fix:** Query corregido a `SELECT u.id, u.username, e.rol FROM users u JOIN empleados e ON e.user_id=u.id ORDER BY u.id`.

### G-CONFIG-01 — `kvm2_setup.sh` fase 3 sobreescribía `swaks.conf` con template vacío

**Causa raíz:** La fase 3 copiaba TODOS los configs de staging a `/opt/laesh/configs/`,
incluyendo `swaks.conf` con placeholder `__SMTP_PASS__`, borrando el `swaks.conf` real
que `07_security_harden.sh` había configurado en Sep 4 con `hdkgcwhfadxzeyid`.

**Fix (`kvm2_setup.sh` línea ~148):** Si `swaks.conf` ya existe en producción SIN el
placeholder `__SMTP_PASS__`, se preserva; si aún tiene el placeholder, se copia el template
y la fase 6 lo rellena con `LAESH_SMTP_PASS` desde `.env`.

### G-SECRETS-01 — `LAESH_SMTP_PASS` vacía en `SECRETS.env` y en `/opt/laesh/configs/.env`

**Causa raíz:** Al crear `SECRETS.env` en esta sesión no se copió el valor que
ya existía en el README.md (líneas 173, 303, 313, 891): `hdkgcwhfadxzeyid`.

**Fix:** `SECRETS.env` corregido con el valor real. **Pendiente en KVM2:** actualizar
`/opt/laesh/configs/.env` manualmente (ver §Acción inmediata abajo).

---

## Setup desde cero (`--nuke`) — Guía canónica

> **Estado (2026-09-13 22:08):** setup completado exitosamente con `kvm2_setup.sh --nuke`.
> 144 estudios, 7 usuarios, HTTP 200, Swoole activo, crones instalados.
> Esta sección documenta los pasos para repetir el proceso (re-instalación o reset total).

### 1 — Preparar KVM2 antes del deploy (Remmina)

En terminal interactiva KVM2 — contraseña sysadmin inline, sin prompt:

```bash
# 1a — Actualizar .env con credenciales
echo 'laesh-26' | sudo -S bash -c 'cat > /opt/laesh/configs/.env << "EOF"
LAESH_APP_PASS=laesh_2026_dev
LAESH_SMTP_PASS=hdkgcwhfadxzeyid
EOF
chmod 600 /opt/laesh/configs/.env && chown root:root /opt/laesh/configs/.env'

# Verificar:
echo 'laesh-26' | sudo -S cat /opt/laesh/configs/.env

# 1b — Ceder ownership de dirs de destino a sysadmin para que rsync funcione sin errores.
#      deploy.sh usa rsync como sysadmin; los dirs están en www-data:www-data por defecto.
#      kvm2_setup.sh --nuke los reasigna a sysadmin:sysadmin permanentemente (fix 2026-09-13).
#      Este paso solo es necesario en la primera ejecución post-instalación o si se corrió
#      kvm2_setup.sh antes de aplicar el fix de DIR_SPEC.
echo 'laesh-26' | sudo -S chown sysadmin:sysadmin /opt/laesh/www/laesh-swbldi/
echo 'laesh-26' | sudo -S chown sysadmin:sysadmin /opt/laesh/assets/laesh-web-assets-uipv1a/
echo 'laesh-26' | sudo -S chown sysadmin:sysadmin /opt/laesh/assets/laesh-web-assets-uipv1a/fonts
```

### 2 — Sincronizar scripts y código (desde local)

```bash
# Desde raíz del repo restaurantb/:
bash setup/deploy/laesh-kvm2-prod/deploy.sh all
bash setup/deploy/laesh-kvm2-prod/deploy.sh assets-publish
```

### 3 — Ejecutar kvm2_setup.sh --nuke (en KVM2)

```bash
# Dar permisos y ejecutar — borra configs/scripts/crones/BD y reconstruye TODO desde staging:
chmod +x ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh
echo 'laesh-26' | sudo -S bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --nuke
```

**Resultado esperado:**
```
  ✓ MariaDB root — conectividad verificada
  ✓ Árbol /opt/laesh/ verificado/creado (16 directorios)
  ✓ Configs copiados / swaks.conf preservado
  ✓ BD configurada       ← 07_seed_catalogs.sql ahora pasa (G-BD-01 fix)
  ✓ PHP-FPM pool configurado
  ✓ Hardening completado
  ✓ HTTP 200 — sitio responde correctamente

  Resumen de BD:
  | Estudios              | 144 |
  | Con descripcion_breve |  80 |   (aprox, los que tienen UPDATE B1/B2)
  | Usuarios              |   7 |
  | ID-122 clave_interna  | LIQ-07 |
```

### 4 — Verificar usuarios demo

```bash
echo 'laesh-26' | sudo -S mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db \
  -e "SELECT u.id, u.username, e.rol FROM users u JOIN empleados e ON e.user_id=u.id ORDER BY u.id;"
```

Credenciales de acceso al portal:
| Usuario | CURP (login) | Contraseña | Rol |
|---------|-------------|-----------|-----|
| ADMIN | 9990000001 | 04041980 | ADMIN |
| RECEPCIÓN | 9990000002 | 04041981 | RECEPCION |
| MÉDICO 1 | 9990000003 | 04041982 | MEDICO |
| MÉDICO 2 | 9990000004 | 04041983 | MEDICO |
| MÉDICO 3 | 9990000005 | 04041984 | MEDICO |
| MÉDICO 4 | 9990000006 | 04041985 | MEDICO |
| MÉDICO 5 | 9990000007 | 04041986 | MEDICO |

---

## Scripts de orquestación (2026-09-13)

Además del pipeline clásico (`00_run_all.sh`), existen dos nuevos scripts de orquestación
para re-deploy desde cero sin pasar por la instalación completa del stack:

### `full_install.sh` (orquestador LOCAL)

```bash
# Prerequisito: SECRETS.env con credenciales reales (ya corregido en repo)
# Desde raíz del repo restaurantb/:
bash setup/deploy/laesh-kvm2-prod/full_install.sh --drop    # primera instalación / reset BD
bash setup/deploy/laesh-kvm2-prod/full_install.sh --skip-bd # solo código/assets
```

Hace: sincroniza SECRETS → escribe `/opt/laesh/configs/.env` en KVM2 → `deploy.sh all` →
`deploy.sh assets-publish` → SSH a KVM2 → `kvm2_setup.sh`.

> **Prerequisito:** el stack (Nginx, PHP-FPM, MariaDB, Swoole) ya debe estar instalado
> en KVM2. Si el servidor está limpio, correr el pipeline `01–05` primero.

### `kvm2_setup.sh` (script en KVM2)

```bash
# En terminal interactiva KVM2:
sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --nuke     # reset TOTAL
sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --drop     # solo reset BD
sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --skip-bd  # solo código/config
sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh            # idempotente
```

8 fases (con `--nuke`): **limpieza total** → credenciales → dirs → configs → BD → PHP-FPM pool → crons/hardening → servicios + smoke test.

| Flag | BD | Configs/scripts/crones | Cuándo usar |
|------|----|------------------------|-------------|
| `--nuke` | DROP + recrear | **Borra todo** y copia desde staging | Primera instalación limpia o reset total |
| `--drop` | DROP + recrear | Preserva configs existentes | Reset solo de BD |
| `--skip-bd` | Intacta | Preserva configs existentes | Solo código/PHP-FPM/crons |
| _(sin flag)_ | `INSERT IGNORE` | Preserva configs existentes | Re-deploy normal |

> **`--nuke` preserva SOLO** `.mariadb-root.cnf` y `.env` — son necesarios para conectar a MariaDB
> y leer las credenciales. Todo lo demás (swaks.conf, scripts, pool PHP-FPM, cron jobs) se borra
> y se reconstruye desde staging. La Fase 6 (`07_security_harden.sh`) inyecta `LAESH_SMTP_PASS`
> en el `swaks.conf` recién copiado.

**Diferencias con `06_deploy_app.sh` + `07_security_harden.sh`:**
- Lee passwords DESDE `/opt/laesh/configs/.env` (no requiere env vars exportadas)
- `--nuke` es el equivalente a "Paso 0 limpieza" + `--drop` en un solo comando
- Verifica `swaks.conf` existente en modo idempotente (G-CONFIG-01 fix)
- Incluye resumen de BD al final (conteo estudios, users, verificación ID 122)

---

## Relacionado

- `deploy.sh` — script canónico de deploy local → KVM2; soporta `webapp`, `assets`, `assets-publish`, `bd`, `scripts`, `all`
- `SERVER_MAP.env` — rutas canónicas de toda la infraestructura (este directorio)
- `SECRETS.env` — credenciales locales (gitignored, 600); plantilla en `SECRETS.env.example` (variables: `LAESH_APP_PASS`, `LAESH_ROOT_PASS`, `LAESH_SMTP_PASS`)
- `full_install.sh` — orquestador local completo (deploy + kvm2_setup.sh)
- `kvm2_setup.sh` — setup en KVM2 (dirs + BD + PHP-FPM + crons + servicios); flags: `--nuke`, `--drop`, `--skip-bd`
- `setup_hostinger.sh` — orquestador de BD (10 SQL + migraciones + seed); invocado por `kvm2_setup.sh` y `deploy.sh bd`
- [`setup/bds/laesh/README.md`](../../bds/laesh/README.md) — dos flujos BD (setup desde cero vs deploy incremental), estructura y credenciales
- [`setup/bds/laesh/migrations/README.md`](../../bds/laesh/migrations/README.md) — guía de migraciones incrementales
- Especificación técnica: `portafolio-dev-2026/blocklabgd/v1.2/et/Especificacion_Tecnica.html`
- Seguridad: `portafolio-dev-2026/blocklabgd/v1.2/et/Tecnica_Seguridad_Integral.html`
- Infraestructura: `portafolio-dev-2026/blocklabgd/v1.2/et/Tecnica_Infraestructura_Despliegue.html`
