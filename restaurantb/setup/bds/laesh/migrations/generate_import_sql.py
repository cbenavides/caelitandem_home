import pandas as pd
import math

file_path = "/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/v1.2/insumos-laesh/04-septiembre/LISTA 2026 PAGINA BUENAS (1).xlsx"
out_sql = "/home/carlos/GitHub/caelitandem_home/restaurantb/setup/bds/laesh/migrations/import_ssot.sql"

df = pd.read_excel(file_path)

# Filter empty groups
df = df.dropna(subset=['Grupo o area de proceso'])
df = df[df['Grupo o area de proceso'].astype(str).str.strip() != '']

# Fill NA with empty string
df = df.fillna('')

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
    if not val:
        return ''
    s = str(val).strip()
    # Prevenir agrupaciones sintéticas con diagonales (ej. 'Perfil Bioquímico 15/24/30/35/45')
    if '15/24' in s or '15/24/30' in s:
        s = s.replace('15/24/30/35/45', '15 ELEMENTOS').replace('15/24', '15 ELEMENTOS')
    return s.replace("'", "''")

with open(out_sql, 'w', encoding='utf-8') as f:
    f.write("USE laesh_db;\n\n")
    f.write("SET FOREIGN_KEY_CHECKS = 0;\n")
    f.write("TRUNCATE TABLE cat_estudios;\n")
    f.write("TRUNCATE TABLE cat_categorias;\n")
    f.write("SET FOREIGN_KEY_CHECKS = 1;\n\n")

    categories = df['Grupo o area de proceso'].unique()
    cat_map = {}
    
    cat_id = 1
    for cat in categories:
        cat_clean = str(cat).replace("'", "''").strip()
        f.write(f"INSERT INTO cat_categorias (id, nombre, orden) VALUES ({cat_id}, '{cat_clean}', {cat_id});\n")
        cat_map[str(cat).strip()] = cat_id
        cat_id += 1
        
    f.write("\n")
    
    for idx, row in df.iterrows():
        cat_name = str(row['Grupo o area de proceso']).strip()
        c_id = cat_map[cat_name]
        
        clave = clean_num_str(row.get('Clave', ''))
        clave = clave.replace("'", "''")
        
        nombre_raw = str(row.get('Nombre', ''))
        nombre = clean_nombre(nombre_raw)
        
        tipo_muestra = str(row.get('TipoMuestra', '')).replace("'", "''").strip()
        contenedor = str(row.get('contenedor', '')).replace("'", "''").strip()
        
        # Exact column name 'Tiempo/Días '
        tiempo = clean_num_str(row.get('Tiempo/Días ', '')).replace("'", "''")
        preparacion = str(row.get('Indicaciones o preparacion', '')).replace("'", "''").strip()
        pruebas = str(row.get('Pruebas incluidas en el perfil', '')).replace("'", "''").strip()
        
        if not nombre:
            continue
            
        f.write(f"INSERT INTO cat_estudios (categoria_id, clave, nombre, descripcion_breve, tiempo, muestra, contenedor, preparacion, pruebas_incluidas, activo) ")
        f.write(f"VALUES ({c_id}, '{clave}', '{nombre}', '', '{tiempo}', '{tipo_muestra}', '{contenedor}', '{preparacion}', '{pruebas}', 1);\n")
        
    f.write("\n-- EOF\n")
