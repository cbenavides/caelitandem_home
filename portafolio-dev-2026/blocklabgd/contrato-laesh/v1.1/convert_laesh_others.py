import markdown
import sys
import re

base_path = "/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/contrato-laesh/v1.1/"

files = [
    {
        "md": base_path + "Anexo_Visual_Flujos_Operativos.md",
        "html": base_path + "Anexo_Visual_Flujos_Operativos.html",
        "type": "anexo"
    },
    {
        "md": base_path + "Carta_Presentacion.md",
        "html": base_path + "Carta_Presentacion.html",
        "type": "carta"
    },
    {
        "md": base_path + "Guia_Exposicion_Diagramas.md",
        "html": base_path + "Guia_Exposicion_Diagramas.html",
        "type": "guia"
    }
]

common_css = """
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

        /* ── Márgenes de impresión (nivel raíz, nunca dentro de @media print) ── */
        @page {
            size: letter portrait;
            margin: 15mm 20mm;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            color: #2D3748;
            line-height: 1.6;
            margin: 0 auto;
            max-width: 900px;
            padding: 40px;
            background-color: #FFFFFF;
        }

        h1, h2, h3, h4 {
            color: #1A202C;
            border-bottom: 1px solid #E2E8F0;
            padding-bottom: 8px;
            margin-top: 2em;
            margin-bottom: 1em;
        }

        h1 {
            font-size: 2.2em;
            text-align: center;
            border-bottom: 2px solid #3182CE;
        }

        h2 {
            font-size: 1.5em;
            color: #2B6CB0;
        }

        p {
            margin-bottom: 1em;
            text-align: justify;
        }

        ul, ol {
            margin-bottom: 1.5em;
        }

        li {
            margin-bottom: 0.5em;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.85em;
            margin: 2em 0;
        }

        th, td {
            border: 1px solid #CBD5E0;
            padding: 10px;
            text-align: left;
            vertical-align: top;
        }

        th {
            background-color: #F7FAFC;
            font-weight: 600;
            color: #2D3748;
        }

        tr:nth-child(even) {
            background-color: #F8FAFC;
        }

        strong {
            color: #1A202C;
            font-weight: 700;
        }
"""

carta_css = common_css + """
        /* Estilos específicos para Carta de Presentación */
        h1 {
            border-bottom: none;
            color: #2B6CB0;
            margin-top: 0;
        }

        /* Print: solo ajustes de tipografía/espaciado. @page ya está al nivel raíz. */
        @media print {
            body {
                padding: 0;
                margin: 0;
                max-width: none;
                font-size: 10.5pt;
                line-height: 1.3;
                box-sizing: border-box;
            }
            h1 {
                font-size: 1.5em;
                margin-bottom: 0.2em;
            }
            h2 {
                font-size: 1.1em;
                margin-top: 0.8em;
                margin-bottom: 0.3em;
            }
            p {
                margin-bottom: 0.5em;
            }
            ul, ol {
                margin-bottom: 0.5em;
            }
            table {
                font-size: 0.85em;
                margin: 0.8em 0;
            }
            hr {
                margin: 0.5em 0;
            }
        }
    </style>
"""

anexo_css = common_css + """
        /* El Anexo Visual define su propio @page (landscape) en el MD via <style> */
        @media print {
            body {
                padding: 0;
                margin: 0;
                max-width: none;
                box-sizing: border-box;
            }
        }
    </style>
"""

for item in files:
    try:
        with open(item["md"], "r", encoding="utf-8") as f:
            text = f.read()

        html_content = markdown.markdown(text, extensions=['tables'])

        css_to_use = carta_css if item["type"] in ["carta", "guia"] else anexo_css

        final_html = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{item["type"].capitalize()} - LAESH</title>
    {css_to_use}
</head>
<body>
    {html_content}
</body>
</html>
"""

        with open(item["html"], "w", encoding="utf-8") as f:
            f.write(final_html)

        print(f"HTML generado exitosamente en: {item['html']}")

    except Exception as e:
        print(f"Error procesando {item['md']}:", e)
