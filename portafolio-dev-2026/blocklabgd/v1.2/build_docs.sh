#!/usr/bin/env bash
# Script de compilación de Documentos LAESH
# Flujo: .mmd ➔ .png HD ➔ .md ➔ .html ➔ .pdf
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="/tmp/laesh_build"
mkdir -p "$TMP_DIR"

# Si se pasa --diagrams o --all, recompila primero los diagramas Mermaid (.mmd ➔ .png HD)
if [[ "$*" == *"--diagrams"* ]] || [[ "$*" == *"--all"* ]]; then
    "$DIR/diagramas/build_diagrams.sh"
fi

# Compilación de los documentos PDF
python3 "$DIR/build_pdf.py" "$@"

# Renombrar a versión final (_v4) de forma segura (evita anidamientos _v4_v4)
for pdf in "$DIR"/*.pdf; do
    if [[ "$pdf" != *"_v4.pdf" ]] && [ -f "$pdf" ]; then
        mv "$pdf" "${pdf%.pdf}_v4.pdf"
    fi
done

# Si se ejecuta con ./build_docs.sh --debug, exporta los PNGs de prueba a /tmp
if [[ "$*" == *"--debug"* ]]; then
    for pdf in "$DIR"/*.pdf; do
        if [ -f "$pdf" ]; then
            name=$(basename "$pdf" .pdf)
            pdftoppm -png -r 150 "$pdf" "$TMP_DIR/${name}_page"
        fi
    done
    echo "🔍 PNGs de diagnóstico guardados en: $TMP_DIR/"
fi
