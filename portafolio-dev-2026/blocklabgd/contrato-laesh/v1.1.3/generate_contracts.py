import sys
sys.path.append('/home/carlos/GitHub/caelitandem_home/portafolio-dev-2026/blocklabgd/contrato-laesh/v1.1.3')
import build_pdf
import os
import markdown

out_dir = build_pdf.BASE + "contrato/"
os.makedirs(out_dir, exist_ok=True)

def build_doc(name, md_file):
    md_path = build_pdf.BASE + md_file
    html_path = build_pdf.TMP_BUILD + md_file.replace('.md', '.html')
    pdf_path = out_dir + md_file.replace('.md', '_v4.pdf')
    body = markdown.markdown(build_pdf.read_md(md_path), extensions=["tables"])
    css = build_pdf.css_base(
        page_size="letter portrait",
        page_margin="16mm 20mm",
        font_size="10.5pt",
        line_height="1.5",
        text_align="justify",
    )
    build_pdf.write_html(html_path, build_pdf.make_html(name, css, body))
    build_pdf.html_to_pdf(html_path, pdf_path)
    
    # Conversión a DOCX vía LibreOffice (HTML -> ODT -> DOCX para preservar formato)
    import subprocess
    odt_temp = f"/tmp/{md_file.replace('.md', '.odt')}"
    docx_temp = out_dir + md_file.replace('.md', '.docx')
    docx_final = out_dir + md_file.replace('.md', '_v4.docx')
    
    try:
        # 1. HTML -> ODT
        subprocess.run(["libreoffice", "--headless", "--convert-to", "odt", "--outdir", "/tmp", html_path], check=True, stdout=subprocess.DEVNULL)
        # 2. ODT -> DOCX
        subprocess.run(["libreoffice", "--headless", "--convert-to", "docx", "--outdir", out_dir, odt_temp], check=True, stdout=subprocess.DEVNULL)
        # 3. Renombrar a _v4.docx
        if os.path.exists(docx_temp):
            if os.path.exists(docx_final):
                os.remove(docx_final)
            os.rename(docx_temp, docx_final)
    finally:
        # Limpieza
        if os.path.exists(odt_temp):
            os.remove(odt_temp)

build_doc("Contrato Marco", "Contrato_Base_Desarrollo.md")
build_doc("Anexo A Sitio Web", "Anexo_A_Sitio_Web.md")
build_doc("Anexo A Bloc Digital", "Anexo_A_Bloc_Digital.md")

print("Generación completada con éxito.")
