# Deploy — Herramientas de Sincronización

Directorio de scripts de despliegue para **LAESH Bloc Digital v1.2** en Hostinger KVM2.

---

## Servidor destino

| Parámetro | Valor |
|-----------|-------|
| Proveedor | Hostinger KVM2 |
| SO | Ubuntu 24.04 LTS |
| IP pública | `83.136.219.193` |
| Usuario SSH | `sysadmin` |
| Puerto SSH | `22` |
| Pipeline remoto | `~/laesh-setup/` |
| Código fuente remoto | `/home/sysadmin/laesh-src/` |

---

## Pre-requisito: SSH key (una sola vez)

Sin key instalada, cada rsync pedirá contraseña interactiva.

```bash
ssh-copy-id -p 22 sysadmin@83.136.219.193

# Verificar (debe responder OK sin pedir contraseña):
ssh sysadmin@83.136.219.193 "echo OK"
```

---

## Transferencia al servidor (4 rsync desde local)

Ejecutar desde la máquina local **antes de correr el pipeline** en el servidor.

```bash
SERVER="sysadmin@83.136.219.193"

# 2a. Pipeline de instalación (scripts 00–08, configs, crones, https, scripts/):
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

> **`--mkpath`** (rsync ≥ 3.2.3): crea el árbol de directorios intermedios en el servidor si no existen.
> El servidor KVM2 tiene rsync 3.2.7 ✅.

### Qué transfiere cada rsync

| Cmd | Origen local | Destino remoto | Usado por |
|-----|-------------|----------------|-----------|
| 2a | `setup/deploy/laesh-kvm2-prod/` | `~/laesh-setup/` | Pipeline 00–08 |
| 2b | `www/laesh-swbldi/` | `laesh-src/laesh-swbldi/` | `06_deploy_app.sh` paso 2 |
| 2c | `www/laesh-web-assets-uipv1a/` | `laesh-src/laesh-web-assets-uipv1a/` | `06_deploy_app.sh` paso 3 |
| 2d | `setup/bds/laesh/` | `laesh-src/setup/bds/laesh/` | `06_deploy_app.sh` paso 6 (setup_hostinger.sh) |

---

## Ejecución del pipeline en el servidor

### Dar permisos (una vez tras el rsync 2a)

```bash
ssh sysadmin@83.136.219.193
chmod +x ~/laesh-setup/*.sh ~/laesh-setup/scripts/*.sh ~/laesh-setup/https/*.sh
```

### Verificar que el código llegó

```bash
ls /home/sysadmin/laesh-src/laesh-swbldi/
ls /home/sysadmin/laesh-src/setup/bds/laesh/setup_hostinger.sh
```

### Exportar variables de entorno

```bash
export LAESH_ROOT_PASS='<contraseña-root-mariadb>'
export LAESH_APP_PASS='<contraseña-laesh_app>'
export LAESH_SMTP_PASS='<app-password-yahoo>'
# LAESH_DOMAIN — omitir hasta que DNS laesh.mx apunte al servidor

# Verificar:
echo "ROOT: ${LAESH_ROOT_PASS:+[OK]}"
echo "APP:  ${LAESH_APP_PASS:+[OK]}"
echo "SMTP: ${LAESH_SMTP_PASS:+[OK]}"
```

### Opción A — Pipeline completo automático

```bash
cd ~/laesh-setup
sudo -E bash 00_run_all.sh
```

### Opción B — Paso a paso (recomendado en primera instalación)

```bash
cd ~/laesh-setup
sudo bash 01_preflight.sh
sudo bash 02_install_stack.sh
sudo bash 03_install_swoole.sh
sudo -E bash 04_configure_stack.sh
sudo bash 05_tls_certbot.sh         # Modo A (self-signed) por defecto
sudo -E bash 06_deploy_app.sh
sudo -E bash 07_security_harden.sh
sudo bash 08_verify.sh
```

### Reanudar desde un paso fallido

```bash
sudo -E bash 00_run_all.sh --from=4   # reanudar desde paso 4
sudo -E bash 00_run_all.sh --only=6   # solo paso 6
sudo -E bash 00_run_all.sh --skip=3   # todos excepto paso 3
```

> **Nota**: Las variables de entorno se pierden si la sesión SSH se interrumpe.
> Re-exportar las 3 variables antes de reanudar.

---

## Estado de instalación KVM2 (2026-09-04)

| Paso | Script | Estado |
|------|--------|--------|
| 1 | `01_preflight.sh` — swap, dirs, ulimits | ✅ Completado |
| 2 | `02_install_stack.sh` — Nginx / MariaDB / PHP 8.3 | ✅ Completado (Composer manual) |
| 3 | `03_install_swoole.sh` — Swoole 6.2.2 | ✅ Completado (libbrotli-dev manual) |
| 4 | `04_configure_stack.sh` — configs + contraseña root MariaDB | ✅ Completado (2ª ejecución tras cert) |
| 5 | `05_tls_certbot.sh` — self-signed (Modo A) | ✅ Completado |
| 6 | `06_deploy_app.sh` — rsync + BD + Composer + Swoole | ✅ Completado (seed usuarios manual) |
| 7 | `07_security_harden.sh` — UFW, SMTP, log-levels, cron backup | ⏳ Pendiente |
| 8 | `08_verify.sh` — suite de verificación final | ⏳ Pendiente |

---

## `sync_to_hkvm2.sh` — Sync rápido del pipeline (uso iterativo)

Alternativa al rsync 2a para re-sincronizar solo los scripts del pipeline tras cambios locales.

```bash
cd /home/carlos/GitHub/caelitandem_home/restaurantb/setup/deploy

./sync_to_hkvm2.sh            # incremental
./sync_to_hkvm2.sh --full     # incremental + elimina remotos huérfanos
./sync_to_hkvm2.sh --dry-run  # simular sin tocar nada
```

> Solo sincroniza `laesh-kvm2-prod/` → `~/laesh-setup/`.
> Para código, assets o BD usar los rsync 2b/2c/2d arriba.

---

## Contenido de este directorio

```
setup/deploy/
├── README.md                  ← este archivo
├── sync_to_hkvm2.sh           ← sync rápido del pipeline a KVM2
├── laesh-kvm2-prod/           ← pipeline de instalación (ver README interno)
└── setup_hkvm2.sh             ← script legacy (referencia histórica)
```

Ver [laesh-kvm2-prod/README.md](laesh-kvm2-prod/README.md) para documentación completa del pipeline.
