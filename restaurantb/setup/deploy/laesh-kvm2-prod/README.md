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

## Variables de entorno requeridas

Exportar antes de ejecutar cualquier script que toque la BD:

```bash
export LAESH_ROOT_PASS='<contraseña-root-mariadb>'
export LAESH_APP_PASS='<contraseña-usuario-laesh_app>'
```

Opcional para Modo B (dominio con Let's Encrypt):

```bash
export LAESH_DOMAIN='laesh.mx'
export LAESH_CERT_EMAIL='admin@laesh.mx'
```

Sin `LAESH_DOMAIN` → el pipeline corre en **Modo A** (self-signed, pura IP).

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
sudo bash 01_preflight.sh
sudo bash 02_install_stack.sh
sudo bash 03_install_swoole.sh
export LAESH_APP_PASS='...'
sudo -E bash 04_configure_stack.sh
sudo bash 05_tls_certbot.sh          # Modo A por defecto
export LAESH_ROOT_PASS='...'
sudo -E bash 06_deploy_app.sh
sudo bash 07_security_harden.sh
sudo bash 08_verify.sh
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

### Cómo funciona

```
1ª visita:  PHP → MariaDB → array → serialize → /tmp/laesh_cache/laesh_cache_prod_LAESH_CMS.php
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

`/tmp/laesh_cache/` — PHP lo crea automáticamente en el primer request. `www-data` necesita escritura en `/tmp` (estándar Ubuntu).

### Bypass CMS Preview

`?_preview=1` + sesión activa ADMIN + borrador en `$_SESSION['cms_draft']` → bypass total del cache. El motor sirve desde MariaDB + sesión, no desde RAM.

### Warm-up y cron

```bash
# Verificar que el cron esté instalado
cat /etc/cron.d/laesh-cache-renew

# Forzar warm-up manual
sudo -u www-data php8.3 /opt/laesh/www/laesh-swbldi/crons/cache_renew.php

# Ver log
tail -20 /opt/laesh/logs/cache-renew.log
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
