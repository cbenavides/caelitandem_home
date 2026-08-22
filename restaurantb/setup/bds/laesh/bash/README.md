# bash/ — Scripts de Setup LAESH

Scripts de infraestructura ejecutados **desde el host** (fuera de los contenedores),
orquestados por `../setup.sh`. No ejecutar en aislado salvo debugging.

## Scripts

| Script | Qué hace | Cuándo |
|--------|----------|--------|
| `01_install_auth.sh` | Crea las 7 tablas de Delight-Auth en `laesh_db` via `docker exec` al contenedor MariaDB. Idempotente: `CREATE TABLE IF NOT EXISTS`. | Primer arranque o reset de BD |
| `02_seed_users.sh` | Ejecuta `commons/seed_first_users.php` dentro del contenedor PHP-FPM. Crea 3 usuarios demo (ADMIN, RECEPCION, MEDICO). Idempotente. | Después de que el schema esté listo |

## Ejecutar

```bash
# Siempre preferir el orquestador completo:
bash setup/bds/laesh/setup.sh

# Aislado (solo si se necesita depurar un paso):
bash setup/bds/laesh/bash/01_install_auth.sh
bash setup/bds/laesh/bash/02_seed_users.sh
```

## Variables sobreescribibles

```bash
# 01_install_auth.sh
DB_CONTAINER   (default: restaurantb_db)
DB_NAME        (default: laesh_db)
DB_USER        (default: root)
DB_PASS        (default: comite_2026)

# 02_seed_users.sh
WEB_CONTAINER  (default: restaurantb_phpfpm)
```

## Pre-requisitos

- `docker ps` muestra `restaurantb_db` y `restaurantb_phpfpm` corriendo
- `../setup.sh` los llama en el orden correcto — `01` antes que los SQL, `02` al final

## ¿Por qué aquí y no en `commons/`?

Estos scripts usan `docker exec` y necesitan el Docker socket del host.
Si vivieran dentro del volumen web (`www/`), estarían dentro del contenedor
y no podrían ejecutar `docker exec`. Ver `../README.md` para el pipeline completo.
