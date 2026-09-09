import os
import zipfile

root = r"C:\Users\Administrator\Downloads\test\Sea of Stars [FitGirl Repack]"
for dirpath, dirnames, files in os.walk(root):
    depth = dirpath[len(root):].count(os.sep)
    if depth > 2:
        dirnames.clear()
        continue
    indent = "  " * depth
    print(f"{indent}{os.path.basename(dirpath) or 'RAIZ'}/")
    for f in files[:12]:
        size_kb = os.path.getsize(os.path.join(dirpath, f)) // 1024
        print(f"{indent}  {f} ({size_kb} KB)")
    if len(files) > 12:
        print(f"{indent}  ... +{len(files) - 12} arquivos")
