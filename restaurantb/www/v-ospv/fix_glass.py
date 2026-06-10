import os
import glob
import re

files = glob.glob("/opt/lampp/htdocs/agua/reportes/*.php")

for filepath in files:
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Check if there's a double quote glass-table inside a PHP print or echo statement
    # A simple way to fix this globally is to replace class="glass-table" with class='glass-table'
    if 'class="glass-table"' in content:
        content = content.replace('class="glass-table"', "class='glass-table'")
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")
