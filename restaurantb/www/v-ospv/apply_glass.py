import os
import glob
import re

css_code = """
<style>
    /* Interfaz Híbrida Glassmorphism - Reportes */
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    body {
        font-family: 'Inter', sans-serif;
        background: #f1f5f9;
        color: #334155;
    }
    table.glass-table {
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(10px);
        border-radius: 12px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.05);
        border: 1px solid rgba(255,255,255,0.4);
        border-collapse: collapse;
        margin: 20px auto;
        padding: 10px;
    }
    table.glass-table th, table.glass-table td {
        padding: 10px 15px;
        border-bottom: 1px solid #e2e8f0;
    }
    table.glass-table th {
        background: rgba(241, 245, 249, 0.8);
        font-weight: 600;
        color: #1e293b;
    }
    .print-btn-float {
        position: fixed;
        top: 20px;
        right: 20px;
        background: rgba(37, 99, 235, 0.9);
        color: white;
        border: none;
        padding: 10px 20px;
        border-radius: 8px;
        font-weight: 600;
        font-family: 'Inter', sans-serif;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
        backdrop-filter: blur(4px);
        z-index: 9999;
        transition: all 0.2s;
    }
    .print-btn-float:hover {
        background: rgba(29, 78, 216, 1);
        transform: translateY(-2px);
    }
    @media print {
        body { background: white; padding: 0; }
        table.glass-table { box-shadow: none; border: none; border-radius: 0; }
        .print-btn-float { display: none !important; }
    }
</style>
"""

button_code = '\n<button class="print-btn-float" onclick="window.print()">🖨️ Imprimir Reporte</button>\n'

files = glob.glob("/opt/lampp/htdocs/agua/reportes/*.php")

for filepath in files:
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    modified = False
    
    # Remove window.print() inside script tags
    if re.search(r'\bwindow\.print\(\);?', content):
        content = re.sub(r'\bwindow\.print\(\);?', '/* window.print(); */', content)
        modified = True
        
    # Remove onload="print();"
    if re.search(r'onload="print\(\);?"', content):
        content = re.sub(r'onload="print\(\);?"', '', content)
        modified = True

    # If it was modified (meaning it had auto-print), inject our button and CSS
    if modified:
        if '<body' in content:
            # Inject right after <body...>
            content = re.sub(r'(<body[^>]*>)', r'\1' + button_code + css_code, content, count=1)
        
        # Optionally, for the 11 list reports, we can apply the glass-table class to their main tables
        # A simple heuristic: <table border=X> or <table width=100%> -> add class
        if 'listacontratos' in filepath or 'lista' in filepath or 'concentrado' in filepath or 'cartera' in filepath:
            content = re.sub(r'(<table[^>]*)>', r'\1 class="glass-table">', content)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")
