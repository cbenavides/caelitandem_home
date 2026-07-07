import os
import glob

docs_path = "/home/carlos/GitHub/caelitandem_home/restaurantb/docs/*.html"

replacements = {
    "Walkie-Talkie (Push-and-Hold)": "Multipulsación Acumulativa (Mute/Unmute)",
    "Walkie-Talkie": "Multipulsación Acumulativa",
    "mantener presionado el botón táctil mientras dicta": "mantener presionado el botón táctil por cada frase y soltar",
    "el micrófono agresivamente y mostrando tu preview en pantalla": "la captura visual, pero preserva el canal de audio activo (latencia cero)",
    "suspendiendo el AudioContext": "implementando un Mute/Unmute lógico a nivel Worker",
}

for filepath in glob.glob(docs_path):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {os.path.basename(filepath)}")

