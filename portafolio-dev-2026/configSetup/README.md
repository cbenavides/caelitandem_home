# Recreación de Infraestructura OCI-VM (Nginx + PHP-FPM + Let's Encrypt)

Este directorio contiene las herramientas y especificaciones necesarias para reconstruir la infraestructura del servidor web y procesamiento dinámico en la instancia `oci-vm` desde cero (Ubuntu 22.04 LTS).

---

## 📋 Arquitectura de la Solución

El script automatiza los siguientes componentes:
1. **Desbloqueo de APT:** Soluciona y comenta los repositorios obsoletos de Kubernetes (`kubernetes.list`) para evitar bloqueos en el gestor de paquetes.
2. **Instalación:** Nginx, PHP 8.1 (FPM y extensiones `mysql`, `xml`, `curl`, `mbstring`) y Certbot (Let's Encrypt) con el plugin de Nginx.
3. **Optimización de PHP-FPM (para VM de 24 GB RAM / 4 cores ARM64):**
   * Configuración de PM dinámica y agresiva (`max_children = 50`, `start_servers = 10`, `min_spare_servers = 5`, `max_spare_servers = 15`).
   * Configuración anti-fugas de memoria (`max_requests = 500`).
   * Incremento de límites de php.ini (`memory_limit = 512M`, `upload_max_filesize = 100M`).
   * Habilitación de OPcache con consumo de memoria de 256MB.
4. **Bootstrapping Nginx (Puerto 80):** Levanta configuraciones temporales de Nginx para permitir el reto de Let's Encrypt sin errores de SSL.
5. **Certificados Let's Encrypt:** Automatiza y solicita los certificados SSL para `caelitandem.lat`, `www.caelitandem.lat` y `n8n.caelitandem.lat`.
6. **Configuración Final HTTPS con Ruteo Aislado:**
   * **`caelitandem.lat` / `www.caelitandem.lat`:** Sirve HTML estático por defecto desde `/home/ubuntu/sitios_2026/caelitandem-home`. La ruta `/mvps` (por ejemplo, el POC de Dictado de Voz Vosk) se procesa de forma aislada bajo `/home/ubuntu/n8n-php/mvps/` usando `location ^~ /mvps` (previniendo colisiones de caché con expresiones regulares).
   * **`n8n.caelitandem.lat`:** Actúa como proxy inverso al puerto `5678` (n8n), pero procesa archivos `.php` localmente bajo el directorio raíz `/home/ubuntu/n8n-php/`.
7. **Renovación Automática:** Instala el script `renew-certs.sh` en `/home/ubuntu/scripts/` y configura un cron job diario a las 03:00 AM para auto-renovación y recarga de Nginx.

---

## 🚀 Instrucciones de Uso (Paso a Paso)

### Paso 1: Configurar DNS en tu Proveedor
Antes de ejecutar el script, asegúrate de que los registros DNS apunten a la IP pública del servidor:
* Registro **A** para `@` (caelitandem.lat) apuntando a la IP.
* Registro **CNAME** o **A** para `www` (www.caelitandem.lat) apuntando a la IP.
* Registro **A** para `n8n` (n8n.caelitandem.lat) apuntando a la IP.

### Paso 2: Transferir y ejecutar el Script
Copia el script `setup-oci-vm.sh` a tu nuevo servidor y ejecútalo como root:

```bash
# 1. Dar permisos de ejecución
chmod +x setup-oci-vm.sh

# 2. Ejecutar como root o con sudo
sudo ./setup-oci-vm.sh
```

El script te solicitará interactivamente un correo de contacto para el registro de Let's Encrypt. El resto de la instalación, descargas y configuraciones se realizarán de forma 100% autónoma.

### Paso 3: Subir los Archivos de la Aplicación
Una vez completado el script, sube tus desarrollos a las rutas correspondientes:
* **Landing Page Estático:** `/home/ubuntu/sitios_2026/caelitandem-home/`
* **Prototipos / MVPs PHP (Vosk, etc.):** `/home/ubuntu/n8n-php/mvps/`

---

## 📂 Archivos en este Directorio
* `setup-oci-vm.sh` — Script auto-contenido de instalación y optimización.
