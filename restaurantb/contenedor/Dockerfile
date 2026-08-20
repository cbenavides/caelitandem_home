# ============================================================
#  Dockerfile — restaurantb / PHP-FPM
#  Base: php:8.3-fpm-alpine (imagen ligera, sin Apache)
#  Extensiones: pdo_mysql, gd, zip, bcmath, mbstring
#
#  Reemplaza: php:8.3-fpm + Apache (imagen anterior combinada)
#  El servidor web ahora es el contenedor nginx:alpine separado.
#  Autor: cbm 2026-08-19
# ============================================================
FROM php:8.3-fpm-alpine

LABEL maintainer="caelitandem_home"
LABEL description="PHP 8.3-FPM para restaurantb — sin Apache"

# ── 1. Dependencias del sistema ──────────────────────────────
RUN apk add --no-cache \
      libpng-dev \
      libjpeg-turbo-dev \
      freetype-dev \
      libzip-dev \
      oniguruma-dev \
      # bcmath no requiere libs externas en Alpine
      # mbstring necesita oniguruma-dev (ya incluido)
      # openssl ya incluido en imagen alpine base
      openssl

# ── 2. Extensiones PHP (mismas que imagen anterior) ──────────
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql \
        gd \
        zip \
        bcmath \
        mbstring

# ── 3. Configuración PHP ─────────────────────────────────────
# php-restaurantb.ini contiene todos los ajustes del proyecto
COPY conf/php-restaurantb.ini /usr/local/etc/php/conf.d/restaurantb.ini
# Pool PHP-FPM tuneado (sobreescribe www.conf por prefijo zz-)
COPY conf/php-fpm-pool.conf   /usr/local/etc/php-fpm.d/zz-restaurantb.conf

# ── 4. Entrypoint ligero ─────────────────────────────────────
# Crea el directorio de logs de la app y lanza php-fpm
COPY conf/docker-entrypoint-fpm.sh /usr/local/bin/docker-entrypoint-fpm.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-fpm.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-fpm.sh"]
CMD ["php-fpm"]
