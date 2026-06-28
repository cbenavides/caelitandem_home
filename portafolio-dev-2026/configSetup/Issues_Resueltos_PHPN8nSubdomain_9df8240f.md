# Issues Resueltos — Sesión 2026-06-10
**Conversación:** `9df8240f-6a37-4147-b8a3-c44b0ab61092`
**Rama:** `main`

---

## Issue 3 — Ejecución de Páginas PHP en el Subdominio n8n.caelitandem.lat

### Scope Funcional
- **Antes:** El subdominio `n8n.caelitandem.lat` actuaba exclusivamente como proxy inverso para la aplicación Node.js de n8n en el puerto 5678. No existía soporte para PHP en el servidor `oci-vm` (PHP no estaba instalado) ni configuraciones para servir scripts dinámicos locales junto a la aplicación proxy.
- **Ahora:** Se instaló PHP 8.1 y PHP-FPM con optimizaciones avanzadas de rendimiento y seguridad. Se modificó el vhost de Nginx de n8n para interceptar solicitudes de archivos `.php` y procesarlas a través del socket de PHP-FPM apuntando al directorio local `/home/ubuntu/n8n-php/`. El resto del tráfico sigue dirigiéndose con normalidad a n8n.
- **Beneficio:** Capacidad de ejecutar scripts de apoyo en PHP (webhooks personalizados, integraciones locales o APIs) bajo el mismo subdominio de automatización (`n8n.caelitandem.lat/*.php`) sin interrumpir la operación de la interfaz o la API de n8n.

### Scope Técnico
- **Bypass de Repositorio Kubernetes:** Se comentó el repositorio de Kubernetes deprecado en `/etc/apt/sources.list.d/kubernetes.list` para permitir que `apt-get update` se ejecutara correctamente.
- **Instalación:** PHP 8.1, PHP-FPM y extensiones clave (`mysql`, `xml`, `curl`, `mbstring`).
- **Optimizaciones PHP-FPM (`pool.d/www.conf`):**
  * Ajuste de procesos simultáneos aprovechando los 23 GB de RAM y 4 núcleos CPU de la VM:
    * `pm.max_children = 50` (antes 5)
    * `pm.start_servers = 10` (antes 2)
    * `pm.min_spare_servers = 5` (antes 1)
    * `pm.max_spare_servers = 15` (antes 3)
    * `pm.max_requests = 500` (previene fugas de memoria)
- **Optimizaciones de Entorno (`php.ini`):**
  * Límites ampliados: `memory_limit = 512M`, `upload_max_filesize = 100M`, `post_max_size = 100M`, `max_execution_time = 60`.
  * Activación y optimización de caché OPcache:
    * `opcache.enable = 1`
    * `opcache.memory_consumption = 256`
- **Configuración de Nginx:**
  * Se insertó un bloque de localización exclusivo para interceptar scripts PHP y procesarlos de forma segura en `/etc/nginx/sites-available/n8n.caelitandem.lat`:
    ```nginx
    location ~ \.php$ {
        root /home/ubuntu/n8n-php;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
    ```
- **Directorio de Trabajo:** Creación y permisos de `/home/ubuntu/n8n-php/` (acceso de lectura a `www-data` a través de permisos `755`). Se incluyeron scripts de prueba `index.php` e `info.php`.

---

## Issue 4 — Ruteo y Soporte PHP para la Carpeta /mvps en el Dominio Principal

### Scope Funcional
- **Antes:** La ruta `/mvps` en `https://www.caelitandem.lat/` arrojaba error **HTTP 404 Not Found**, ya que el dominio principal estaba configurado únicamente para servir contenido HTML/JS/CSS estático desde `/home/ubuntu/sitios_2026/caelitandem-home`. No tenía soporte para procesar PHP ni acceso al directorio `/home/ubuntu/n8n-php/mvps/`.
- **Ahora:** Se configuró un bloque de ruteo dedicado en el vhost del dominio principal. Utilizando el operador `^~` de Nginx, se forzó a que cualquier recurso dentro de la ruta `/mvps` (ya sean archivos estáticos como `.js`/`.css`/imágenes, o scripts dinámicos `.php`) se resuelva de manera aislada dentro de `/home/ubuntu/n8n-php/mvps/`, ejecutando PHP-FPM para cualquier archivo con extensión `.php`.
- **Beneficio:** Permite alojar y ejecutar prototipos interactivos (como el POC de Dictado por Voz Vosk en `/mvps/vosk-sm/vozweb.php`) de forma transparente bajo el dominio principal de producción (`www.caelitandem.lat`) sin alterar el funcionamiento del resto del sitio estático.

### Scope Técnico
- **Uso de `^~` (Bypass de Expresiones Regulares):**
  Para evitar que los bloques globales de caché de archivos estáticos (que buscan imágenes/CSS en el root estático) interfirieran con los activos locales de `/mvps`, se implementó la directiva `location ^~ /mvps` con procesamiento PHP anidado:
  ```nginx
  location ^~ /mvps {
      root /home/ubuntu/n8n-php;
      index index.php index.html index.htm;
      try_files $uri $uri/ =404;

      location ~ \.php$ {
          include snippets/fastcgi-php.conf;
          fastcgi_pass unix:/run/php/php8.1-fpm.sock;
          fastcgi_buffers 16 16k;
          fastcgi_buffer_size 32k;
      }
  }
  ```

---

## Archivos Modificados

| Archivo | Repo / Entorno | Tipo de cambio |
|:---|:---:|:---|
| `/etc/apt/sources.list.d/kubernetes.list` | oci-vm (Sistema) | Comentado el repositorio de Kubernetes obsoleto. |
| `/etc/php/8.1/fpm/pool.d/www.conf` | oci-vm (Sistema) | Optimización del administrador de procesos (PM). |
| `/etc/php/8.1/fpm/php.ini` | oci-vm (Sistema) | Optimización de límites de ejecución, subidas y caché OPcache. |
| `/etc/nginx/sites-available/n8n.caelitandem.lat` | oci-vm (Sistema) | Adición del bloque de procesamiento PHP y root local en subdominio. |
| `/etc/nginx/sites-available/caelitandem.lat` | oci-vm (Sistema) | Adición del bloque de ruteo prioritario (`^~ /mvps`) con soporte de activos y PHP. |
| `/home/ubuntu/n8n-php/{index.php, info.php}` | oci-vm (Directorio de usuario) | Creación de archivos y ruta de scripts PHP. |

---

## Verificación

| Check | Resultado |
|:---|:---:|
| `sudo nginx -t` en oci-vm | ✅ Exitoso (sintaxis correcta) |
| `curl -i https://n8n.caelitandem.lat/index.php` | ✅ Devuelve HTTP 200 OK y *"n8n PHP is working!"* |
| `curl -i https://n8n.caelitandem.lat/info.php` | ✅ Devuelve HTTP 200 OK y el HTML de `phpinfo()` |
| `curl -i https://n8n.caelitandem.lat/` | ✅ Devuelve la interfaz de n8n por proxy-pass |
| `curl -i https://www.caelitandem.lat/mvps/vosk-sm/vozweb.php` | ✅ Devuelve HTTP 200 OK y el HTML del POC de Voz |
| `curl -i https://www.caelitandem.lat/mvps/vosk-sm/upload_model.php` | ✅ Devuelve HTTP 200 OK y JSON de confirmación |
| `systemctl status php8.1-fpm` | ✅ Activo y corriendo optimizado |

---
*Generado por Antigravity — 2026-06-10*
