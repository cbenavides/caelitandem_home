#!/usr/bin/env python3
"""
build_pdf.py
Pipeline: Markdown → HTML → PDF (via Google Chrome headless)

Documentos:
  resumen  → Resumen_Oferta_Servicios.pdf      (letter portrait, multi-página)
  tabla    → Cuadro_Comparativo.pdf             (oficio landscape, 1 hoja)
  carta    → Carta_Presentacion.pdf             (letter portrait, 1 hoja)
  guia     → Guia_Exposicion_Diagramas.pdf      (letter portrait)
  anexo    → Anexo_Visual_Flujos_Operativos.pdf (legal landscape, desde HTML existente)

Uso:
  python3 build_pdf.py              # todos
  python3 build_pdf.py carta resumen
"""

import markdown
import os
import re
import subprocess
import sys

BASE = os.path.dirname(os.path.abspath(__file__)) + "/"
TMP_BUILD = "/tmp/laesh_build/"
os.makedirs(TMP_BUILD, exist_ok=True)

SCRIPT_DIR = "/home/carlos/tools/pdf-renderer"
PDF_RENDERER = f"{SCRIPT_DIR}/pdf_render.js"


# ─────────────────────────────────────────────
# Utilidades
# ─────────────────────────────────────────────

def read_md(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write_html(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  HTML → {path}")

def html_to_pdf(html_path, pdf_path, width_pts=None, height_pts=None):
    """
    Convierte HTML → PDF usando puppeteer (Node.js).
    displayHeaderFooter: false — sin header/footer del navegador.
    preferCSSPageSize: true — respeta @page del CSS.
    """
    cmd = ["node", PDF_RENDERER, html_path, pdf_path]
    if width_pts and height_pts:
        cmd += [str(width_pts), str(height_pts)]

    r = subprocess.run(cmd, capture_output=True, text=True, timeout=90,
                       cwd=SCRIPT_DIR)
    ok = r.returncode == 0
    print(f"  PDF  → {pdf_path} {'✅' if ok else '❌'}")
    if not ok:
        print(f"  stderr: {r.stderr[:400]}")
        print(f"  stdout: {r.stdout[:200]}")
    return ok


def make_html(title, css_block, body_html):
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>{title}</title>
    {css_block}
</head>
<body>
{body_html}
</body>
</html>"""


# ─────────────────────────────────────────────
# CSS por tipo de documento
# ─────────────────────────────────────────────

def css_base(page_size, page_margin, font_size="10.5pt", line_height="1.45", extra=""):
    """CSS base con @page al NIVEL RAÍZ (nunca dentro de @media)."""
    return f"""<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

    /* @page SIEMPRE al nivel raíz */
    @page {{
        size: {page_size};
        margin: {page_margin};
    }}

    * {{ box-sizing: border-box; }}

    body {{
        font-family: 'Inter', Arial, sans-serif;
        color: #1A202C;
        font-size: {font_size};
        line-height: {line_height};
        margin: 0;
        padding: 0;
        background: #fff;
    }}

    h1 {{
        font-size: 1.5em;
        text-align: center;
        border-bottom: 2px solid #2B6CB0;
        padding-bottom: 5px;
        margin-top: 0.6em;
        margin-bottom: 0.7em;
        color: #1A202C;
    }}
    h2 {{
        font-size: 1.2em;
        color: #2B6CB0;
        border-bottom: 1px solid #BEE3F8;
        padding-bottom: 3px;
        margin-top: 1.2em;
        margin-bottom: 0.5em;
        page-break-after: avoid;
    }}
    h3 {{
        font-size: 1.05em;
        color: #2D3748;
        margin-top: 1em;
        margin-bottom: 0.4em;
        page-break-after: avoid;
    }}

    p {{
        margin: 0 0 0.55em 0;
        text-align: justify;
    }}

    ul, ol {{ margin: 0 0 0.7em 0; padding-left: 1.3em; }}
    li {{ margin-bottom: 0.25em; }}

    hr {{ border: none; border-top: 1px solid #E2E8F0; margin: 0.7em 0; }}

    em {{ color: #4A5568; }}
    strong {{ color: #1A202C; font-weight: 700; }}

    blockquote {{
        margin: 0.7em 0;
        padding: 0.6em 1em;
        background: #EBF8FF;
        border-left: 4px solid #3182CE;
        border-radius: 0 4px 4px 0;
        font-size: 0.93em;
    }}
    blockquote p {{ margin: 0; text-align: left; }}

    table {{
        width: 100%;
        border-collapse: collapse;
        font-size: 0.87em;
        margin: 0.6em 0;
    }}
    th, td {{
        border: 1px solid #CBD5E0;
        padding: 6px 8px;
        vertical-align: top;
        text-align: left;
    }}
    th {{
        background: #EBF4FF;
        font-weight: 600;
        color: #1A202C;
    }}
    tr:nth-child(even) {{ background: #F7FAFC; }}

    a {{ color: #2B6CB0; text-decoration: none; }}

    @media print {{
        body {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
        h2, h3 {{ page-break-after: avoid; }}
        tr {{ page-break-inside: avoid; }}
    }}

    {extra}
</style>"""


# ─────────────────────────────────────────────
# Carta de Presentación — 1 sola hoja carta
# ─────────────────────────────────────────────
def build_carta():
    md_path   = BASE + "Carta_Presentacion.md"
    html_path = TMP_BUILD + "Carta_Presentacion.html"
    pdf_path  = BASE + "Carta_Presentacion.pdf"

    body = markdown.markdown(read_md(md_path), extensions=["tables"])

    # CSS ajustado para caber en 1 hoja letter con mejor distribución vertical
    css = css_base(
        page_size="letter portrait",
        page_margin="18mm 22mm",
        font_size="10.5pt",
        line_height="1.39",
        extra="""
        /* Carta: optimizaciones de distribución */
        h3 { font-size: 1.1em; margin-top: 1em; margin-bottom: 0.4em; }
        p   { margin-bottom: 0.7em; }
        li  { margin-bottom: 0.25em; }
        table { font-size: 0.9em; margin: 0.8em 0; }
        th, td { padding: 6px 8px; }
        blockquote { padding: 0.5em 0.8em; margin: 0.6em 0; }
        hr { margin: 0.8em 0; }
        """
    )

    write_html(html_path, make_html("Carta de Presentación - LAESH", css, body))
    return html_to_pdf(html_path, pdf_path)


# ─────────────────────────────────────────────
# Resumen de Oferta — sin la tabla comparativa
# ─────────────────────────────────────────────
def build_resumen():
    md_path   = BASE + "Resumen_Oferta_Servicios.md"
    html_path = TMP_BUILD + "Resumen_Oferta_Servicios.html"
    pdf_path  = BASE + "Resumen_Oferta_Servicios.pdf"

    body = markdown.markdown(read_md(md_path), extensions=["tables"])

    # Identificar y ELIMINAR la tabla comparativa del resumen principal
    def strip_comparativo(m):
        tbl = m.group(1)
        if ("Proyecto 1" in tbl or "Opción 1" in tbl) and ("Proyecto 2" in tbl or "Opción 4" in tbl):
            return '<p class="cuadro-notice" style="margin-bottom: 2em; margin-top: 1em; font-size: 1.05em; color: #2B6CB0;"><em>📊 Ver documento adjunto: <strong>Cuadro_Comparativo.pdf</strong></em></p>'
        return tbl

    body = re.sub(r'(<table>.*?</table>)', strip_comparativo, body, flags=re.DOTALL)

    # Inyectar saltos de página explícitos mínimos para evitar cortes feos
    breaks = [
        (r'(<h2[^>]*>.*?Resumen Comparativo)', r'<div style="page-break-before: always; break-before: page;"></div>\1'),
        (r'(<h2>Consideraciones Fiscales)', r'<div style="page-break-before: always; break-before: page;"></div>\1'),
    ]
    for pattern, replacement in breaks:
        body = re.sub(pattern, replacement, body)

    css = css_base(
        page_size="letter portrait",
        page_margin="16mm 16mm",
        font_size="11.3pt",
        line_height="1.35",
        extra="""
        h1 { font-size: 1.55em; margin-top: 0.35em; margin-bottom: 0.25em; color: #1A365D; border-bottom: 2px solid #2B6CB0; padding-bottom: 3px; }
        h2 { font-size: 1.35em; margin-top: 1.2em; margin-bottom: 0.4em; color: #2B6CB0; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px; page-break-after: avoid; }
        h3 { font-size: 1.22em; margin-top: 1.0em; margin-bottom: 0.3em; color: #2D3748; page-break-after: avoid; }
        p  { margin-bottom: 0.6em; text-align: justify; }
        ul, ol { margin-bottom: 0.6em; padding-left: 1.3em; }
        li { margin-bottom: 0.3em; }
        blockquote { margin: 1.2em 0; padding: 0.5em 0.8em; font-size: 0.95em; }
        blockquote p { margin-bottom: 1em; }
        blockquote p:last-child { margin-bottom: 0; }
        table { margin: 1em 0; font-size: 0.95em; width: 100%; border-collapse: collapse; }
        th, td { padding: 6px 8px; border: 1px solid #CBD5E0; text-align: left; }
        th { background-color: #F7FAFC; font-weight: bold; }
        """
    )

    write_html(html_path, make_html("Resumen de Oferta de Servicios - LAESH", css, body))
    return html_to_pdf(html_path, pdf_path)


# ─────────────────────────────────────────────
# Cuadro Comparativo — oficio horizontal, PDF separado
# ─────────────────────────────────────────────
def build_tabla():
    md_path   = BASE + "Resumen_Oferta_Servicios.md"
    html_path = TMP_BUILD + "Cuadro_Comparativo.html"
    pdf_path  = BASE + "Cuadro_Comparativo.pdf"

    body = markdown.markdown(read_md(md_path), extensions=["tables"])

    # Extraer SOLO el título h2 + párrafo intro + tabla comparativa
    # 1. Buscar el bloque desde el h2 "Cuadro Comparativo"
    h2_match = re.search(r'<h2[^>]*>.*?Resumen Comparativo.*?</h2>', body, re.DOTALL)
    table_match = re.search(r'<table>.*?</table>', body, re.DOTALL)

    if not h2_match or not table_match:
        print("  ❌ No se encontró la tabla comparativa en el MD")
        return False

    # Párrafo entre h2 y table
    between = body[h2_match.end():table_match.start()].strip()

    extracted_body = f"""
{h2_match.group(0)}
{between}
<br>
{table_match.group(0)}
"""

    # Fusionar celdas de encabezado de grupo (colspan=4) para estética ejecutiva sin tragar las filas intermedias
    extracted_body = re.sub(
        r'<tr>(?:(?!</tr>).)*?<strong>\s*---\s*(.*?)\s*---\s*</strong>(?:(?!</tr>).)*?</tr>',
        r'<tr><td colspan="4" style="text-align: center; background-color: #E2E8F0; color: #2B6CB0; font-weight: bold; padding: 8px; border-bottom: 2px solid #CBD5E0;">\1</td></tr>',
        extracted_body,
        flags=re.DOTALL
    )

    # Forzar que el Resumen Final empiece siempre en una nueva hoja
    extracted_body = extracted_body.replace(
        '<tr><td colspan="5" style="text-align: center; background-color: #E2E8F0; color: #2B6CB0; font-weight: bold; padding: 8px; border-bottom: 2px solid #CBD5E0;">RESUMEN FINAL</td></tr>',
        '<tr style="page-break-before: always; break-before: page;"><td colspan="5" style="text-align: center; background-color: #E2E8F0; color: #2B6CB0; font-weight: bold; padding: 8px; border-bottom: 2px solid #CBD5E0;">RESUMEN FINAL</td></tr>'
    )

    css = css_base(
        page_size="legal landscape",
        page_margin="14mm 16mm",
        font_size="10.5pt",
        line_height="1.35",
        extra="""
        h2 { font-size: 1.25em; margin-top: 0.3em; margin-bottom: 0.5em; }
        p  { margin-bottom: 0.4em; font-size: 0.98em; }
        table { font-size: 10pt; margin: 0.4em 0; }
        th { background: #CBD5E0; color: #1A202C; font-weight: 700; border: 1px solid #A0AEC0; }
        th, td { padding: 8px 10px; font-size: 10pt; line-height: 1.35; }
        """
    )

    write_html(html_path, make_html("Cuadro Comparativo - LAESH", css, extracted_body))
    return html_to_pdf(html_path, pdf_path)


# ─────────────────────────────────────────────
# Guía de Exposición de Diagramas
# ─────────────────────────────────────────────
def build_guia():
    md_path   = BASE + "Guia_Exposicion_Diagramas.md"
    html_path = TMP_BUILD + "Guia_Exposicion_Diagramas.html"
    pdf_path  = BASE + "Guia_Exposicion_Diagramas.pdf"

    body = markdown.markdown(read_md(md_path), extensions=["tables"])
    css = css_base(
        page_size="letter portrait",
        page_margin="16mm 20mm",
        font_size="10pt",
        line_height="1.4",
    )

    write_html(html_path, make_html("Guía de Exposición de Diagramas - LAESH", css, body))
    return html_to_pdf(html_path, pdf_path)


# ─────────────────────────────────────────────
# Anexo Visual (HTML existente, legal landscape)
# ─────────────────────────────────────────────
def build_anexo():
    md_path   = BASE + "Anexo_Visual_Flujos_Operativos.md"
    html_path = TMP_BUILD + "Anexo_Visual_Flujos_Operativos.html"
    pdf_path  = BASE + "Anexo_Visual_Flujos_Operativos.pdf"

    content = read_md(md_path)
    full_html = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Anexo Visual - LAESH</title>
</head>
<body>
{content}
</body>
</html>"""
    write_html(html_path, full_html)
    return html_to_pdf(html_path, pdf_path)


# ─────────────────────────────────────────────
# Runner
# ─────────────────────────────────────────────
DOCS = {
    "carta":   ("Carta de Presentación (1 hoja)",       build_carta),
    "resumen": ("Resumen de Oferta de Servicios",        build_resumen),
    "tabla":   ("Cuadro Comparativo (oficio landscape)", build_tabla),
    "guia":    ("Guía de Exposición de Diagramas",       build_guia),
    "anexo":   ("Anexo Visual de Flujos",                build_anexo),
}

targets = sys.argv[1:] if len(sys.argv) > 1 else list(DOCS.keys())

for key in targets:
    if key not in DOCS:
        print(f"⚠ '{key}' desconocido. Opciones: {list(DOCS.keys())}")
        continue
    name, fn = DOCS[key]
    print(f"\n▶ {name}")
    fn()

print("\n✅ Pipeline completado.")
