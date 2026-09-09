import csv
import re
import os
from PIL import Image

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
sprites_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Debug: como o Garl limpo se parece (que funciona!) vs StrifeMinion (que falha)
for target in ["Garl_Idle_D1_F00", "Brugaves_Idle_D1_F00", "StrifeMinion_Idle_D3_F00", "Acolyte1_Idle_D3_F00"]:
    src = None
    for dirpath, _, files in os.walk(sprites_root):
        if target + ".png" in files:
            src = os.path.join(dirpath, target + ".png")
            break
    if src is None:
        print(target, "-> NAO ACHOU")
        continue
    img = Image.open(src).convert("RGBA")
    px = list(img.getdata())
    opaque = [p for p in px if p[3] > 128]
    total_opaque = len(opaque)
    total_trans = len(px) - total_opaque
    if total_opaque:
        avg = tuple(round(sum(p[i] for p in opaque) / total_opaque) for i in range(3))
    else:
        avg = (0, 0, 0)
    print(f"{target:35} {img.size} opacos={total_opaque:5} transp={total_trans:5} avg={avg}")
