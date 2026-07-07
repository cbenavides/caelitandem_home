import os
import re

docs_dir = "/home/carlos/GitHub/caelitandem_home/restaurantb/docs"
gemini_md = "/home/carlos/GitHub/caelitandem_home/restaurantb/GEMINI.md"

def replace_in_file(filepath):
    if not os.path.exists(filepath):
        print(f"Skipping {filepath}, does not exist.")
        return
        
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Update Push-to-Talk definition and VAD
    content = re.sub(r'Push-to-Talk \(debe pulsar un botón físico/táctil para dictar\)',
                     r'Walkie-Talkie / Push-and-Hold (debe mantener presionado el botón táctil mientras dicta)', content, flags=re.IGNORECASE)
    content = re.sub(r'modelo \u003cstrong\u003ePush-to-Talk\u003c/strong\u003e',
                     r'modelo <strong>Walkie-Talkie (Push-and-Hold)</strong>', content, flags=re.IGNORECASE)
    
    # 2. Update AudioContext suspend instead of close
    content = re.sub(r'cerrando el \u003ccode\u003eAudioContext\u003c/code\u003e',
                     r'suspendiendo el <code>AudioContext</code>', content, flags=re.IGNORECASE)
    
    # 3. Update the "Listo" / VAD rule for waitstaff
    content = re.sub(r'Al finalizar, dicta la palabra \u003cem\u003e"Listo"\u003c/em\u003e\. El sistema corta inmediatamente la escucha de VOSK, extrae el texto y lo procesa\. \(Si no dicta "Listo", el sistema cortará por detección de silencio prolongado - VAD\)\.',
                     r'Al finalizar, simplemente suelta el botón. El sistema corta inmediatamente la escucha de VOSK, extrae el texto acumulado y lo procesa. Ya no hay cortes por silencio (VAD), permitiendo pausas naturales.', content)
    
    content = re.sub(r'El comando \u003cem\u003e"listo"\u003c/em\u003e ahora es interpretado',
                     r'El fin del dictado al soltar el botón ahora es interpretado', content)
    
    content = re.sub(r'protocolo mixto Push-to-Talk que permite detener el dictado \(\u003cem\u003eListo\u003c/em\u003e\)',
                     r'protocolo Walkie-Talkie (Push-and-Hold) que detiene el dictado al soltar el botón', content)
                     
    content = re.sub(r'Se procesa de inmediato al escuchar "listo", sin esperar silencio \(VAD\)\.',
                     r'Se procesa de inmediato al soltar el botón, permitiendo pausas infinitas mientras se mantenga presionado.', content)
                     
    content = re.sub(r'Dicte: \u003cem\u003e"Mesa uno, dos tacos al pastor, listo"\u003c/em\u003e',
                     r'Mantenga presionado y dicte: <em>"Mesa uno, dos tacos al pastor"</em> (luego suelte)', content)
                     
    content = re.sub(r'Dicte: \u003cem\u003e"Mesa cinco, una gringa, dos tripitas y una coca de litro bien fría\.\.\. listo"\u003c/em\u003e\.',
                     r'Mantenga presionado y dicte: <em>"Mesa cinco, una gringa, dos tripitas y una coca de litro bien fría"</em> (suelte al terminar).', content)
                     
    content = re.sub(r'Al terminar de hablar, diga el comando \u003cstrong\u003e"listo"\u003c/strong\u003e o presione el botón del micrófono para detener la escucha\.',
                     r'Al terminar de hablar, simplemente suelte el botón del micrófono para detener la escucha.', content)
                     
    content = re.sub(r'Diga en voz alta el comando: \u003cstrong\u003e"listo mesa tres"\u003c/strong\u003e\.',
                     r'En el KDS de cocina, diga en voz alta el comando: <strong>"listo mesa tres"</strong>.', content)

    # 4. Remove Listo from Mesero Grammar (it's only for kitchen now)
    content = re.sub(r'<tr>\s*<td><strong>Finalizar Dictado de Comanda</strong></td>\s*<td><code>"Listo"</code> \(Al final de la frase\)</td>\s*<td><em>"Mesa cinco, dos de tripa\.\.\. \[pausa\]\.\.\. Listo"</em></td>\s*<td>\(Ninguna\)\. Pasa automáticamente al modo Preview\.</td>\s*<td>\(Si no se dicta, el sistema usa detección de silencio prolongado para terminar\)\.</td>\s*</tr>',
                     r'<tr>\n        <td><strong>Finalizar Dictado de Comanda</strong></td>\n        <td><code>Soltar el Botón (Push-and-Hold)</code></td>\n        <td><em>Mantener presionado: "Mesa cinco, dos de tripa" -> Soltar</em></td>\n        <td>(Ninguna). Pasa automáticamente al modo Preview.</td>\n        <td>(El dictado solo termina al soltar el botón, permitiendo pausas sin corte por VAD).</td>\n      </tr>', content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for filename in os.listdir(docs_dir):
    if filename.endswith(".html"):
        replace_in_file(os.path.join(docs_dir, filename))

replace_in_file(gemini_md)
print("Done.")
