#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
import_catalogo_estudios.py — Script Maestro Unificado de Importación y Actualización de Catálogos LAESH

Reglas de Negocio y Arquitectura SSOT (Post-Migración m010):
1. MATCH POR CLAVE Y NOMBRE (Modo top20):
   Para el archivo '20 estudios mas solicitados (1).xlsx', SOLO se utiliza 'Clave' y 'Nombre' para
   localizar el estudio existente en el catálogo maestro de la BD (cat_estudios). NO se insertan registros
   huérfanos ni se realiza TRUNCATE; únicamente se actualiza 'top20_orden' (1..20), metadatos analíticos y
   la secuencia jerárquica en rel_estudio_gabinete.
2. REGLA DE AGRUPACIONES SINTÉTICAS CON DIAGONALES (clean_nombre):
   Previene agrupaciones compuestas en el nombre (ej. 'Perfil Bioquímico 15/24/30/35/45' -> '15 ELEMENTOS').
3. REGLA DE PRUEBAS INCLUIDAS (format_pruebas_incluidas):
   Convierte los analitos separados por comas fuera de paréntesis en saltos de línea ('\n'). De este modo,
   al compilar la webapp con CatalogBuilder::build(), explode('\n') genera un array de elementos
   individuales para la interfaz en vez de un solo bloque apelmazado.
4. REGLA DE NULOS (clean_num_str / normalize_text):
   Sanea nulos (NaN/None) y elimina sufijos flotantes (.0) en claves y tiempos.
5. TAXONOMÍA RELACIONAL (strip_accents / resolve_gabinete):
   Mapea 'Grupo o area de proceso' directamente a cat_gabinetes (1..14) y rel_estudio_gabinete.

Uso:
    python3 import_catalogo_estudios.py --mode=top20 [--dry-run]
    python3 import_catalogo_estudios.py --mode=top20 --apply --build-cache
    python3 import_catalogo_estudios.py --mode=full --file="/ruta/a/catalogo_general.xlsx"
    python3 import_catalogo_estudios.py --mode=build-cache
"""

import sys
import os
import re
import argparse
import subprocess
import shutil
import unicodedata

try:
    import pandas as pd
except ImportError:
    print("ERROR: pandas no está instalado. Ejecute: pip install pandas openpyxl", file=sys.stderr)
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MIGRATIONS_DIR = SCRIPT_DIR
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../../../.."))

DEFAULT_TOP20_EXCEL = "/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/v1.2/insumos-laesh/22sep/20 estudios mas solicitados (1).xlsx"
DEFAULT_FULL_EXCEL = "/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/v1.2/insumos-laesh/04-septiembre/LISTA 2026 PAGINA BUENAS (1).xlsx"

# Diccionario Oficial de Gabinetes
GABINETES = {
    1: 'Hematología',
    2: 'Química Clínica',
    3: 'Bacteriología',
    4: 'Coagulación',
    5: 'Inmunología',
    6: 'Uroanálisis',
    7: 'Endocrinología',
    8: 'Marcadores Tumorales',
    9: 'Gasometría Arterial y Venosa',
    10: 'Citoquímicos',
    11: 'Reumatología y Autoinmunidad',
    12: 'Parasitología',
    13: 'Biología Molecular',
    14: 'Diversos'
}

ALIAS_CLEAN_MAP = {
    'hematologia': 1,
    'bioquimica clinica': 2,
    'quimica clinica': 2,
    'bioquimica': 2,
    'quimica': 2,
    'hplc': 2,
    'bacteriologia': 3,
    'microbiologia': 3,
    'coagulacion': 4,
    'inmunologia': 5,
    'inmuno-endocrinologia': 5,
    'inmuno endocrinologia': 5,
    'endocrinologia': 7,
    'uroanalisis': 6,
    'urianalisis': 6,
    'orina': 6,
    'marcadores tumorales': 8,
    'marcador tumoral': 8,
    'gasometria arterial y venosa': 9,
    'gasometria arterial': 9,
    'gasometria': 9,
    'citoquimicos': 10,
    'reumatologia y autoinmunidad': 11,
    'reumatologia': 11,
    'parasitologia': 12,
    'biologia molecular': 13,
    'diversos': 14,
    'general': 14
}

def strip_accents(text):
    if not text:
        return ''
    return ''.join(c for c in unicodedata.normalize('NFD', str(text)) if unicodedata.category(c) != 'Mn').lower().strip()

def normalize_text(text):
    if text is None or (isinstance(text, float) and pd.isna(text)):
        return ''
    return str(text).strip()

def clean_sql_str(val):
    if val is None:
        return ''
    return str(val).strip().replace("'", "''")

def clean_num_str(val):
    if val is None or pd.isna(val):
        return ''
    s = str(val).strip()
    if s.endswith('.0'):
        try:
            return str(int(float(s)))
        except ValueError:
            pass
    return s

def clean_nombre(val):
    """Previene agrupaciones sintéticas con diagonales heredadas de generate_import_sql.py"""
    if not val:
        return ''
    s = str(val).strip()
    if '15/24' in s or '15/24/30' in s:
        s = s.replace('15/24/30/35/45', '15 ELEMENTOS').replace('15/24', '15 ELEMENTOS')
    return s.strip()

def format_pruebas_incluidas(val):
    """
    Normaliza la columna de pruebas incluidas dividiendo los analitos separados por comas
    o punto y coma (respetando comas dentro de paréntesis) para convertirlos a saltos de línea.
    Esto permite que CatalogBuilder::build() genere un array JSON de elementos individuales en la webapp.
    """
    if not val or pd.isna(val):
        return ''
    s = str(val).strip()
    if not s:
        return ''
    if chr(10) in s:
        items = [x.strip() for x in s.split(chr(10)) if x.strip() and x.strip() not in [',', ';']]
        return chr(10).join(items)

    # Dividir por coma o punto y coma que NO esté dentro de paréntesis
    items = re.split(r',(?![^(]*\))|;\s*', s)
    items = [x.strip().rstrip('.,;') for x in items if x.strip()]
    return chr(10).join(items)

def resolve_gabinete(area_str):
    raw = strip_accents(area_str)
    return ALIAS_CLEAN_MAP.get(raw, 14)

def find_header_row(file_path):
    df_raw = pd.read_excel(file_path, header=None, nrows=10)
    for idx, row in df_raw.iterrows():
        row_strs = [str(x).strip().lower() for x in row.values if pd.notna(x)]
        if 'clave' in row_strs and 'nombre' in row_strs:
            return idx
    return 0

def process_top20(excel_path):
    print(f"[*] Procesando archivo Top 20: {excel_path}")
    header_idx = find_header_row(excel_path)
    df = pd.read_excel(excel_path, header=header_idx)
    cols = {str(c).strip().lower(): c for c in df.columns}
    col_clave = cols.get('clave')
    col_nombre = cols.get('nombre')
    col_muestra = cols.get('tipomuestra') or cols.get('muestra')
    col_contenedor = cols.get('contenedor')
    col_tiempo = next((c for c in df.columns if 'tiempo' in str(c).lower()), None)
    col_area = next((c for c in df.columns if 'grupo' in str(c).lower() or 'area' in str(c).lower()), None)
    col_prep = next((c for c in df.columns if 'indicacion' in str(c).lower() or 'preparacion' in str(c).lower()), None)
    col_pruebas = next((c for c in df.columns if 'pruebas' in str(c).lower()), None)
    col_orden = next((c for c in df.columns if 'orden' in str(c).lower() or str(c).strip().lower() in ['unnamed: 1', 'no', 'num', '#']), None)
    if col_orden is None and len(df.columns) > 1:
        col_orden = df.columns[1]

    studies = []
    for idx, row in df.iterrows():
        raw_orden = row.get(col_orden) if col_orden else (idx + 1)
        try:
            orden = int(float(raw_orden))
        except (ValueError, TypeError):
            orden = idx + 1

        clave = clean_num_str(row.get(col_clave, ''))
        nombre_raw = normalize_text(row.get(col_nombre, ''))
        nombre = clean_nombre(nombre_raw)
        if not nombre or not clave:
            continue

        muestra = normalize_text(row.get(col_muestra, ''))
        contenedor = normalize_text(row.get(col_contenedor, ''))
        tiempo = clean_num_str(row.get(col_tiempo, '')) if col_tiempo else ''
        area = normalize_text(row.get(col_area, '')) if col_area else ''
        prep = normalize_text(row.get(col_prep, '')) if col_prep else ''
        raw_pruebas = normalize_text(row.get(col_pruebas, '')) if col_pruebas else ''
        pruebas_formateadas = format_pruebas_incluidas(raw_pruebas)
        gab_id = resolve_gabinete(area)

        studies.append({
            'orden': orden,
            'clave': clave,
            'nombre': nombre,
            'muestra': muestra,
            'contenedor': contenedor,
            'tiempo': tiempo,
            'area': area,
            'gab_id': gab_id,
            'prep': prep,
            'pruebas': pruebas_formateadas,
            'pruebas_count': len(pruebas_formateadas.split(chr(10))) if pruebas_formateadas else 0
        })

    studies.sort(key=lambda x: x['orden'])
    print(f"[+] Total de estudios Top 20 parseados: {len(studies)}")
    return studies

def generate_top20_sql(studies):
    """
    Genera sentencias SQL de UPDATE puro para los 20 estudios más solicitados.
    REGLA: SOLO utiliza 'Clave' y 'Nombre' para hacer el MATCH sobre el catálogo existente en cat_estudios.
    No realiza INSERT ni TRUNCATE destructivo.
    """
    sql_lines = [
        '-- ===========================================================================',
        '-- import_top20.sql — Actualización de los 20 Estudios Más Solicitados (SSOT)',
        '-- Generado por import_catalogo_estudios.py (Post-Refactor m010)',
        '-- REGLA: Match estricto en catálogo existente por CLAVE y NOMBRE (CERO INSERT)',
        '-- ===========================================================================',
        'USE laesh_db;',
        'SET FOREIGN_KEY_CHECKS = 0;',
        '-- 1. Resetear asignaciones previas de Top 20 para evitar duplicados',
        'UPDATE cat_estudios SET top20_orden = NULL WHERE top20_orden IS NOT NULL;',
        ''
    ]

    for s in studies:
        clave_sql = clean_sql_str(s['clave'])
        nombre_sql = clean_sql_str(s['nombre'])
        muestra_sql = clean_sql_str(s['muestra'])
        cont_sql = clean_sql_str(s['contenedor'])
        tiempo_sql = clean_sql_str(s['tiempo'])
        prep_sql = clean_sql_str(s['prep'])
        # Escapar saltos de línea para el literal SQL en MariaDB
        pruebas_sql = clean_sql_str(s['pruebas']).replace(chr(10), '\\n')
        orden = s['orden']
        gab_id = s['gab_id']
        area_nombre = GABINETES.get(gab_id, 'Diversos')

        sql_lines.append(f"-- Top {orden:02d}: {s['nombre']} (Clave: {s['clave']}) | Match por Clave y Nombre")
        sql_lines.append(f"""UPDATE cat_estudios
   SET top20_orden       = {orden},
       muestra           = COALESCE(NULLIF('{muestra_sql}', ''), muestra),
       contenedor        = COALESCE(NULLIF('{cont_sql}', ''), contenedor),
       tiempo            = COALESCE(NULLIF('{tiempo_sql}', ''), tiempo),
       preparacion       = COALESCE(NULLIF('{prep_sql}', ''), preparacion),
       pruebas_incluidas = COALESCE(NULLIF('{pruebas_sql}', ''), pruebas_incluidas),
       updated_at        = NOW()
 WHERE clave = '{clave_sql}'
   AND (LOWER(TRIM(nombre)) = LOWER(TRIM('{nombre_sql}'))
        OR LOWER(TRIM('{nombre_sql}')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
        OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('{nombre_sql}')), '%'));""")

        # Sincronizar orden jerárquico en rel_estudio_gabinete
        sql_lines.append(f"""UPDATE rel_estudio_gabinete
   SET orden = {orden}
 WHERE estudio_id = (
     SELECT id FROM cat_estudios
      WHERE clave = '{clave_sql}'
        AND (LOWER(TRIM(nombre)) = LOWER(TRIM('{nombre_sql}'))
             OR LOWER(TRIM('{nombre_sql}')) LIKE CONCAT(LOWER(TRIM(nombre)), '%')
             OR LOWER(TRIM(nombre)) LIKE CONCAT(LOWER(TRIM('{nombre_sql}')), '%'))
      LIMIT 1
 );""")
        sql_lines.append('')

    sql_lines.append('SET FOREIGN_KEY_CHECKS = 1;')
    sql_lines.append('-- Validar Top 20 asignado en el catálogo')
    sql_lines.append('SELECT id, clave, nombre, top20_orden, activo FROM cat_estudios WHERE top20_orden IS NOT NULL ORDER BY top20_orden ASC;')
    return chr(10).join(sql_lines)

def process_full_catalog(excel_path):
    print(f"[*] Procesando Catálogo General Maestro: {excel_path}")
    header_idx = find_header_row(excel_path)
    df = pd.read_excel(excel_path, header=header_idx)
    df = df.dropna(subset=['Nombre']) if 'Nombre' in df.columns else df
    df = df.fillna('')
    cols = {str(c).strip().lower(): c for c in df.columns}
    col_clave = cols.get('clave')
    col_nombre = cols.get('nombre')
    col_muestra = cols.get('tipomuestra') or cols.get('muestra')
    col_contenedor = cols.get('contenedor')
    col_tiempo = next((c for c in df.columns if 'tiempo' in str(c).lower()), None)
    col_area = next((c for c in df.columns if 'grupo' in str(c).lower() or 'area' in str(c).lower()), None)
    col_prep = next((c for c in df.columns if 'indicacion' in str(c).lower() or 'preparacion' in str(c).lower()), None)
    col_pruebas = next((c for c in df.columns if 'pruebas' in str(c).lower()), None)

    studies = []
    for idx, row in df.iterrows():
        clave = clean_num_str(row.get(col_clave, ''))
        nombre_raw = normalize_text(row.get(col_nombre, ''))
        nombre = clean_nombre(nombre_raw)
        if not nombre:
            continue
        muestra = normalize_text(row.get(col_muestra, ''))
        contenedor = normalize_text(row.get(col_contenedor, ''))
        tiempo = clean_num_str(row.get(col_tiempo, '')) if col_tiempo else ''
        area = normalize_text(row.get(col_area, '')) if col_area else ''
        prep = normalize_text(row.get(col_prep, '')) if col_prep else ''
        raw_pruebas = normalize_text(row.get(col_pruebas, '')) if col_pruebas else ''
        pruebas_formateadas = format_pruebas_incluidas(raw_pruebas)
        gab_id = resolve_gabinete(area)

        studies.append({
            'clave': clave,
            'nombre': nombre,
            'muestra': muestra,
            'contenedor': contenedor,
            'tiempo': tiempo,
            'area': area,
            'gab_id': gab_id,
            'prep': prep,
            'pruebas': pruebas_formateadas
        })
    print(f"[+] Total de estudios en catálogo general: {len(studies)}")
    return studies

def generate_full_sql(studies):
    sql_lines = [
        '-- ===========================================================================',
        '-- import_ssot_catalogo.sql — Sembrado / Sincronización Masiva del Catálogo',
        '-- Modelo Normalizado SSOT (cat_estudios + rel_estudio_gabinete)',
        '-- ===========================================================================',
        'USE laesh_db;',
        'SET FOREIGN_KEY_CHECKS = 0;',
        ''
    ]
    for s in studies:
        clave_sql = clean_sql_str(s['clave'])
        nombre_sql = clean_sql_str(s['nombre'])
        muestra_sql = clean_sql_str(s['muestra'])
        cont_sql = clean_sql_str(s['contenedor'])
        tiempo_sql = clean_sql_str(s['tiempo'])
        prep_sql = clean_sql_str(s['prep'])
        pruebas_sql = clean_sql_str(s['pruebas']).replace(chr(10), '\\n')
        gab_id = s['gab_id']

        sql_lines.append(f"""INSERT INTO cat_estudios (
    clave, nombre, muestra, contenedor, tiempo, preparacion, pruebas_incluidas, activo, updated_at
) VALUES (
    '{clave_sql}', '{nombre_sql}', '{muestra_sql}', '{cont_sql}', '{tiempo_sql}', '{prep_sql}', '{pruebas_sql}', 1, NOW()
) ON DUPLICATE KEY UPDATE
    nombre            = VALUES(nombre),
    muestra           = VALUES(muestra),
    contenedor        = VALUES(contenedor),
    tiempo            = VALUES(tiempo),
    preparacion       = VALUES(preparacion),
    pruebas_incluidas = VALUES(pruebas_incluidas),
    activo            = 1,
    updated_at        = NOW();

INSERT INTO rel_estudio_gabinete (estudio_id, gabinete_id, subgabinete_id, orden)
SELECT id, {gab_id}, NULL, 999
  FROM cat_estudios
 WHERE clave = '{clave_sql}'
ON DUPLICATE KEY UPDATE
    gabinete_id = VALUES(gabinete_id);
""")
        sql_lines.append('')
    sql_lines.append('SET FOREIGN_KEY_CHECKS = 1;')
    sql_lines.append("SELECT 'Operacion completada exitosamente';")
    return chr(10).join(sql_lines)

def run_catalog_builder():
    print("[*] Recompilando caché del catálogo (CatalogBuilder::build)... ")
    php_candidates = [shutil.which('php8.3'), shutil.which('php'), '/usr/bin/php8.3', '/usr/bin/php']
    php_bin = next((p for p in php_candidates if p and os.path.exists(p)), None)
    if not php_bin:
        print("[!] No se encontró binario de PHP para ejecutar CatalogBuilder.", file=sys.stderr)
        return False
    builder_candidates = [
        os.path.join(REPO_ROOT, "restaurantb/www/laesh-swbldi/commons/commons.php"),
        "/opt/laesh/www/laesh-swbldi/commons/commons.php",
        "/var/www/html/laesh-swbldi/commons/commons.php"
    ]
    commons_path = next((p for p in builder_candidates if os.path.exists(p)), None)
    if not commons_path:
        print("[!] No se encontró commons.php en rutas estándar.", file=sys.stderr)
        return False
    php_code = f"require_once '{commons_path}'; \Common\CatalogBuilder::build(null, 'Importación CLI');"
    try:
        res = subprocess.run([php_bin, "-r", php_code], capture_output=True, text=True, timeout=30)
        output = res.stdout.strip()
        print("[+] Catálogo recompilado (catalog-compiled.js).")
        return True
    except Exception as e:
        print(f"[!] Error al invocar CatalogBuilder: {e}", file=sys.stderr)
        return False

def apply_sql(sql_content):
    print("[*] Aplicando cambios directamente en MariaDB laesh_db...")
    cnf_candidates = ["/opt/laesh/configs/.mariadb-root.cnf", os.path.expanduser("~/.my.cnf")]
    cnf_file = next((f for f in cnf_candidates if os.path.exists(f)), None)
    cmd = None
    if cnf_file:
        cmd = ["mysql", f"--defaults-extra-file={cnf_file}", "laesh_db"]
    elif shutil.which("mysql"):
        cmd = ["mysql", "-h", "127.0.0.1", "-u", "laesh_app", "-plaesh_2026_dev", "laesh_db"]
    if not cmd or not shutil.which(cmd[0]):
        print("[!] No se encontró cliente mysql o archivo .cnf para aplicar automáticamente.", file=sys.stderr)
        print("[i] Puede ejecutar el script SQL generado con: mariadb laesh_db < <archivo.sql>")
        return False
    try:
        proc = subprocess.run(cmd, input=sql_content, text=True, capture_output=True, timeout=60)
        if proc.returncode == 0:
            print("[+] Sentencias SQL ejecutadas exitosamente en MariaDB laesh_db.")
            return True
        else:
            print(f"[!] Error al ejecutar en MariaDB: {proc.stderr}", file=sys.stderr)
            return False
    except Exception as e:
        print(f"[!] Excepción al ejecutar MySQL: {e}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description='Importador Maestro de Catálogo de Estudios LAESH (Post-m010)')
    parser.add_argument('--mode', choices=['top20', 'full', 'seed', 'build-cache'], default='top20',
                        help="Modo de ejecución: 'top20' (default, match por Clave y Nombre), 'full' / 'seed', o 'build-cache'")
    parser.add_argument('--file', help='Ruta al archivo Excel insumo (opcional, usa defaults según modo)')
    parser.add_argument('--output', help='Ruta de guardado para el archivo SQL resultante')
    parser.add_argument('--apply', action='store_true', help='Aplica el SQL directamente a MariaDB laesh_db')
    parser.add_argument('--build-cache', dest='build_cache', action='store_true',
                        help='Compila catalog-compiled.js tras aplicar las modificaciones')
    parser.add_argument('--dry-run', action='store_true', help='Inspecciona y valida el insumo sin escribir')
    args = parser.parse_args()

    if args.mode == 'build-cache':
        success = run_catalog_builder()
        sys.exit(0 if success else 1)

    if args.mode == 'top20':
        excel_path = args.file or DEFAULT_TOP20_EXCEL
        if not os.path.exists(excel_path):
            print(f"ERROR: Archivo no encontrado: {excel_path}", file=sys.stderr)
            sys.exit(1)
        studies = process_top20(excel_path)
        if args.dry_run:
            print("\n[DRY RUN] Validación de los 20 Estudios Más Solicitados (Match Clave y Nombre):")
            for s in studies:
                g_nom = GABINETES.get(s['gab_id'], 'Diversos')
                p_info = f"{s['pruebas_count']} analitos" if s['pruebas_count'] > 0 else 'Sin desglose'
                print(f"  #{s['orden']:02d} | Clave: {s['clave']:<6} | Gabinete: {s['gab_id']:<2} ({g_nom:<25}) | Pruebas: {p_info:<12} | Nombre: {s['nombre']}")
            print("\n[DRY RUN] Finalizado con éxito. Sin cambios aplicados.")
            return
        sql_content = generate_top20_sql(studies)
        out_sql = args.output or os.path.join(MIGRATIONS_DIR, 'import_top20.sql')
    else:
        excel_path = args.file or DEFAULT_FULL_EXCEL
        if not os.path.exists(excel_path):
            print(f"ERROR: Archivo no encontrado: {excel_path}", file=sys.stderr)
            sys.exit(1)
        studies = process_full_catalog(excel_path)
        if args.dry_run:
            print(f"\n[DRY RUN] {len(studies)} estudios parseados. Primeros 5:")
            for s in studies[:5]:
                print(f"  Clave: {s['clave']:<6} | Área: {s['area']} -> Gabinete {s['gab_id']} | Nombre: {s['nombre']}")
            return
        sql_content = generate_full_sql(studies)
        out_sql = args.output or os.path.join(MIGRATIONS_DIR, 'import_ssot_catalogo.sql')

    with open(out_sql, 'w', encoding='utf-8') as f:
        f.write(sql_content)
    print(f"[+] Archivo SQL generado exitosamente: {out_sql}")

    applied = False
    if args.apply:
        applied = apply_sql(sql_content)

    if args.build_cache or (args.apply and applied):
        run_catalog_builder()

    print("[✔] Operación completada con éxito.")

if __name__ == '__main__':
    main()
