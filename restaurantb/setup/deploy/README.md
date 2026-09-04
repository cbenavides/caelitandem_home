# Deploy — Herramientas de Sincronización

Directorio de scripts de despliegue para **LAESH Bloc Digital v1.2** en Hostinger KVM2.

---

## `sync_to_hkvm2.sh` — Sync Pipeline → Hostinger KVM2

Transfiere el contenido de `laesh-kvm2-prod/` al servidor de producción via **rsync sobre SSH**.
Soporta modo incremental (default) y full.

### Servidor destino

| Parámetro | Valor |
|-----------|-------|
| Host | `83.136.219.193` |
| Usuario SSH | `sysadmin` |
| Puerto SSH | `22` |
| Directorio remoto | `/home/sysadmin/laesh-kvm2-prod/` |

### Pre-requisito: SSH key (una sola vez)

Sin key instalada, cada ejecución pedirá contraseña interactiva.
Para evitarlo, copiar la key local al servidor:

```bash
ssh-copy-id -p 22 sysadmin@83.136.219.193
# Contraseña SSH: laesh-26
```

Verificar:

```bash
ssh sysadmin@83.136.219.193 "echo OK"
# Debe responder OK sin pedir contraseña
```

### Uso

```bash
cd /home/carlos/GitHub/caelitandem_home/restaurantb/setup/deploy

# 1. Simular — ver qué se transferiría sin tocar nada
./sync_to_hkvm2.sh --dry-run

# 2. Incremental — solo archivos nuevos o modificados (uso habitual)
./sync_to_hkvm2.sh

# 3. Full — incremental + elimina en remoto lo que ya no existe local
./sync_to_hkvm2.sh --full

# Combinaciones
./sync_to_hkvm2.sh --full --dry-run
```

### Qué sincroniza

```
laesh-kvm2-prod/          →   /home/sysadmin/laesh-kvm2-prod/
├── 00_run_all.sh
├── 01_preflight.sh … 08_verify.sh
├── configs/              →   configs del stack (nginx, php, mariadb, fpm)
├── crones/               →   systemd unit, logrotate, script expiry cert
├── https/                →   issue_cert.sh (wrapper certbot)
└── scripts/              →   operacionales (start/stop/status/backup/restore)
```

### Qué NO sincroniza (sync separado requerido)

| Contenido | Origen local | Destino remoto |
|-----------|-------------|----------------|
| Código fuente webapp | `restaurantb/www/laesh-swbldi/` | `/opt/laesh/www/laesh-swbldi/` |
| Assets UI | `restaurantb/www/laesh-web-assets-uipv1a/` | `/opt/laesh/assets/laesh-web-assets-uipv1a/` |

El script `06_deploy_app.sh` (dentro del pipeline) hace ese rsync directamente desde el servidor si el repo está montado; de lo contrario se transfiere manualmente o via CI.

### Exclusiones aplicadas

`.git/`, `*.swp`, `*.bak`, `.DS_Store`

### Comportamiento de `--checksum`

rsync compara archivos por **checksum SHA**, no solo por timestamp/tamaño.
Garantiza que un archivo editado pero con el mismo nombre se detecte y retransfiera correctamente aunque el timestamp no haya cambiado.

### Después del sync

```bash
ssh sysadmin@83.136.219.193
cd ~/laesh-kvm2-prod

# Pipeline completo (exportar vars de entorno primero)
export LAESH_ROOT_PASS='<root-db-pass>'
export LAESH_APP_PASS='<app-db-pass>'
sudo -E bash 00_run_all.sh

# O paso a paso
sudo bash 01_preflight.sh
sudo bash 02_install_stack.sh
# ...
```

Ver [laesh-kvm2-prod/README.md](laesh-kvm2-prod/README.md) para la ejecución completa del pipeline.

---

## Contenido de este directorio

```
setup/deploy/
├── README.md                  ← este archivo
├── sync_to_hkvm2.sh           ← sync pipeline a Hostinger KVM2
├── laesh-kvm2-prod/           ← pipeline de instalación (ver README interno)
└── setup_hkvm2.sh             ← script legacy (referencia histórica)
```
