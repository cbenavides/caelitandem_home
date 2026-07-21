#!/usr/bin/env bash
# Script para compilar diagramas Mermaid (.mmd) a PNG HD
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎨 Compilando diagramas Mermaid (.mmd ➔ .png HD)..."

compile_mmd() {
    local input_name="$1"
    local output_name="$2"
    
    if [ -f "$DIR/$input_name" ]; then
        echo "  ➜ $input_name ➔ $output_name"
        npx -y @mermaid-js/mermaid-cli \
            -i "$DIR/$input_name" \
            -o "$DIR/$output_name" \
            -w 2400 -H 1600 -b white \
            -C "$DIR/custom-mermaid.css" \
            -c "$DIR/p-config.json" >/dev/null 2>&1
    fi
}

compile_mmd "diag1.mmd" "Diagrama_1_Emision_HD.png"
compile_mmd "diag2.mmd" "Diagrama_2_Recepcion_HD.png"
compile_mmd "diag3.mmd" "Diagrama_3_Resultados_HD.png"
compile_mmd "diag4_flujo1.mmd" "Diagrama_4_Flujo1_HD.png"
compile_mmd "diag5_flujo2.mmd" "Diagrama_5_Flujo2_HD.png"
compile_mmd "diag6_flujo3.mmd" "Diagrama_6_Flujo3_HD.png"

echo "✅ Diagramas compilados exitosamente en: $DIR/"
