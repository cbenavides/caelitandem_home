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
    pdf_path = out_dir + md_file.replace('.md', '.pdf')
    body = markdown.markdown(build_pdf.read_md(md_path), extensions=["tables"])
    css = build_pdf.css_base(
        page_size="letter portrait",
        page_margin="16mm 20mm",
        font_size="10.5pt",
        line_height="1.4",
    )
    build_pdf.write_html(html_path, build_pdf.make_html(name, css, body))
    build_pdf.html_to_pdf(html_path, pdf_path)

build_doc("Contrato Marco", "Contrato_Base_Desarrollo.md")
build_doc("Anexo A Sitio Web", "Anexo_A_Sitio_Web.md")
build_doc("Anexo A Bloc Digital", "Anexo_A_Bloc_Digital.md")

print("Generación completada con éxito.")
