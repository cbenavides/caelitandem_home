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

with open(out_sql, 'w', encoding='utf-8') as f:
    f.write("USE laesh_db;\n\n")
    f.write("SET FOREIGN_KEY_CHECKS = 0;\n")
    f.write("TRUNCATE TABLE catalogo_estudios;\n")
    f.write("TRUNCATE TABLE catalogo_categorias;\n")
    f.write("TRUNCATE TABLE catalogo_grupos;\n")
    f.write("SET FOREIGN_KEY_CHECKS = 1;\n\n")

    f.write("INSERT INTO catalogo_grupos (id, clave, titulo, orden) VALUES (1, 'G1', 'Catálogo General 2026', 1);\n\n")

    categories = df['Grupo o area de proceso'].unique()
    cat_map = {}
    
    cat_id = 1
    for cat in categories:
        cat_clean = str(cat).replace("'", "''").strip()
        f.write(f"INSERT INTO catalogo_categorias (id, grupo_id, nombre, orden) VALUES ({cat_id}, 1, '{cat_clean}', {cat_id});\n")
        cat_map[str(cat).strip()] = cat_id
        cat_id += 1
        
    f.write("\n")
    
    for idx, row in df.iterrows():
        cat_name = str(row['Grupo o area de proceso']).strip()
        c_id = cat_map[cat_name]
        
        clave = str(row.get('Clave', '')).replace("'", "''").strip()
        nombre = str(row.get('Nombre', '')).replace("'", "''").strip()
        tipo_muestra = str(row.get('TipoMuestra', '')).replace("'", "''").strip()
        contenedor = str(row.get('contenedor', '')).replace("'", "''").strip()
        
        # Exact column name 'Tiempo/Días '
        tiempo = str(row.get('Tiempo/Días ', '')).replace("'", "''").strip()
        preparacion = str(row.get('Indicaciones o preparacion', '')).replace("'", "''").strip()
        pruebas = str(row.get('Pruebas incluidas en el perfil', '')).replace("'", "''").strip()
        
        if not nombre:
            continue
            
        f.write(f"INSERT INTO catalogo_estudios (categoria_id, clave_interna, nombre, descripcion_breve, tiempo_procesamiento, muestra_requerida, contenedor, preparacion, pruebas_incluidas, activo) ")
        f.write(f"VALUES ({c_id}, '{clave}', '{nombre}', '', '{tiempo}', '{tipo_muestra}', '{contenedor}', '{preparacion}', '{pruebas}', 1);\n")
        
    f.write("\n-- EOF\n")
