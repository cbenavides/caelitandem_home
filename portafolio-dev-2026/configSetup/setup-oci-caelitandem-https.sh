#!/usr/bin/env bash
# =============================================================================
# setup-oci-vm.sh
# Script autoconfigurado para recreación de infraestructura en OCI-VM.
# Ejecutar como root en una instancia limpia de Ubuntu 22.04 LTS.
# =============================================================================

# Configurar salida ante cualquier error
set -e

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Iniciando instalación y optimización de OCI-VM ===${NC}"

# 1. Validación de permisos root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse como root (sudo).${NC}"
    exit 1
fi

# 2. Reparación y desbloqueo de APT
KUBE_LIST="/etc/apt/sources.list.d/kubernetes.list"
if [ -f "$KUBE_LIST" ]; then
    echo "Desactivando repositorios conflictivos obsoletos..."
    sed -i 's/^deb /# deb /' "$KUBE_LIST"
fi

# 3. Instalación de paquetes
echo "Actualizando índices de paquetes e instalando dependencias..."
apt-get update
apt-get install -y nginx php8.1-fpm php8.1-mysql php8.1-xml php8.1-curl php8.1-mbstring certbot python3-certbot-nginx curl openssl git

# 4. Creación de la estructura de directorios
echo "Creando estructura de directorios en /home/ubuntu..."
mkdir -p /home/ubuntu/sitios_2026/caelitandem-home
mkdir -p /home/ubuntu/n8n-php/mvps
mkdir -p /home/ubuntu/scripts
mkdir -p /home/ubuntu/logs

# Asignar permisos correctos para el usuario 'ubuntu' y Nginx (www-data)
chown -R ubuntu:ubuntu /home/ubuntu/sitios_2026 /home/ubuntu/n8n-php /home/ubuntu/scripts /home/ubuntu/logs
chmod 755 /home/ubuntu/sitios_2026 /home/ubuntu/n8n-php /home/ubuntu/n8n-php/mvps

# 5. Creación de archivos de prueba PHP
echo "Escribiendo archivos de prueba PHP..."
echo "<?php echo 'n8n PHP is working!'; ?>" > /home/ubuntu/n8n-php/index.php
echo "<?php phpinfo(); ?>" > /home/ubuntu/n8n-php/info.php
chown ubuntu:ubuntu /home/ubuntu/n8n-php/index.php /home/ubuntu/n8n-php/info.php
chmod 644 /home/ubuntu/n8n-php/index.php /home/ubuntu/n8n-php/info.php

# 6. Configuración del script de renovación automatizada y cron job
echo "Escribiendo scripts de renovación de certificados..."
cat << 'EOF' > /home/ubuntu/scripts/renew-certs.sh
#!/usr/bin/env bash
# renew-certs.sh — Auto-renovación de certificados y recarga de Nginx
LOG_FILE="/home/ubuntu/logs/certbot-renew.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "=== Iniciando validación de certificados: $(date) ===" >> "$LOG_FILE"
if certbot renew --post-hook "systemctl reload nginx" >> "$LOG_FILE" 2>&1; then
    echo "[OK] Ejecución de Certbot completada sin errores." >> "$LOG_FILE"
else
    echo "[ERROR] Certbot encontró problemas al intentar renovar." >> "$LOG_FILE"
fi
echo "==========================================================" >> "$LOG_FILE"
EOF

chmod +x /home/ubuntu/scripts/renew-certs.sh
chown ubuntu:ubuntu /home/ubuntu/scripts/renew-certs.sh

echo "Instalando tarea en cron diaria a las 03:00 AM..."
cat << 'EOF' > /etc/cron.d/certbot-custom
# /etc/cron.d/certbot-custom
# Corre todos los días a las 03:00 AM como usuario root
0 3 * * * root /home/ubuntu/scripts/renew-certs.sh >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/certbot-custom

# 7. Aplicando optimizaciones de rendimiento y límites en PHP
echo "Aplicando optimizaciones en php.ini y pool de PHP-FPM..."

# Pool FPM (www.conf) - optimizado para VM de 24GB RAM
sed -i 's/^pm.max_children = .*/pm.max_children = 50/' /etc/php/8.1/fpm/pool.d/www.conf
sed -i 's/^pm.start_servers = .*/pm.start_servers = 10/' /etc/php/8.1/fpm/pool.d/www.conf
sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/' /etc/php/8.1/fpm/pool.d/www.conf
sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 15/' /etc/php/8.1/fpm/pool.d/www.conf
if ! grep -q "^pm.max_requests =" /etc/php/8.1/fpm/pool.d/www.conf; then
    sed -i 's/^;pm.max_requests = .*/pm.max_requests = 500/' /etc/php/8.1/fpm/pool.d/www.conf
fi

# php.ini general
sed -i 's/^max_execution_time = .*/max_execution_time = 60/' /etc/php/8.1/fpm/php.ini
sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 100M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' /etc/php/8.1/fpm/php.ini

# OPcache (Caché de bytecode en RAM)
sed -i 's/^;opcache.enable=.*/opcache.enable=1/' /etc/php/8.1/fpm/php.ini
sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' /etc/php/8.1/fpm/php.ini
sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/' /etc/php/8.1/fpm/php.ini
sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=2/' /etc/php/8.1/fpm/php.ini

# Reiniciar PHP-FPM para aplicar cambios
systemctl restart php8.1-fpm

# 8. Bootstrap Nginx (Puerto 80 temporal para resolver el reto HTTP de Certbot)
echo "Configurando bootstrap temporal de Nginx (Puerto 80)..."

cat << 'EOF' > /etc/nginx/sites-available/caelitandem.lat
server {
    listen 80;
    listen [::]:80;
    server_name caelitandem.lat www.caelitandem.lat;
    root /home/ubuntu/sitios_2026/caelitandem-home;
    index index.html index.htm;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

cat << 'EOF' > /etc/nginx/sites-available/n8n.caelitandem.lat
server {
    listen 80;
    server_name n8n.caelitandem.lat;
    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Crear enlaces simbólicos para activar configuraciones
ln -sf /etc/nginx/sites-available/caelitandem.lat /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/n8n.caelitandem.lat /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Reiniciar Nginx en modo bootstrap
systemctl restart nginx

# 9. Pre-crear archivos de seguridad SSL de Let's Encrypt para evitar fallos de sintaxis en Nginx
echo "Asegurando la presencia de las configuraciones de seguridad SSL..."
if [ ! -d /etc/letsencrypt ]; then
    mkdir -p /etc/letsencrypt
fi

cat << 'EOF' > /etc/letsencrypt/options-ssl-nginx.conf
# Configuración segura de SSL provista originalmente por Certbot
ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
EOF

if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
    echo "Generando parámetros Diffie-Hellman seguros de 2048 bits (este paso puede tardar)..."
    openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
fi

# 10. Obtención interactiva de certificados SSL con Certbot
echo ""
echo "========================================================================="
echo " SOLICITUD DE CERTIFICADOS LET'S ENCRYPT"
echo "========================================================================="
echo "Los DNS de caelitandem.lat, www.caelitandem.lat y n8n.caelitandem.lat"
echo "deben estar apuntando a la IP de este servidor antes de continuar."
echo ""
read -p "Introduce el correo electrónico para el registro: " EMAIL
if [ -z "$EMAIL" ]; then
    EMAIL="admin@caelitandem.lat"
fi

echo "Generando certificado SSL para caelitandem.lat y www.caelitandem.lat..."
certbot certonly --nginx --agree-tos --no-eff-email --email "$EMAIL" -d caelitandem.lat -d www.caelitandem.lat

echo "Generando certificado SSL para n8n.caelitandem.lat..."
certbot certonly --nginx --agree-tos --no-eff-email --email "$EMAIL" -d n8n.caelitandem.lat

# 11. Despliegue de Configuraciones Finales de Nginx con SSL y Ruteo
echo "Instalando vhosts finales con soporte HTTPS completo..."

# Vhost caelitandem.lat definitivo
cat << 'EOF' > /etc/nginx/sites-available/caelitandem.lat
server {
    server_name caelitandem.lat www.caelitandem.lat;

    root /home/ubuntu/sitios_2026/caelitandem-home;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    # Ruta de prototipos interactivos con ruteo aislado de activos y PHP
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

    # Security headers
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip
    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 256;

    # Cache estáticos
    location ~* \.(css|js|png|jpg|jpeg|gif|svg|ico|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    access_log /var/log/nginx/caelitandem.lat-access.log;
    error_log  /var/log/nginx/caelitandem.lat-error.log;

    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/www.caelitandem.lat/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/www.caelitandem.lat/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.caelitandem.lat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    if ($host = caelitandem.lat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    listen [::]:80;
    server_name caelitandem.lat www.caelitandem.lat;
    return 301 https://www.caelitandem.lat$request_uri;
}
EOF

# Vhost n8n.caelitandem.lat definitivo
cat << 'EOF' > /etc/nginx/sites-available/n8n.caelitandem.lat
server {
    server_name n8n.caelitandem.lat;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location ~ \.php$ {
        root /home/ubuntu/n8n-php;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/n8n.caelitandem.lat/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/n8n.caelitandem.lat/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    # Agregar cabeceras de seguridad
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; connect-src 'self' https://api.n8n.io;" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;
}

server {
    if ($host = n8n.caelitandem.lat) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    server_name n8n.caelitandem.lat;
    return 404; # managed by Certbot
}
EOF

# 12. Validar sintaxis final y recargar Nginx
echo "Validando sintaxis de configuración de Nginx..."
nginx -t

echo "Recargando Nginx con la configuración de producción..."
systemctl reload nginx

echo -e "${GREEN}=== ¡Proceso finalizado con éxito! ===${NC}"
echo "Pruebas de acceso recomendadas:"
echo "1. https://www.caelitandem.lat/ (Contenido estático)"
echo "2. https://www.caelitandem.lat/mvps/info.php (Verificación de ejecución PHP y límites)"
echo "3. https://n8n.caelitandem.lat/ (Verificación de n8n por proxy-pass)"
