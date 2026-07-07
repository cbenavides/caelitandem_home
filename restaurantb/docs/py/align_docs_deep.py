import os
import glob
import re

docs_path = "/home/carlos/GitHub/caelitandem_home/restaurantb/docs/*.html"

def replace_in_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    for old, new in replacements.items():
        if isinstance(old, re.Pattern):
            content = old.sub(new, content)
        else:
            content = content.replace(old, new)
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Deep aligned: {os.path.basename(filepath)}")

# Regex patterns and text replacements
replacements = {
    # Fix technical spec about AudioContext being closed
    re.compile(r"Cierre agresivo del <code>AudioContext<\/code> y <code>MediaStreamTrack<\/code> tras la finalización del dictado para detener la zombificación del micrófono\."): 
        r"Implementación de Mute/Unmute lógico a nivel de Web Worker para mantener el <code>AudioContext</code> caliente (Always-Hot) con latencia 0ms, eliminando el gasto de CPU al descartar los paquetes de audio cuando el botón no está presionado.",
    
    # Fix Functional Workflow RN-2.3
    re.compile(r"el micrófono se apaga agresivamente \(deteniendo los tracks de audio y suspendiendo el <code>AudioContext<\/code>\) para desactivar el indicador de grabación del sistema operativo, permitiendo que la pantalla se atenúe y suspenda normalmente para conservar batería\."):
        r"el sistema implementa un Mute lógico (descarte de paquetes en el Worker). El micrófono y el AudioContext permanecen en modo 'Always-Hot' (latencia cero), manteniendo el indicador de grabación visible, pero evitando el procesamiento innecesario en el motor VOSK.",
    
    # Fix Ficha Tecnica Comercial
    re.compile(r"la aplicación detiene físicamente las pistas de audio y cierra el <code>AudioContext<\/code> al soltar el botón\."):
        r"la aplicación detiene lógicamente el procesamiento mediante un Mute/Unmute a nivel Worker, manteniendo el flujo listo (latencia cero) al soltar el botón.",
    
    # Fix Test Cases (Pruebas_Casos_Validacion_Comandas_VOSK.html) - Timeout VAD
    re.compile(r"<strong>En ese preciso milisegundo, el micrófono se apaga automáticamente<\/strong>"):
        r"<strong>En ese preciso milisegundo, el sistema aplica un Mute lógico (detiene el procesamiento VOSK)</strong>",
        
    re.compile(r"El micrófono sigue encendido o la luz verde/roja de la tablet no se apaga después de enviar la comanda"):
        r"El micrófono permanece 'Always-Hot' intencionalmente (la luz verde no se apaga), pero el procesamiento interno debe detenerse.",
        
    re.compile(r"Active el micrófono sin hablar. Asegúrese de que el entorno sea medianamente ruidoso o tenga estática ambiental. Hable después de 15 segundos."):
        r"Active el micrófono (mantenga presionado) sin hablar. Hable después de 15 segundos y suelte.",
        
    # Technical Spec VAD description
    re.compile(r"si este no supera el umbral matemático de actividad \(silencio\), el chunk es descartado, ahorrando más de un 40% de CPU y batería en transmisiones inactivas\."):
        r"adicionalmente, la compuerta de Multipulsación (Mute/Unmute) descarta todos los paquetes cuando el botón no está presionado, garantizando ahorro de CPU y batería en modo inactivo.",
        
    # Funcional Flujos "Activar Escucha"
    re.compile(r"y da <strong>Touch \(Táctil\)</strong> al botón de micrófono en la PWA"):
        r"y <strong>Mantiene presionado</strong> el botón de micrófono en la PWA",
        
    re.compile(r"El mesero pulsa el micrófono y dicta: <em>\"Cerrar cuenta de mesa cinco\"</em>."):
        r"El mesero mantiene presionado el micrófono, dicta: <em>\"Cerrar cuenta de mesa cinco\"</em> y lo suelta.",
}

for filepath in glob.glob(docs_path):
    replace_in_file(filepath, replacements)

