import markdown
import sys

md_file = "/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/contrato-laesh/v1.1/Resumen_Oferta_Servicios.md"
html_file = "/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/contrato-laesh/v1.1/Resumen_Oferta_Servicios.html"

try:
    with open(md_file, "r", encoding="utf-8") as f:
        text = f.read()

    # Convert markdown to html with tables extension
    html_content = markdown.markdown(text, extensions=['tables'])

    # CSS for professional commercial contract
    css = """
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
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
        
        /* Table Styling */
        .table-container {
            width: 100%;
            overflow-x: auto;
            margin: 2em 0;
            page: landscape-page;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.85em; /* Smaller font for tables */
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
        
        em {
            color: #4A5568;
            font-style: italic;
        }
        
        strong {
            color: #1A202C;
            font-weight: 700;
        }

        /* Blockquote / Policy Sections */
        blockquote {
            margin: 1.5em 0;
            padding: 1.2em 1.5em;
            background-color: #F8FAFC;
            border-left: 5px solid #3182CE;
            border-radius: 0 4px 4px 0;
            color: #2D3748;
            font-size: 0.95em;
        }
        
        blockquote p {
            margin: 0;
        }
        
        /* Solo el primer texto en negrita (el título) se comporta como bloque y azul */
        blockquote > p > strong:first-of-type {
            color: #2B6CB0;
            display: block;
            margin-bottom: 0.5em;
            font-size: 1.05em;
        }

        /* El resto de las negritas dentro del párrafo se mantienen normales (inline y oscuras) */
        blockquote > p > strong:not(:first-of-type) {
            color: #1A202C;
            display: inline;
            margin-bottom: 0;
            font-size: 1em;
        }

        /* ── Márgenes de impresión ── */
        /* IMPORTANTE: @page SIEMPRE al nivel raíz del CSS, NUNCA dentro de @media print */
        @page {
            size: portrait;
            margin: 1.6cm 1.4cm;
        }

        @page landscape-page {
            size: landscape;
            margin: 1.2cm;
        }

        /* Print: ajustes de body y tipografía (SIN @page aquí) */
        @media print {
            body {
                padding: 0;
                margin: 0;
                max-width: none;
                font-size: 10pt;
                line-height: 1.25;
                box-sizing: border-box;
            }

            h1 { font-size: 1.5em; margin-top: 0.5em; margin-bottom: 0.3em; padding-bottom: 4px; }
            h2 { font-size: 1.2em; margin-top: 0.8em; margin-bottom: 0.3em; padding-bottom: 3px; page-break-after: avoid; }
            h3 { font-size: 1.05em; margin-top: 0.8em; margin-bottom: 0.2em; page-break-after: avoid; }

            p { margin-bottom: 0.4em; }
            ul, ol { margin-bottom: 0.5em; padding-left: 20px; }
            li { margin-bottom: 0.2em; }

            blockquote {
                margin: 0.8em 0;
                padding: 0.6em 1em;
                border-left-width: 4px;
            }
            blockquote > p > strong:first-of-type {
                margin-bottom: 0.2em;
            }

            .table-container {
                page-break-before: always;
                margin: 0;
            }

            .table-container table {
                page-break-inside: auto;
                margin: 0;
            }

            .table-container th, .table-container td {
                font-size: 9pt;
                padding: 8px 10px;
                line-height: 1.4;
            }

            table {
                page-break-inside: auto;
                margin: 0.8em 0;
            }

            tr {
                page-break-inside: avoid;
                page-break-after: auto;
            }

            th, td {
                font-size: 9pt;
                padding: 6px;
            }

            a {
                text-decoration: none;
                color: #2D3748;
            }
        }
    </style>
    """

    # Wrap only the 5-column table in the styled container for landscape printing
    import re
    
    def wrap_large_table(match):
        table_html = match.group(1)
        # Solo aplicamos el contenedor horizontal a la tabla comparativa de 5 columnas
        if "Opción 1" in table_html and "Opción 4" in table_html:
            return f'<div class="table-container">{table_html}</div>'
        return table_html

    html_content = re.sub(r'(<table>.*?</table>)', wrap_large_table, html_content, flags=re.DOTALL)

    final_html = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resumen de Oferta de Servicios - LAESH</title>
    {css}
</head>
<body>
    {html_content}
</body>
</html>
"""

    with open(html_file, "w", encoding="utf-8") as f:
        f.write(final_html)

    print("HTML generated successfully at", html_file)

except Exception as e:
    print("Error:", e)
