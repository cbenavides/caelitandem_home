#!/usr/bin/env bash
# Script conveniente para compilar todos los documentos PDF del contrato LAESH
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 "$DIR/build_pdf.py" "$@"
