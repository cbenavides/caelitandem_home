#!/usr/bin/env bash
# Script de compilación de Documentos LAESH
# Nota: Cualquier archivo temporal o PNG de diagnóstico se dirige a /tmp
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="/tmp/laesh_build"
mkdir -p "$TMP_DIR"

python3 "$DIR/build_pdf.py" "$@"

# Si se ejecuta con ./build_docs.sh --debug, exporta los PNGs de prueba a /tmp
if [[ "$1" == "--debug" ]]; then
    for pdf in "$DIR"/*.pdf; do
        if [ -f "$pdf" ]; then
            name=$(basename "$pdf" .pdf)
            pdftoppm -png -r 150 "$pdf" "$TMP_DIR/${name}_page"
        fi
    done
    echo "🔍 PNGs de diagnóstico guardados en: $TMP_DIR/"
fi
