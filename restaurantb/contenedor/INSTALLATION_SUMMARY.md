# Instalación del Stack Docker LAMP – **restaurantb**

---

## 📦 Descripción General
Este documento resume todo el proceso de instalación y configuración del stack **LAMP** (Linux, Apache, MariaDB, PHP) para el proyecto **restaurantb** bajo Docker.  Incluye los componentes del `docker‑compose.yml`, los archivos de configuración **default** y **custom**, variables de entorno y los comandos habituales para operar el entorno.

---

## 📋 Prerrequisitos
- Docker Engine + Docker Compose instalados (versión 2.20+ recomendada).
- Acceso a la carpeta del proyecto:
  ```bash
  cd /home/carlos/GitHub/caelitandem_home/restaurantb/contenedor
  ```
- (Opcional) Cliente MySQL heredado de XAMPP: `/opt/lampp/bin/mysql`.

---

## 🗂️ Estructura del proyecto
```
restaurantb/
├─ contenedor/
│   ├─ Dockerfile                     # Construye la imagen `restaurantb_web`
│   ├─ docker-compose.yml            # Orquesta los servicios (web, db, pma)
│   ├─ .env                          # Variables de entorno (no versionado)
│   ├─ conf/
│   │   ├─ php-restaurantb.ini       # Config PHP 8.3 adaptada de XAMPP
│   │   ├─ mariadb-restaurantb.cnf   # Config MariaDB 11 adaptada de my.ini
│   │   ├─ apache-restaurantb.conf    # Config Apache 2.4 (sin rutas Windows)
│   │   └─ pma-config.user.inc.php   # Config phpMyAdmin (auth cookie, allow arbitrary)
│   └─ bd/
│       └─ init/
│           └─ 01_pmadb.sql          # Crea usuario `pma` y base `phpmyadmin`
``` 
---

## 🐳 `docker‑compose.yml` – Servicios principales
| Servicio | Imagen | Puertos (host → contenedor) | Volúmenes | Comentario |
|----------|--------|----------------------------|-----------|------------|
| **web** | `restaurantb_web:latest` (PHP 8.3‑Apache) | `6001 → 80` (HTTP) <br> `8443 → 443` (HTTPS) | `./www:/var/www/html` (código) <br> `../logs/apache:/var/log/apache2` | Servidor web que sirve la aplicación. Config extra `apache-restaurantb.conf` y `php-restaurantb.ini` se copian en la imagen. |
| **db** | `mariadb:11` | `6002 → 3306` | `db_data:/var/lib/mysql` <br> `../logs/mariadb:/var/log/mysql` <br> `../bd/init:/docker-entrypoint-initdb.d` (scripts de arranque) <br> `./conf/mariadb-restaurantb.cnf:/etc/mysql/conf.d/restaurantb.cnf:ro` | Base de datos con configuración custom (charset utf8mb4, bind‑address 0.0.0.0, logs, slow‑query‑log, etc.). |
| **pma** | `phpmyadmin:latest` | `6080 → 80` (expuesto a *0.0.0.0*) | `./conf/pma-config.user.inc.php:/etc/phpmyadmin/config.user.inc.php:ro` | Interfaz web para gestión de MySQL/MariaDB. `PMA_ARBITRARY=1` permite conectar a cualquier servidor, `AllowArbitraryServer` habilitado en la configuración. |

---

## 🔧 Configuraciones *default* vs *custom*
| Archivo | Propósito | Estado | Comentario |
|--------|-----------|--------|------------|
| `conf/php-restaurantb.ini` | `php.ini` adaptado a PHP 8.3 (límites, logging, timezone, etc.) | **Custom** | Comentados los valores Windows, se usan rutas Linux y se habilitan buenas prácticas de producción. |
| `conf/mariadb-restaurantb.cnf` | `my.cnf` adaptado a MariaDB 11 (charset, innodb, buffers, bind‑address, logs) | **Custom** | Se omiten rutas Windows, se ajustan tamaños de buffer a contenedor. |
| `conf/apache-restaurantb.conf` | Config Apache extra (headers de seguridad, compresión, disables XAMPP‑only modules) | **Custom** | Carga módulos `ssl`, `rewrite`, `headers`, `deflate`; desactiva `ServerTokens` y `ServerSignature`. |
| `conf/pma-config.user.inc.php` | Config phpMyAdmin (blowfish secret, auth cookie, AllowArbitraryServer) | **Custom** | Permite login seguro y conexión a cualquier host MySQL. |
| `bd/init/01_pmadb.sql` | Script de inicialización (crea usuario `pma` y base `phpmyadmin`) | **Custom** | Se ejecuta sólo la primera vez del contenedor de DB. |
| `.env` | Variables de entorno (contraseñas, puertos) | **Custom** | No versionado (`.gitignore`). |

---

## 🔐 Variables de entorno (archivo `.env`)
```
# MariaDB credentials
MARIADB_ROOT_PASSWORD=comite_2026
MARIADB_DATABASE=restaurantb
MARIADB_USER=restaurantb_usr
MARIADB_PASSWORD=rb_pass_2026

# Puertos externos (host → contenedor)
WEB_HTTP_PORT=6001
WEB_HTTPS_PORT=8443
DB_PORT=6002
PMA_PORT=6080
```
> **Nota:** Cambia estas contraseñas antes de pasar a producción.

---

## 🚀 Comandos de operación
| Acción | Comando | Comentario |
|--------|---------|------------|
| **Iniciar / (re)construir** | `docker compose up -d --build` | Levanta los 3 servicios; `--build` recompila la imagen `web` si el Dockerfile cambió. |
| **Detener** | `docker compose down` | Elimina contenedores, redes y volúmenes *named* (pero conserva `db_data`). |
| **Reiniciar** | `docker compose restart` | Reinicia los contenedores sin volver a crear imágenes. |
| **Estado** | `docker compose ps` | Muestra estado y puertos expuestos. |
| **Logs (todos)** | `docker compose logs -f` | Sigue los logs en tiempo real. |
| **Logs de un servicio** | `docker compose logs -f <service>` (p.ej. `db`) | Filtra por servicio. |
| **Shell dentro de un contenedor** | `docker compose exec <service> bash` | Útil para depuración (`web`, `db`, `pma`). |
| **Conectar con cliente MySQL heredado** | `/opt/lampp/bin/mysql -h 127.0.0.1 -P 6002 -u root -p` | Contraseña: `comite_2026`. Cambia `root` por `restaurantb_usr` o `pma` según necesites. |

---

## 🌐 **Resumen rápido de la instalación Docker LAMP (restaurantb) con URLs completas (localhost)**

| Servicio | URL completa (localhost) | Usuario / Contraseña (ejemplo) |
|----------|--------------------------|---------------------------------|
| **Web – HTTP** | `http://localhost:6001` | — |
| **Web – HTTPS** | `https://localhost:8443` | — (certificado auto‑firmado) |
| **phpMyAdmin** | `http://localhost:6080` | Usa las credenciales de **db** (p. ej. `root/comite_2026`). |
| **MariaDB** (acceso CLI) | `mysql -h localhost -P 6002 -u <user> -p` | `root/comite_2026` <br> `restaurantb_usr/rb_pass_2026` <br> `pma/pma_pass_2026` |

---

## 📌 Notas finales
- Los puertos están mapeados a `0.0.0.0`, por lo que cualquier máquina de la LAN puede acceder usando la IP del host (p. ej. `http://192.168.1.45:6001`).
- Para producción, reemplaza el certificado auto‑firmado por uno válido y cambia las contraseñas del archivo `.env`.
- Los volúmenes `db_data` y los logs persisten en `../bd/data` y `../logs/*` respectivamente, facilitando backups.

---

## 🎙️ Anexo: Uso del Micrófono en Dispositivos Móviles (Red Local)

### El problema: `localhost` vs IP Local (`192.168.x.x`)
Los navegadores modernos tienen una regla estricta: `localhost` se considera siempre un entorno seguro, permitiendo el acceso al micrófono (`getUserMedia`). Sin embargo, al acceder desde un dispositivo móvil en la misma red local a través de la IP de la máquina (ej: `https://192.168.1.45:8443`), el navegador detectará que el certificado es auto-firmado. 
Aunque se acepte la advertencia ("Continuar de forma insegura"), el navegador degradará el contexto de seguridad y **bloqueará el micrófono silenciosamente**.

### Soluciones prácticas para red local

#### Opción A: La forma rápida (Ideal para pruebas o pocos dispositivos)
Permite tratar la IP local como segura directamente en Chrome de Android.
1. En el navegador del móvil, visita `chrome://flags`
2. Busca la opción: **`Insecure origins treated as secure`**
3. Añade la URL con la IP local y el puerto HTTP (no es necesario HTTPS para este flag), por ejemplo: `http://192.168.1.45:6001`
4. Cambia la opción a **Enabled** y presiona **Relaunch** (Reiniciar).
*Resultado: Chrome permitirá usar el micrófono sobre la red local sin requerir un HTTPS válido.*

#### Opción B: La forma robusta (Certificado Raíz propio)
Para múltiples dispositivos sin tener que tocar configuraciones internas del navegador.
1. Generar una CA (Autoridad Certificadora) local y un certificado para la IP (por ejemplo, usando la herramienta `mkcert` en Linux).
1.2 /opt/lampp/htdocs/agua/.chatledger/Anonymizing_Tlapa_System_Reports_41182f672b07.md para lets encrypt uso y/o lo de renovación automaticas, como se aplico al sitio caelitandem en la VM OCI Always free.
2. Reemplazar los certificados auto-firmados en la carpeta `restaurantb/contenedor/ssl/` con los nuevos generados.
3. Instalar el certificado de la CA raíz (`rootCA.crt`) en cada teléfono Android (usualmente en *Ajustes > Seguridad > Cifrado y credenciales > Instalar certificado*).
*Resultado: La conexión HTTPS será reconocida como 100% segura (candado verde) y el micrófono funcionará nativamente por defecto.*

---

*Este documento fue generado automáticamente por el asistente de IA después de configurar el stack Docker LAMP para `restaurantb`.*
