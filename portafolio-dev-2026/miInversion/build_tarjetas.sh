#!/usr/bin/env bash
# Script de compilación de Tarjetas de Presentación
# Nota: Cualquier archivo temporal o PNG de diagnóstico se dirige a /tmp
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="/tmp/tarjetas_build"
mkdir -p "$TMP_DIR"

# Generación del PDF principal en la carpeta del proyecto
node /home/carlos/tools/pdf-renderer/pdf_render.js "$DIR/tarjetas_planilla.html" "$DIR/tarjetas_planilla.pdf"
echo "✅ PDF de tarjetas generado exitosamente: $DIR/tarjetas_planilla.pdf"

# Si se ejecuta con ./build_tarjetas.sh --debug, exporta los PNGs de prueba a /tmp
if [[ "$1" == "--debug" ]]; then
    pdftoppm -png -r 150 "$DIR/tarjetas_planilla.pdf" "$TMP_DIR/verify_page"
    echo "🔍 PNGs de diagnóstico guardados en: $TMP_DIR/"
fi
