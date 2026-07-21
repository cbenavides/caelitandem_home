#!/usr/bin/env bash
# Script de compilación de Tarjetas de Presentación (v1.2)
# Nota: Cualquier archivo temporal o PNG de diagnóstico se dirige a /tmp
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="/tmp/tarjetas_build"
mkdir -p "$TMP_DIR"

# Generación del PDF principal en la carpeta del proyecto
node /home/carlos/tools/pdf-renderer/pdf_render.js "$DIR/tarjetas_planilla1.2.html" "$DIR/tarjetas_planilla1.2.pdf"
echo "✅ PDF de tarjetas v1.2 generado exitosamente: $DIR/tarjetas_planilla1.2.pdf"

# Si se ejecuta con ./build_tarjetas1.2.sh --debug, exporta los PNGs de prueba a /tmp
if [[ "$*" == *"--debug"* ]]; then
    pdftoppm -png -r 150 "$DIR/tarjetas_planilla1.2.pdf" "$TMP_DIR/verify_page_v1.2"
    echo "🔍 PNGs de diagnóstico guardados en: $TMP_DIR/"
fi
