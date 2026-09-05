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
├── www/
│   └── laesh-swbldi/         # código fuente PHP (portales md/rc/adrc/login/website)
├── assets/
│   └── laesh-web-assets-uipv1a/  # CSS, JS, imágenes estáticos
├── laesh-db/                 # datadir MariaDB (symlink ← /var/lib/mysql)
├── logs/                     # nginx, php-fpm, swoole, mariadb, backup, cert
├── https/                    # self-signed.crt/key (Modo A) · live/ symlink LE (Modo B)
├── backups/
│   └── db/                   # dumps .sql.gz rotados (7 días / 4 semanas)
├── uploads/
│   └── pdfs/                 # PDFs subidos (acceso interno via Nginx)
├── configs/                  # copia de los configs de este pipeline (source of truth)
├── scripts/                  # operacionales (start/stop/status/backup/restore)
└── crones/                   # systemd units, logrotate, cert check
```

---

## Pre-requisitos antes de ejecutar el pipeline

### 1 — Variables de entorno obligatorias

Exportar en la sesión SSH antes de cualquier script:

```bash
# LAESH_ROOT_PASS — contraseña que TÚ defines para el usuario root de MariaDB.
#   Ubuntu 24.04 instala MariaDB con unix_socket (sin contraseña).
#   04_configure_stack.sh la establece automáticamente y guarda en .mariadb-root.cnf.
export LAESH_ROOT_PASS='<contraseña-que-defines-para-root-mariadb>'

# LAESH_APP_PASS — contraseña que TÚ defines para el usuario laesh_app (usuario de la app PHP).
#   00_database.sql crea laesh_app con contraseña dev temporal.
#   setup_hostinger.sh paso 3 la sobreescribe con este valor.
#   04_configure_stack.sh la inyecta en php-fpm-laesh.conf.
#   El paso 06_deploy_app.sh falla con error explícito si no está definida.
export LAESH_APP_PASS='<contraseña-que-defines-para-laesh_app>'

# LAESH_SMTP_PASS — app-password Yahoo para alertas SMTP (monitor_services.sh).
#   07_security_harden.sh sustituye __SMTP_PASS__ en swaks.conf con este valor.
export LAESH_SMTP_PASS='<app-password-yahoo>'

# ── Modo B (dominio + Let's Encrypt) — solo cuando DNS laesh.mx apunte al server ──
# ⚠️ Omitir si DNS aún no está configurado — el paso 5 fallará al validar el dominio.
# Sin LAESH_DOMAIN → Modo A (self-signed, pura IP). Activar Modo B después:
#   export LAESH_DOMAIN='laesh.mx' && sudo -E bash 05_tls_certbot.sh
# export LAESH_DOMAIN='laesh.mx'
# export LAESH_ADMIN_EMAIL='cbena999@gmail.com'   # ya es el default en 00_run_all.sh
```

Sin `LAESH_DOMAIN` → el pipeline corre en **Modo A** (self-signed, pura IP).

### 2 — Transferir el código al servidor (rsync desde local)

Ejecutar desde tu máquina local **antes de correr el pipeline** en el servidor:

```bash
SERVER="sysadmin@83.136.219.193"

# 2a. Pipeline de instalación (este directorio):
rsync -avz --delete \
    /home/carlos/GitHub/caelitandem_home/restaurantb/setup/deploy/laesh-kvm2-prod/ \
    ${SERVER}:~/laesh-setup/ \
    --exclude='.git'

# 2b. Código fuente de la aplicación:
rsync -avz --delete --mkpath \
    /home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-swbldi/ \
    ${SERVER}:/home/sysadmin/laesh-src/laesh-swbldi/ \
    --exclude='.git' --exclude='vendor/'

# 2c. Assets estáticos (CSS, JS, imágenes):
rsync -avz --delete --mkpath \
    /home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-web-assets-uipv1a/ \
    ${SERVER}:/home/sysadmin/laesh-src/laesh-web-assets-uipv1a/ \
    --exclude='.git'

# 2d. Scripts de BD (SQL + orquestador setup_hostinger.sh):
rsync -avz --delete --mkpath \
    /home/carlos/GitHub/caelitandem_home/restaurantb/setup/bds/laesh/ \
    ${SERVER}:/home/sysadmin/laesh-src/setup/bds/laesh/ \
    --exclude='.git'
```

> **¿Por qué 4 rsync?** El pipeline (`06_deploy_app.sh`) busca código de app en
> `/home/sysadmin/laesh-src/laesh-swbldi/` y los scripts BD en
> `/home/sysadmin/laesh-src/setup/bds/laesh/`. La separación permite re-sincronizar
> solo lo que cambió sin re-transferir el pipeline completo.

### 3 — Dar permisos de ejecución al pipeline

Una vez que el rsync completa, **en el servidor**:

```bash
chmod +x ~/laesh-setup/*.sh ~/laesh-setup/scripts/*.sh ~/laesh-setup/https/*.sh
```

### 4 — Verificar pre-requisitos en el servidor antes de ejecutar

```bash
# Confirmar que las variables están definidas:
echo "ROOT: ${LAESH_ROOT_PASS:+[OK — definida]}" 
echo "APP:  ${LAESH_APP_PASS:+[OK — definida]}"
echo "SMTP: ${LAESH_SMTP_PASS:+[OK — definida]}"

# Confirmar que el código llegó:
ls /home/sysadmin/laesh-src/laesh-swbldi/
ls /home/sysadmin/laesh-src/setup/bds/laesh/setup_hostinger.sh
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
cd ~/laesh-setup
export LAESH_ROOT_PASS='...'
export LAESH_APP_PASS='...'
export LAESH_SMTP_PASS='...'        # app-password Yahoo para alertas SMTP (paso 7)
sudo -E bash 00_run_all.sh
```

### Opción B — Paso a paso (recomendado en primera instalación)

```bash
# Asegurar que las variables están definidas (ver §Pre-requisitos):
export LAESH_ROOT_PASS='...'
export LAESH_APP_PASS='...'
export LAESH_SMTP_PASS='...'        # app-password Yahoo para alertas SMTP

cd ~/laesh-setup

sudo bash 01_preflight.sh
sudo bash 02_install_stack.sh
sudo bash 03_install_swoole.sh
sudo -E bash 04_configure_stack.sh  # inyecta LAESH_APP_PASS en php-fpm-laesh.conf
sudo bash 05_tls_certbot.sh         # Modo A (self-signed) por defecto
sudo -E bash 06_deploy_app.sh       # rsync + BD + Composer; usa LAESH_ROOT_PASS/APP_PASS
sudo -E bash 07_security_harden.sh  # UFW, SMTP conf, log-levels, OPcache, cron backup
sudo bash 08_verify.sh              # 15 checks internos + 27 checks HTTP
```

### Reanudar desde un paso fallido

```bash
sudo -E bash 00_run_all.sh --from=4  # retoma desde 04_configure_stack.sh
sudo -E bash 00_run_all.sh --only=6  # ejecuta solo 06_deploy_app.sh
sudo -E bash 00_run_all.sh --skip=3  # ejecuta todos excepto 03_install_swoole.sh
```

---

## Scripts del pipeline

| Script | Qué hace |
|--------|----------|
| `00_run_all.sh` | Orquestador — ejecuta 01→08 en orden; acepta `--from/--only/--skip` |
| `01_preflight.sh` | Swap 4 GB, sysctl, ulimits, árbol de directorios `/opt/laesh/`, copia configs (`.cnf` `.ini` `.conf` `.path` `.service`) / crones / https / scripts |
| `02_install_stack.sh` | Instala Nginx, MariaDB 11.8, PHP 8.3 + extensiones, Composer; mueve datadir con symlink AppArmor; usa `php8.3 -n` para evitar hang en re-runs post paso 7 |
| `03_install_swoole.sh` | Instala Swoole 6.2.x via PECL; verifica versión via `strings` (no `php -r`) para ser seguro en re-runs con JIT+CLI activo |
| `04_configure_stack.sh` | Copia configs al sistema, reemplaza `__LAESH_APP_PASS__`, establece contraseña root MariaDB, crea `.mariadb-root.cnf`, habilita systemd units, valida nginx/fpm |
| `05_tls_certbot.sh` | **Dual-mode idempotente**: Modo A (self-signed) o Modo B (Let's Encrypt) según `LAESH_DOMAIN` |
| `06_deploy_app.sh` | rsync código fuente, Composer install, inicializa BD (10 SQL scripts + seed), actualiza rutas KVM2 en BD, arranca Swoole |
| `07_security_harden.sh` | UFW, OPcache FPM (JIT tracing) + CLI (sin JIT — P-INFRA-02), cron backup, cron expiry cert, monitor SMTP, log-levels systemd path unit, SSH hardening opcional |
| `08_verify.sh` | 28 checks internos (Sistema/Stack/Servicios/BD/Logs/Infra) + suite `bash/03_test_deploy.sh`. PHP CLI via `php8.3 -n`; Swoole via `strings` (sin invocar PHP) |

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
| `swoole-laesh.service` | systemd unit | Swoole WebSocket + HTTP IPC — `User=www-data`, `Restart=always` |
| `logrotate-laesh.conf` | logrotate | nginx, php-fpm, swoole, mariadb — daily, 30 días, compress |
| `check_cert_expiry.sh` | cron semanal (root) | Alerta si TLS vence en < 14 días; intenta auto-renew |
| `cache_renew.cron` | cron diario 5 AM (www-data) | Warm-up Cache L2 OPcache File Store — purge + re-fetch 4 datasets (~13 ms) |

---

## Scripts operacionales (`scripts/`)

> **Despliegue al servidor:** estos scripts llegan a `/opt/laesh/scripts/` vía
> `sync_to_hkvm2.sh` (rsync completo de `scripts/`), **no** por el pipeline
> `07_security_harden.sh` (que solo instala los 6 scripts de monitoreo/backup).
> Ejecutar `sync_to_hkvm2.sh` antes de usarlos si se modificaron localmente.

### Arranque / parada del stack

```bash
# Prerrequisito: stack completamente instalado (00_run_all.sh ya ejecutado)
sudo bash scripts/laesh-start.sh      # arranca en orden: mariadb → php-fpm → swoole → nginx
sudo bash scripts/laesh-stop.sh       # detiene en orden inverso: nginx → swoole → php-fpm → mariadb
sudo bash scripts/laesh-status.sh     # semáforo ✓/△/✗ + últimas líneas de logs
sudo bash scripts/swoole-restart.sh   # reinicia solo Swoole (tras deploy de código WS)
```

### Backup y restore

```bash
sudo bash scripts/backup_db.sh                 # dump laesh_db → /opt/laesh/backups/db/
sudo bash scripts/backup_db.sh --weekly        # retención semanal (35 días)

# Prerrequisito restore: /opt/laesh/configs/.mariadb-root.cnf debe existir (creado en paso 04)
sudo bash scripts/restore_db.sh /opt/laesh/backups/db/laesh_db_YYYYMMDD_HHMMSS.sql.gz
```

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

### Bypass CMS Preview

`?_preview=1` + sesión activa ADMIN + borrador en `$_SESSION['cms_draft']` → bypass total del cache. El motor sirve desde MariaDB + sesión, no desde RAM.

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

### SMTP — configuración

`07_security_harden.sh` despliega `/opt/laesh/configs/swaks.conf` (600 root:root) sustituyendo
`__SMTP_PASS__` con `LAESH_SMTP_PASS`. Protocolo: Yahoo SMTP port 587 STARTTLS auth LOGIN.

```bash
# Verificar que la sustitución fue correcta (no debe aparecer nada):
sudo grep '__SMTP_PASS__' /opt/laesh/configs/swaks.conf

# Probar SMTP manualmente:
sudo bash scripts/test_smtp.sh
# Con destinatario alternativo:
sudo bash scripts/test_smtp.sh --to otro@email.com

# Ver log de monitor:
tail -50 /opt/laesh/logs/monitor-services.log
```

### Estado de alertas

```bash
# Ver cooldowns activos (qué servicios ya alertaron recientemente):
ls -la /opt/laesh/monitor/
stat /opt/laesh/monitor/nginx.last_alert 2>/dev/null

# Forzar re-alerta (borrar cooldown de nginx):
sudo rm /opt/laesh/monitor/nginx.last_alert
```

---

## Log-Levels en Caliente (Hot Reload)

Permite cambiar niveles de log de Nginx, MariaDB, PHP y la app PHP sin reiniciar servicios.

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

### Interfaz de administración

El tab **"🔧 Infra: Log-Levels en Caliente"** en `admrc/views/sistema.php` permite editar
estos valores desde el panel de administración con validación server-side de enums.

```bash
# Ver log de aplicaciones de nivel:
tail -25 /opt/laesh/logs/apply-log-levels.log

# Aplicar cambio manualmente (sin editar el archivo):
sudo bash /opt/laesh/scripts/apply_log_levels.sh
```

---

## Logger.php — Filtro de Nivel Mínimo

`commons/Logger.php` implementa filtrado de severidad por request. El nivel se lee de
`/opt/laesh/configs/app-log-level.php` (archivo PHP escrito por `apply_log_levels.sh`).

### Configuración recomendada por entorno

| Entorno | `app_log_level` | Resultado |
|---------|-----------------|-----------|
| **Producción** | `WARN` (default) | Solo WARN, ERROR, CRITICAL, FATAL → mínimo ruido en `sys_logs` y `app.log` |
| **Debug temporal** | `INFO` o `DEBUG` | Activar via tab Infra; revertir a WARN cuando resuelto |
| **Silenciar todo** | `OFF` | Ningún log pasa — usar solo en emergencia para reducir I/O |

### Orden de severidad

```
DEBUG(0) → INFO(1) → WARN(2) → ERROR(3) → CRITICAL(4) → FATAL(5) → OFF(∞)
```

Un log de nivel `N` pasa solo si `N ≥ nivel_mínimo_configurado`.

### Cache por request

El nivel se cachea en `Logger::$minLevel` (propiedad estática) el primer `log()` del request.
Si el nivel cambia en el archivo durante un request ya iniciado, el nuevo nivel aplica desde
el siguiente request (sin overhead de I/O por línea de log).

```bash
# Ver nivel activo:
sudo cat /opt/laesh/configs/app-log-level.php

# Cambiar a INFO via CLI (alternativa a la UI):
echo "nginx_error_level=warn
mariadb_slow_query_log=OFF
mariadb_slow_query_time=2
mariadb_log_error_verbosity=2
mariadb_general_log=OFF
php_error_reporting=production
app_log_level=INFO" | sudo tee /opt/laesh/logs/log-levels.conf
# El path unit detecta el cambio y aplica en segundos.
```

---

## Seguridad — Directivas adicionales en Nginx (§Seguridad_Integral)

### Verbos HTTP restringidos

Solo `GET`, `POST`, `HEAD` permitidos. `TRACE`, `OPTIONS`, `DELETE`, `PUT` devuelven `405`:
```nginx
if ($request_method !~ ^(GET|POST|HEAD)$) { return 405; }
```
Presente en ambos `nginx-laesh-ip.conf` y `nginx-laesh-domain.conf`.

### Rate limiting login

Definido en `nginx-base.conf`, aplicado en `location /login/`:
```nginx
# base.conf:
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
# site conf (location /login/):
limit_req zone=login burst=3 nodelay;
```
Complementa el throttling automático de Delight Auth (`users_throttling` en BD).

### Bloqueo PHP en uploads

```nginx
location ~* /laesh-uploads/.*\.php$ { deny all; return 404; }
```
Previene que un PDF malicioso enmascarado se ejecute como script PHP.

### Least Privilege MariaDB

`laesh_app` tiene solo permisos DML: `SELECT, INSERT, UPDATE, DELETE ON laesh_db.*`.
`07_security_harden.sh` paso 5 verifica que no haya `DROP`, `ALTER`, `ALL PRIVILEGES`.

### SSH Hardening (§1.5)

`07_security_harden.sh` paso 6. Requiere llave pública en `authorized_keys` antes de deshabilitar contraseña:
```bash
# Pre-requisito (desde tu máquina local):
ssh-copy-id -p 22 sysadmin@83.136.219.193

# Luego en el servidor:
sudo bash 07_security_harden.sh  # SSH hardening ON por default
```
Aplica: `PermitRootLogin no`, `PasswordAuthentication no`, `MaxAuthTries 3`.

---

## Reinstalación desde cero (OS reset → servidor limpio)

Guía completa para replicar el stack en un servidor con Ubuntu 24.04 fresco
(Hostinger reinstalación del SO, o nuevo KVM2 con la misma IP/dominio).

> **Cuándo usar esta guía:** reinstalación del SO en Hostinger panel,
> migración a un servidor nuevo, o reset completo intencional de la instalación.
> Para rollback parcial de configuración o código, ver sección **Rollback** más abajo.

### Paso 0 — Limpieza del servidor anterior (si aplica)

Si el servidor tiene una instalación LAESH previa (no es OS fresco):

```bash
# 0a. Detener servicios
sudo systemctl stop swoole-laesh php8.3-fpm nginx mariadb 2>/dev/null || true
sudo systemctl disable swoole-laesh 2>/dev/null || true

# 0b. ⚠ BACKUP antes de limpiar — copiar backups y uploads a local:
scp -r sysadmin@83.136.219.193:/opt/laesh/backups/db/ ./backup-pre-reinstall/
scp -r sysadmin@83.136.219.193:/opt/laesh/uploads/   ./uploads-pre-reinstall/

# 0c. Limpiar árbol /opt/laesh/ completo
sudo rm -rf /opt/laesh/

# 0d. Limpiar crons y systemd
sudo rm -f /etc/cron.d/laesh-*
sudo rm -f /etc/systemd/system/swoole-laesh.service
sudo rm -f /etc/logrotate.d/laesh
sudo systemctl daemon-reload

# 0e. Limpiar nginx
sudo rm -f /etc/nginx/sites-available/laesh
sudo rm -f /etc/nginx/sites-enabled/laesh

# 0f. Limpiar cert LE (si se va a reutilizar el mismo dominio):
#   NO borrar — certbot reutiliza el cert existente mientras no haya caducado.
#   Solo borrar si cambias de dominio:
# sudo certbot delete --cert-name laesh.mx

# 0g. Limpiar fuente del pipeline en el home de sysadmin
rm -rf ~/laesh-setup/ ~/laesh-src/

# 0h. Verificar que quedó limpio
ls /opt/laesh/ 2>/dev/null && echo "WARN: /opt/laesh/ aún existe" || echo "OK: /opt/laesh/ limpio"
```

### Paso 1 — Transferir pipeline y fuente (desde local)

```bash
# Desde tu máquina local — ejecutar sync_to_hkvm2.sh
bash /home/carlos/GitHub/caelitandem_home/restaurantb/setup/deploy/sync_to_hkvm2.sh

# Verifica que llegó todo:
ssh sysadmin@83.136.219.193 "ls ~/laesh-setup/ && ls ~/laesh-src/laesh-swbldi/"
```

### Paso 2 — Definir variables de entorno en el servidor

```bash
# En la sesión SSH del servidor:
export LAESH_ROOT_PASS='<define-contraseña-root-mariadb>'
export LAESH_APP_PASS='<define-contraseña-laesh_app>'
export LAESH_SMTP_PASS='<app-password-yahoo-smtp>'
export LAESH_ADMIN_EMAIL='cbena999@gmail.com'

# Modo B (dominio con cert LE válido) — solo si DNS apunta al servidor:
export LAESH_DOMAIN='laesh.mx'
# Sin LAESH_DOMAIN → Modo A (self-signed). Activar Modo B después con:
#   LAESH_DOMAIN=laesh.mx sudo -E bash 05_tls_certbot.sh
```

### Paso 3 — Ejecutar pipeline completo

```bash
cd ~/laesh-setup/

# Primera instalación: NO requiere --drop (BD no existe → CREATE IF NOT EXISTS)
sudo -E bash 00_run_all.sh

# Si algo falla en el paso N, reanudar desde ese paso:
sudo -E bash 00_run_all.sh --from=N
```

### Paso 4 — Solo si se necesita reset de BD con datos previos

```bash
# ⚠ DESTRUCTIVO — borra toda la BD y la recrea desde el seed.
# Usar solo si el --drop es intencional (no es el caso de servidor limpio).
LAESH_ROOT_PASS='...' LAESH_APP_PASS='...' sudo -E bash 06_deploy_app.sh --drop
```

### Paso 5 — Verificación final

```bash
# Suite 27 checks (HTTP, assets, CSP, PHP, seguridad):
BASE=https://laesh.mx bash ~/laesh-src/setup/bds/laesh/bash/03_test_deploy.sh

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
| Paso 1 (sync local→servidor) | 3–5 min (depende de red) |
| Paso 2–3 (pipeline 01–04, 06–08) | 5–10 min |
| Paso 3 solo Swoole (compilación PECL) | 10–20 min |
| **Total** | **~25–40 min** |

---

## Rollback — Procedimientos ante fallo (§19.7)

### Rollback de configuración Nginx

```bash
# Nginx no arranca tras cambio de config:
sudo nginx -t                              # ver error exacto
sudo cp /etc/nginx/nginx.conf.bak nginx.conf  # si existe backup
sudo systemctl reload nginx
```

### Rollback de deploy de código (rsync)

```bash
# Restaurar a versión anterior (si se hizo backup previo)
sudo rsync -av /opt/laesh/backups/www-FECHA/ /opt/laesh/www/
sudo systemctl restart php8.3-fpm
```

### Rollback de BD

```bash
# Listar dumps disponibles
ls -lh /opt/laesh/backups/db/

# Restaurar dump específico
sudo bash /opt/laesh/scripts/restore_db.sh /opt/laesh/backups/db/laesh_db_YYYYMMDD_HHMMSS.sql.gz
# El script crea un backup previo automático antes de restaurar
```

### Rollback de versión PHP-FPM

```bash
# Ver config activa
php8.3 --ini | grep "Loaded Configuration"

# Revertir ini de laesh
sudo cp /etc/php/8.3/fpm/conf.d/99-laesh.ini.bak /etc/php/8.3/fpm/conf.d/99-laesh.ini
sudo systemctl reload php8.3-fpm
```

### Rollback de MariaDB config

```bash
# El archivo de backup se crea en 07_security_harden.sh (SSH) y manualmente recomendado antes de cambios
sudo cp /etc/mysql/mariadb.conf.d/99-laesh.cnf.bak /etc/mysql/mariadb.conf.d/99-laesh.cnf
sudo systemctl restart mariadb
```

---

## Gaps detectados y fixes aplicados (deploy 2026-09-04 / stabilización 2026-09-05)

Issues encontrados durante el despliegue en producción KVM2 (`83.136.219.193`) y sus correcciones.

### G-01 — HTTP 404 en `/laesh/`, `/laesh/adrc/`, `/laesh/login/login.php`

**Causa raíz:** `index index.php` en el location `alias` genera un internal redirect  
(e.g. `/laesh/` → `/laesh/index.php`) que cae en el regex genérico `~ ^/laesh/(.+\.php)$`  
con `$1=index.php` → `SCRIPT_FILENAME` incorrecto (`laesh-swbldi/index.php`, no existe).  
Para `adrc`, la URL usa `adrc` pero el dirname físico es `admrc`.

**Fix:** `nginx-laesh-ip.conf` y `nginx-laesh-domain.conf` — 3 location handlers específicos  
declarados **antes** del genérico:
- `location = /laesh/index.php` → `website/index.php` (exacto)
- `location ~ ^/laesh/login/(.+\.php)$` → `website/login/$1`
- `location ~ ^/laesh/adrc/(.+\.php)$` → `admrc/$1`

### G-02 — HTTP 404 en `/laesh-web-assets-uipv1a/css/portal.css` y `app.js`

**Causa raíz:** El regex global `location ~* \.(css|js)$` (sin `root`/`alias`) tiene  
prioridad sobre el prefix `location /laesh-web-assets-uipv1a/` → nginx usa  
`/usr/share/nginx/html` como root → 404. Se confirma con `nginx -T` (grep de `root /usr/share`).

**Fix:** `location ^~ /laesh-web-assets-uipv1a/` — el modificador `^~` detiene la  
evaluación de regex para ese prefijo, forzando el bloque `alias` correcto.  
Requirió `systemctl restart nginx` (no solo `reload`) para limpiar workers cacheados.

### G-03 — `01_preflight.sh` no copiaba `.path`/`.service` a `/opt/laesh/configs/`

**Causa raíz:** Solo se copiaban `*.cnf`, `*.ini`, `*.conf`. Los systemd path/service units  
(`laesh-log-levels.path`, `laesh-log-levels.service`) no llegaban al servidor.  
`07_security_harden.sh` buscaba los units en `/opt/laesh/configs/` → no los encontraba  
→ `systemctl enable laesh-log-levels.path` fallaba.

**Fix:** Agregadas 2 líneas en paso 5/5 de `01_preflight.sh`:
```bash
cp -v "${SETUP_DIR}"/configs/*.path    /opt/laesh/configs/ 2>/dev/null || true
cp -v "${SETUP_DIR}"/configs/*.service /opt/laesh/configs/ 2>/dev/null || true
```

### G-04 — `07_security_harden.sh` falso positivo en Least Privilege check

**Causa raíz:** `mariadb -u root` falla silencioso después de que paso 4 establece  
contraseña root → `GRANTS` queda vacío → `grep -Eqi 'ALL PRIVILEGES|DROP|...'`  
no encuentra nada → reporta "OK" aunque no se pudo verificar.

**Fix:** Preferir `.mariadb-root.cnf` (socket auth con contraseña) si existe;  
fallback `-u root` solo en fresh install pre-paso-4.

### G-05 — P-INFRA-02: PHP CLI hang con OPcache JIT + Swoole

**Causa raíz:** `07_security_harden.sh` copiaba el mismo `10-opcache-laesh.ini`  
(que contiene `opcache.jit=tracing` + `opcache.enable_cli=1`) a FPM **y CLI**.  
`php8.3` CLI con esos ajustes + `extension=swoole.so` → hang indefinido.  
Afectaba: `08_verify.sh`, `cache_renew.cron`, cualquier llamada `php8.3` directa.

**Fix:** Paso 7 genera **dos** ini distintos:
- **FPM**: `10-opcache-laesh.ini` completo (JIT tracing 64 MB — máx rendimiento)
- **CLI**: misma base pero `opcache.jit=0` + `opcache.jit_buffer_size=0M` (sin JIT)

`08_verify.sh` y `03_install_swoole.sh` usan `php8.3 -n` donde procede,  
y `strings` sobre el `.so` para versión de Swoole (sin invocación PHP).

### G-06 — `08_verify.sh` check Swoole devuelve versión errónea

**Causa raíz:** `grep -oE '6[.][0-9]+[.][0-9]+' | head -1` encontraba `6.0.0` de  
una librería embebida (OpenSSL/brotli) antes que la versión Swoole real.

**Fix:** `grep -oE '6[.][0-9]+[.][0-9]+' | sort -V | tail -1` + patrón esperado `6\.2\.`  
(cualquier patch de 6.2.x), label "Swoole 6.2.x".

### G-07 — `03_install_swoole.sh` y `02_install_stack.sh` usan `php8.3 -r` en re-runs

**Causa raíz:** Si se re-ejecutan DESPUÉS de paso 7 (JIT+CLI+Swoole activos),  
las llamadas `php8.3 -r "echo SWOOLE_VERSION"`, `php8.3 -r 'echo PHP_VERSION;'`  
y `composer --version` (que invoca php) cuelgan.

**Fix `03`:** Idempotency check y verificación final usan `strings` sobre el `.so`.  
Activa check usa `ls /etc/php/8.3/fpm/conf.d/20-swoole.ini`.  
**Fix `02`:** `php8.3 -n -r 'echo PHP_VERSION;'` y `php8.3 -n /usr/local/bin/composer --version`.

---

### G-08 — URL raíz: app servida en `/laesh/` en vez de `/` (2026-09-05)

**Causa raíz:** Los nginx configs tenían `location /laesh/X` como prefijo en todas las rutas.
La app PHP (Flight) tenía rutas registradas como `/laesh/X`. Resultado: el dominio `laesh.mx/`
daba 404; había que ir a `laesh.mx/laesh/`.

**Fix:** `nginx-laesh-ip.conf` y `nginx-laesh-domain.conf` — todos los location blocks cambiados
a raíz `/X`. Mecanismo de inyección para preservar PHP routing sin tocar código PHP:
- `set $laesh_uri /laesh$request_uri;` al inicio del server block
- `fastcgi_param REQUEST_URI $laesh_uri;` en todos los PHP handlers
- PHP recibe REQUEST_URI `/laesh/X` → sus rutas `/laesh/X` hacen match ✓
- Browser ve URL `/X` ✓
- Block `location ^~ /laesh/ { set $laesh_uri $request_uri; rewrite ... last; }` para compat
  con bookmarks viejos o PHP-generated links con prefijo (evita doble inyección)
- `cms_upload_endpoint` en BD actualizado de `/laesh/adrc/cms/upload` → `/adrc/cms/upload`

### G-CERTBOT-01 — certbot `--nginx` crea duplicados TLS en nginx config (2026-09-05)

**Causa raíz:** `certbot --nginx` modifica el site config en-place inyectando
`include /etc/letsencrypt/options-ssl-nginx.conf` (que tiene `ssl_protocols` + `ssl_ciphers`).
Nuestro config ya tenía esas directivas → `nginx: ssl_ciphers directive is duplicate`.

**Fix `05_tls_certbot.sh`:** Cambiado `certbot --nginx` → `certbot certonly --webroot -w /opt/laesh/www`.
Certonly solo emite el cert sin tocar el config nginx. Domain.conf actualizado con
placeholder `__LAESH_DOMAIN__` (reemplazado por sed en el script) para cert paths LE reales.
HTTP block tiene excepción ACME: `location ^~ /.well-known/acme-challenge/` antes del 301.

### G-BACKUP-01 — `backup_db.sh` producía dumps vacíos (20 bytes) sin alerta (2026-09-05)

**Causa raíz:** `mariadb-dump` se invocaba sin credenciales. Paso 4 establece contraseña root.
Resultado: 15 dumps de 20 bytes (gzip vacío) generados de 17:00 a 07:00 sin ninguna alerta.

**Fix `scripts/backup_db.sh`:**
- `--defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf` (creado en paso 4)
- Trap en `EXIT`: si `_BACKUP_OK=false`, llama `send_alert.sh` con error
- Validación post-dump: `stat -c%s $FILE` < 10 KB → alerta + `rm -f` del archivo vacío
- `_BACKUP_OK=true` solo se fija al final exitoso (guard contra false positives en exit 0)

**Fix `scripts/monitor_services.sh`:**
- Función `check_backup_fresh()` agregada: falla si último backup > 90 min o < 10 KB
- Alerta SMTP si backup_fresh falla (sujeto a cooldown 30 min anti-spam)

---

## Relacionado

- [README del directorio deploy](../README.md) — `sync_to_hkvm2.sh` y cómo transferir este pipeline
- `setup_hostinger.sh` — script de inicialización de BD (10 SQL + seed); invocado por `06_deploy_app.sh`
- Especificación técnica: `portafolio-dev-2026/blocklabgd/v1.2/et/Especificacion_Tecnica.html`
- Seguridad: `portafolio-dev-2026/blocklabgd/v1.2/et/Tecnica_Seguridad_Integral.html`
- Infraestructura: `portafolio-dev-2026/blocklabgd/v1.2/et/Tecnica_Infraestructura_Despliegue.html`
