import csv
import re
import os
from PIL import Image
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
sprites_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Candidatos monstros + humanoides com Idle_D3_F00
by_frame = {}
for row in rows:
    m = re.match(r"^(\w+?)_Idle_D3_F00$", row[1])
    if m:
        by_frame[m.group(1)] = row

results = []
for name in sorted(by_frame):
    src = None
    for dirpath, _, files in os.walk(sprites_root):
        if name + ".png" in files:
            src = os.path.join(dirpath, name + ".png")
            break
    if src is None:
        continue
    img = Image.open(src).convert("RGBA")
    px = list(img.getdata())
    opaque = [p for p in px if p[3] > 128]
    if len(opaque) < 200 or len(opaque) == len(px):
        continue  # vazio ou sem alpha (corrompido)
    avg_r = sum(p[0] for p in opaque) / len(opaque)
    avg_g = sum(p[1] for p in opaque) / len(opaque)
    avg_b = sum(p[2] for p in opaque) / len(opaque)
    # Limpo = canais diversos (não mono-vermelho). Vermelho puro: G<15 e B<15.
    clean = not (avg_g < 20 and avg_b < 20)
    results.append((name, img.size, (avg_r, avg_g, avg_b), clean))

clean_list = [r for r in results if r[3]]
print(f"limpos: {len(clean_list)} / {len(results)}")
for name, size, avg, _ in clean_list[:40]:
    print(f"  {name:40} {size} rgb=({avg[0]:.0f},{avg[1]:.0f},{avg[2]:.0f})")
