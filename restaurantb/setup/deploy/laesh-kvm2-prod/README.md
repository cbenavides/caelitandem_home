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
| Dominio futuro | `laesh.mx` (DNS pendiente de configurar) |

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
# Obligatorias (BD):
export LAESH_ROOT_PASS='<contraseña-root-mariadb>'
export LAESH_APP_PASS='<contraseña-usuario-laesh_app>'

# Obligatoria (SMTP alertas — sustitución de __SMTP_PASS__ en 07_security_harden.sh):
export LAESH_SMTP_PASS='<app-password-yahoo>'

# Opcionales — Modo B (dominio con Let's Encrypt):
export LAESH_DOMAIN='laesh.mx'
export LAESH_CERT_EMAIL='admin@laesh.mx'
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
rsync -avz --delete \
    /home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-swbldi/ \
    ${SERVER}:/home/sysadmin/laesh-src/laesh-swbldi/ \
    --exclude='.git' --exclude='vendor/'

# 2c. Assets estáticos (CSS, JS, imágenes):
rsync -avz --delete \
    /home/carlos/GitHub/caelitandem_home/restaurantb/www/laesh-web-assets-uipv1a/ \
    ${SERVER}:/home/sysadmin/laesh-src/laesh-web-assets-uipv1a/ \
    --exclude='.git'

# 2d. Scripts de BD (SQL + orquestador setup_hostinger.sh):
rsync -avz --delete \
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
cd ~/laesh-kvm2-prod
export LAESH_ROOT_PASS='...'
export LAESH_APP_PASS='...'
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
| `01_preflight.sh` | Swap 4 GB, sysctl, ulimits, árbol de directorios `/opt/laesh/`, copia configs/crones/https/scripts |
| `02_install_stack.sh` | Instala Nginx, MariaDB 11.8, PHP 8.3 + extensiones, Composer; mueve datadir con symlink AppArmor |
| `03_install_swoole.sh` | Instala Swoole 6.2.2 via PECL; habilita extensión en PHP 8.3 FPM y CLI |
| `04_configure_stack.sh` | Copia configs al sistema, reemplaza `__LAESH_APP_PASS__`, habilita systemd units, valida nginx/fpm |
| `05_tls_certbot.sh` | **Dual-mode idempotente**: Modo A (self-signed) o Modo B (Let's Encrypt) según `LAESH_DOMAIN` |
| `06_deploy_app.sh` | rsync código fuente, Composer install, inicializa BD (10 SQL scripts + seed), arranca Swoole |
| `07_security_harden.sh` | UFW, OPcache, cron backup, cron expiry cert, hardening SSH opcional |
| `08_verify.sh` | 15 checks internos (swap, servicios, BD, Swoole, FPM) + suite bash/03_test_deploy.sh |

---

## Archivos de configuración (`configs/`)

| Archivo | Destino en servidor | Descripción |
|---------|--------------------|----|
| `mariadb-99-laesh.cnf` | `/etc/mysql/mariadb.conf.d/99-laesh.cnf` | bind 127.0.0.1, **2 GB pool**, NVMe IO capacity, tmp_table 64M |
| `php-99-laesh.ini` | `/etc/php/8.3/fpm/conf.d/99-laesh.ini` | hardened, timezone `America/Mexico_City`, session secure |
| `php-fpm-laesh.conf` | `/etc/php/8.3/fpm/pool.d/laesh.conf` | pool `laesh`, **30 workers**, unix socket, env vars DB, `__LAESH_APP_PASS__` |
| `nginx-base.conf` | `/etc/nginx/nginx.conf` | `user www-data`, **4096 conns**, gzip, open_file_cache, **limit_req_zone** login/api |
| `nginx-laesh-ip.conf` | `/etc/nginx/sites-available/laesh` | Modo A: `server_name _`, self-signed, sin HSTS, HTTP methods, rate limit login |
| `nginx-laesh-domain.conf` | `/etc/nginx/sites-available/laesh` | Modo B: `laesh.mx`, LE certs, HSTS 1 año, HTTP methods, rate limit login |
| `10-opcache-laesh.ini` | `/etc/php/8.3/fpm/conf.d/` y `/cli/conf.d/` | OPcache 128 MB, JIT tracing 64 MB, `enable_cli=1` para cache_renew.php |

---

## Crones y systemd (`crones/`)

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `swoole-laesh.service` | systemd unit | Swoole WebSocket + HTTP IPC — `User=www-data`, `Restart=always` |
| `logrotate-laesh.conf` | logrotate | nginx, php-fpm, swoole, mariadb — daily, 30 días, compress |
| `check_cert_expiry.sh` | cron semanal (root) | Alerta si TLS vence en < 14 días; intenta auto-renew |
| `cache_renew.cron` | cron diario 5 AM (www-data) | Warm-up Cache L2 OPcache File Store — purge + re-fetch 4 datasets (~13 ms) |

---

## HTTPS (`https/`)

| Archivo | Descripción |
|---------|-------------|
| `issue_cert.sh` | Wrapper certbot: pre-check DNS, emite cert, crea symlink, instala hook post-renovación, verifica dry-run |

**Uso manual de Modo B:**

```bash
export LAESH_DOMAIN=laesh.mx
sudo -E bash https/issue_cert.sh           # emitir cert real
sudo -E bash https/issue_cert.sh --dry-run # probar sin emitir
sudo -E bash https/issue_cert.sh --force-renew
```

---

## Scripts operacionales (`scripts/`)

```bash
sudo bash scripts/laesh-start.sh      # arranca mariadb → php-fpm → swoole → nginx
sudo bash scripts/laesh-stop.sh       # detiene en orden inverso
sudo bash scripts/laesh-status.sh     # semáforo ✓/△/✗ + últimas líneas de logs
sudo bash scripts/swoole-restart.sh   # reinicia Swoole (tras deploy de código WS)
sudo bash scripts/backup_db.sh        # dump laesh_db → /opt/laesh/backups/db/
sudo bash scripts/backup_db.sh --weekly             # retención semanal (35 días)
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

Tras `08_verify.sh`, ~23/27 checks en verde son esperados.
Los 4 restantes fallan por diseño en Modo A:

| Check | Por qué falla en Modo A |
|-------|------------------------|
| HSTS header presente | Sin LE cert, HSTS no se habilita |
| HTTP/2 push | Requiere cert válido de CA |
| Cert expiry check | Self-signed, openssl reporta advertencia |
| `bash/03` — HTTPS strict | `-k` acepta self-signed; algunos sub-checks de headers fallan |

En Modo B (dominio + LE) todos los checks pasan.

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
| https_e2e | `curl -k https://127.0.0.1/laesh/` (stack completo) |

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

Definido en `nginx-base.conf`, aplicado en `location /laesh/login/`:
```nginx
# base.conf:
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
# site conf:
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

## Relacionado

- [README del directorio deploy](../README.md) — `sync_to_hkvm2.sh` y cómo transferir este pipeline
- `setup_hostinger.sh` — script de inicialización de BD (10 SQL + seed); invocado por `06_deploy_app.sh`
- Especificación técnica: `portafolio-dev-2026/blocklabgd/v1.2/et/Especificacion_Tecnica.html`
- Seguridad: `portafolio-dev-2026/blocklabgd/v1.2/et/Tecnica_Seguridad_Integral.html`
