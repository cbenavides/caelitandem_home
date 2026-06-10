# ============================================================
#  Dockerfile — restaurantb / Servicio Web
#  Base: PHP 8.3 + Apache (LTS estable, imagen oficial)
#  Extensiones: pdo_mysql, gd, zip, bcmath, mbstring
#  SSL:  certificado auto-firmado en /etc/ssl/restaurantb/
#        (ruta interna — independiente del volumen host ssl/)
# ============================================================
FROM php:8.3-apache

LABEL maintainer="caelitandem_home"
LABEL description="PHP 8.3 + Apache con SSL y extensiones para restaurantb"

# ── 1. Dependencias del sistema ──────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssl \
      libpng-dev \
      libjpeg-dev \
      libfreetype6-dev \
      libzip-dev \
      libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Extensiones PHP (se compilan y cachean en esta capa) ──
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql \
        gd \
        zip \
        bcmath \
        mbstring

# ── 3. Configuración PHP ─────────────────────────────────────
# Adaptada de opt-xampp7.4.33/php.ini (cbm 2026)
# Cada directiva documentada en conf/php-restaurantb.ini
COPY conf/php-restaurantb.ini /usr/local/etc/php/conf.d/restaurantb.ini

# ── 4. Módulos Apache ────────────────────────────────────────
# Adaptados de opt-xampp7.4.33/httpd.conf (cbm 2026)
RUN a2enmod ssl rewrite headers deflate

# ── 4b. Configuración Apache extra ───────────────────────────
# Adaptada de httpd.conf + httpd-xampp.conf (sin dirs Windows)
COPY conf/apache-restaurantb.conf /etc/apache2/conf-available/restaurantb.conf
RUN a2enconf restaurantb

# ── 5. VirtualHost SSL ───────────────────────────────────────
COPY conf/ssl-vhost.conf /etc/apache2/sites-available/restaurantb-ssl.conf
RUN a2ensite restaurantb-ssl

# ── 6. Certificado auto-firmado (ruta INTERNA — no colisiona
#       con el volumen bind-mount del host en /etc/apache2/ssl)
RUN mkdir -p /etc/ssl/restaurantb && chmod 700 /etc/ssl/restaurantb \
    && openssl req -x509 -nodes -days 730 -newkey rsa:2048 \
         -keyout /etc/ssl/restaurantb/server.key \
         -out    /etc/ssl/restaurantb/server.crt \
         -subj   '/C=MX/ST=Oaxaca/L=Local/O=Restaurantb/CN=localhost' \
    && chmod 600 /etc/ssl/restaurantb/server.key

# ── 7. Entrypoint: selecciona cert real (volumen) o fallback ─
COPY conf/docker-entrypoint-ssl.sh /usr/local/bin/docker-entrypoint-ssl.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-ssl.sh

EXPOSE 80 443

# El entrypoint inyecta el cert correcto y luego cede a
# docker-php-entrypoint (entrypoint original de la imagen base)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-ssl.sh"]
CMD ["apache2-foreground"]
