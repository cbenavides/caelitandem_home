#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_import_sql.py [DEPRECADO / RETIRADO]

ADVERTENCIA: Este script legado ha sido retirado y reemplazado por:
    import_catalogo_estudios.py

Motivos de deprecación técnica:
1. Referenciaba la tabla plana 'cat_categorias' y la columna 'categoria_id', las cuales
   fueron formalmente eliminadas en la migración m010 en favor de la taxonomía unificada
   (cat_gabinetes, cat_subgabinetes y rel_estudio_gabinete).
2. Ejecutaba TRUNCATE destructivo sobre cat_estudios, incompatible con actualizaciones incrementales
   como los 20 estudios más solicitados (top20_orden).
3. No compilaba las cachés de la webapp (catalog-compiled.js).

Este archivo actúa como un redirector / shim de compatibilidad hacia import_catalogo_estudios.py.
"""

import sys
import os
import subprocess
import warnings

warnings.warn(
    "generate_import_sql.py está deprecado. Use import_catalogo_estudios.py en su lugar.",
    DeprecationWarning,
    stacklevel=2
)

target_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "import_catalogo_estudios.py")
if os.path.exists(target_script):
    cmd = [sys.executable, target_script] + sys.argv[1:]
    sys.exit(subprocess.call(cmd))
else:
    sys.exit("ERROR: No se encontró import_catalogo_estudios.py.")
