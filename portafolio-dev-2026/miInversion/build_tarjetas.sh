#!/usr/bin/env bash
# Script conveniente para compilar las tarjetas de presentación
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node /home/carlos/tools/pdf-renderer/pdf_render.js "$DIR/tarjetas_planilla.html" "$DIR/tarjetas_planilla.pdf"
echo "✅ PDF de tarjetas generado exitosamente: $DIR/tarjetas_planilla.pdf"
