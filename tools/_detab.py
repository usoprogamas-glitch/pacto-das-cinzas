import os
import re

total_files = 0
total_tabs = 0
for root, dirs, files in os.walk('scripts'):
    for f in files:
        if not f.endswith('.gd'):
            continue
        p = os.path.join(root, f)
        with open(p, encoding='utf-8', errors='replace') as fh:
            t = fh.read()
        if '\t' not in t:
            continue
        n = t.count('\t')
        total_files += 1
        total_tabs += n
        # Converte cada tab em 1 espaco (convencao do projeto), preservando
        # quebras de linha. Tabs nunca aparecem dentro de strings relevantes.
        nt = t.replace('\t', ' ')
        with open(p, 'w', encoding='utf-8', newline='') as fh:
            fh.write(nt)
        print(n, p)
print('TOTAL', total_tabs, 'tabs em', total_files, 'arquivos')
