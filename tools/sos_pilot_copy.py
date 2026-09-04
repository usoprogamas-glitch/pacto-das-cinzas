import csv
import re
import os
import shutil

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
sprites_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
dest_root = os.path.join("assets", "sos", "NarcisKingZale")

with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Piloto: Idle (todas as dirs, 1 frame cada) + Walk (D1, D3, D5 x 6 frames)
copied = 0
missing = 0
for row in rows:
    name = row[1]
    if not name.startswith("NarcisKingZale_"):
        continue
    m = re.match(r"^NarcisKingZale_(Idle)_D(\d)_F(\d+)$", name)
    is_idle = bool(m)
    m2 = re.match(r"^NarcisKingZale_(Walk)_D(\d)_F(\d+)$", name)
    if not (is_idle or m2):
        continue
    if m2 and m2.group(2) not in ("1", "3", "5"):
        continue  # piloto só 3 direções de walk
    # Localiza o arquivo real (sprites/<origem>/<nome>.png)
    src = None
    for dirpath, _, files in os.walk(sprites_root):
        if name + ".png" in files:
            src = os.path.join(dirpath, name + ".png")
            break
    if src is None:
        missing += 1
        continue
    dest = os.path.join(dest_root, name + ".png")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(src, dest)
    copied += 1

print(f"copiados: {copied} | faltando no disco: {missing}")
