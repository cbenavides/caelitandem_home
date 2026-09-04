#!/bin/bash
# Instalador Idempotente de Stack: Nginx, MariaDB 11, PHP-FPM 8.3 + Swoole Systemd

# ==========================================
# VARIABLES DE CONFIGURACIÓN
# ==========================================
DB_ROOT_PASS="laesh-bd2026"
LOGFILE="/var/log/stack_setup.log"

# Funciones de Logging
log_info() { echo -e "[\e[34mINFO\e[0m] $(date +'%T') - $1" | tee -a "$LOGFILE"; }
log_success() { echo -e "[\e[32mEXITO\e[0m] $(date +'%T') - $1" | tee -a "$LOGFILE"; }
log_error() { echo -e "[\e[31mERROR\e[0m] $(date +'%T') - $1" | tee -a "$LOGFILE"; }

log_info "Iniciando despliegue idempotente del stack..."

# 1. Repositorios y Paquetes Base
if ! dpkg -l | grep -q php8.3-fpm; then
    log_info "Instalando Nginx, MariaDB y núcleo PHP 8.3..."
    apt-get update -y >> "$LOGFILE" 2>&1
    apt-get install software-properties-common -y >> "$LOGFILE" 2>&1
    add-apt-repository ppa:ondrej/php -y >> "$LOGFILE" 2>&1
    apt-get update -y >> "$LOGFILE" 2>&1
    apt-get install nginx mariadb-server php8.3-fpm php8.3-mysql php8.3-dev -y >> "$LOGFILE" 2>&1
else
    log_success "Paquetes base ya instalados. Omitiendo."
fi

# 1.1 Configurar Contraseña de root en MariaDB
log_info "Asegurando credenciales de MariaDB..."
# Utiliza el socket de Unix por defecto para inyectar la contraseña sin pedir prompt
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}'; FLUSH PRIVILEGES;" >> "$LOGFILE" 2>&1
log_success "Contraseña de root de MariaDB configurada."

# 2. Compilación de Swoole
if ! php -m | grep -q -i swoole; then
    log_info "Compilando extensión nativa Swoole vía PECL..."
    pecl install swoole >> "$LOGFILE" 2>&1
    echo "extension=swoole.so" > /etc/php/8.3/cli/conf.d/20-swoole.ini
    echo "extension=swoole.so" > /etc/php/8.3/fpm/conf.d/20-swoole.ini
    systemctl restart php8.3-fpm >> "$LOGFILE" 2>&1
    log_success "Swoole compilado y habilitado exitosamente."
else
    log_success "Swoole ya se encuentra integrado en PHP."
fi

# 3. Configuración del Estado Deseado para Nginx
log_info "Forzando estado de configuración en Nginx..."
cat << 'EOF' > /etc/nginx/sites-available/webapp
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html;

    # Proxy inverso para WebSockets Swoole
    location /ws/ {
        proxy_pass http://127.0.0.1:9501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }

    # Interoperabilidad PHP-FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

if nginx -t >> "$LOGFILE" 2>&1; then
    systemctl reload nginx
    log_success "Bloque de Nginx recargado."
else
    log_error "Fallo sintáctico en Nginx."
fi

# 4. Archivo de Prueba de Interoperabilidad (Usando la variable de password)
cat << EOF > /var/www/html/test_db.php
<?php
try {
    \$pdo = new PDO('mysql:host=localhost', 'root', '${DB_ROOT_PASS}');
    echo "INTEGRACION_OK";
} catch (PDOException \$e) { echo "ERROR_DB: " . \$e->getMessage(); }
EOF
chown -R www-data:www-data /var/www/html/test_db.php

# 5. Demonio Systemd para Swoole
log_info "Validando servicio perpetuo de Swoole..."
cat << 'EOF' > /var/www/html/ws_server.php
<?php
$server = new Swoole\WebSocket\Server("127.0.0.1", 9501);
$server->on("start", function ($server) { echo "Swoole OK\n"; });
$server->on("message", function($server, $frame) { $server->push($frame->fd, "WS_OK"); });
$server->start();
EOF

chown -R sysadmin:sysadmin /var/www/html/ws_server.php

cat << 'EOF' > /etc/systemd/system/swoole-websocket.service
[Unit]
Description=Swoole WebSocket Server
After=network.target mariadb.service php8.3-fpm.service

[Service]
Type=simple
User=sysadmin
Group=sysadmin
ExecStart=/usr/bin/php8.3 /var/www/html/ws_server.php
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >> "$LOGFILE" 2>&1
systemctl enable --now swoole-websocket >> "$LOGFILE" 2>&1

# 6. Verificación Final en Vivo
TEST_RESULT=$(curl -s http://localhost/test_db.php)
if [[ "$TEST_RESULT" == *"INTEGRACION_OK"* ]] && systemctl is-active --quiet swoole-websocket; then
    log_success "Ejecución idempotente exitosa: Stack operando al 100%."
else
    log_error "Hay problemas en la interoperabilidad del stack final. Respuesta: $TEST_RESULT"
fi