import csv
import re
import os
import shutil

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
sprites_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
dest_root = os.path.join("assets", "sos", "Brugaves")

with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

copied = 0
for row in rows:
    name = row[1]
    if re.match(r"^Brugaves_(Idle|Walk)_D\d_F\d+$", name):
        src = None
        for dirpath, _, files in os.walk(sprites_root):
            if name + ".png" in files:
                src = os.path.join(dirpath, name + ".png")
                break
        if src is None:
            print("faltando:", name)
            continue
        dest = os.path.join(dest_root, name + ".png")
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(src, dest)
        copied += 1
print("copiados:", copied)
