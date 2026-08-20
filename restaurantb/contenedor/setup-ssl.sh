#!/bin/bash
# ==============================================================================
#  setup-ssl.sh — Automatización de Certificados HTTPS locales con mkcert
# ==============================================================================
#
# Este script se ejecuta en el HOST y automatiza todo el proceso de:
#   1. Detección dinámica de la IP local de red del host.
#   2. Verificación/Instalación de la CA local mediante mkcert.
#   3. Generación del certificado SSL en la carpeta ssl/ del host.
#   4. Copia del certificado de la CA raíz a la carpeta web para su descarga.
#   5. Reinicio del contenedor de Apache.
#

# Detener el script si ocurre algún error
set -e

# Asegurar que el script se ejecuta en el directorio 'contenedor'
cd "$(dirname "$0")"

echo "⚙️  Iniciando configuración de certificados locales HTTPS..."

# 1. Detectar la IP activa de la red local del host de forma dinámica
IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
if [ -z "$IP_LOCAL" ]; then
    IP_LOCAL=$(hostname -I | awk '{print $1}')
fi

if [ -z "$IP_LOCAL" ]; then
    echo "⚠️  No se pudo detectar la IP de red local. Usando fallback 127.0.0.1"
    IP_LOCAL="127.0.0.1"
else
    echo "🌐 IP local de red detectada: $IP_LOCAL"
fi

# 2. Localizar el ejecutable mkcert (global o local)
if command -v mkcert &> /dev/null; then
    MKCERT_CMD="mkcert"
elif [ -x "./mkcert" ]; then
    MKCERT_CMD="./mkcert"
else
    echo "❌ ERROR: 'mkcert' no está instalado en el sistema host ni se encontró un binario local en $(pwd)/mkcert."
    echo "👉 Para instalar mkcert ejecute:"
    echo "   sudo apt update && sudo apt install -y mkcert"
    echo "👉 O descargue el binario ejecutable directamente en esta carpeta con el nombre 'mkcert':"
    echo "   https://github.com/FiloSottile/mkcert/releases"
    exit 1
fi
echo "🔧 Usando binario mkcert: $MKCERT_CMD"

# 3. Asegurar la inicialización de la CA local
echo "🔑 Verificando / Inicializando la Autoridad Certificadora (CA) local..."
if ! $MKCERT_CMD -install; then
    echo "⚠️  Nota: No se pudo registrar la CA automáticamente en los almacenes del navegador del host (requiere sudo interactivo)."
    echo "   Esto es normal en entornos no interactivos de desarrollo. La CA de desarrollo ya ha sido creada."
fi

# 4. Asegurar que existe la carpeta de certificados ssl/ con permisos adecuados
mkdir -p ../ssl

# 5. Generar los certificados para la IP detectada y los orígenes locales
echo " Emitiendo certificados para: $IP_LOCAL, localhost, 127.0.0.1..."
$MKCERT_CMD -cert-file ../ssl/server.crt -key-file ../ssl/server.key "$IP_LOCAL" localhost 127.0.0.1

# Establecer permisos adecuados para que el contenedor pueda leerlos de forma segura
chmod 644 ../ssl/server.crt
chmod 600 ../ssl/server.key

# 6. Exponer la CA pública raíz en el directorio web (www/ca.crt) para descarga fácil en dispositivos clientes
CA_ROOT_PATH=$($MKCERT_CMD -CAROOT)/rootCA.pem
if [ -f "$CA_ROOT_PATH" ]; then
    echo "📦 Copiando CA raíz a la carpeta pública web..."
    cp "$CA_ROOT_PATH" ../www/ca.crt
    chmod 644 ../www/ca.crt
    echo "✅ CA raíz disponible para descarga por red en: http://$IP_LOCAL:6001/ca.crt"
else
    echo "⚠️  No se encontró la ruta de la CA raíz en: $CA_ROOT_PATH. No se copió la CA raíz."
fi

# 7. Reiniciar el contenedor web de Apache para cargar los nuevos certificados
if command -v docker &> /dev/null && docker compose ps &> /dev/null; then
    echo "🔄 Reiniciando contenedor Nginx para cargar los nuevos certificados..."
    docker compose restart nginx
    echo "✅ Nginx reiniciado con éxito."
else
    echo "⚠️  Docker o Docker Compose no están corriendo. Los certificados se aplicarán en el próximo inicio."
fi

echo "🎉 ¡Infraestructura SSL local configurada exitosamente!"
echo "👉 Visite: https://$IP_LOCAL:8443 en su navegador."
echo "👉 Registre el certificado 'ca.crt' en su dispositivo Android si planea usar el micrófono."
