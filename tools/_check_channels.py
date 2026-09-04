from PIL import Image
from collections import Counter

path = None
import os
root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
for dirpath, _, files in os.walk(root):
    if "StrifeMinion_Idle_D3_F00.png" in files:
        path = os.path.join(dirpath, "StrifeMinion_Idle_D3_F00.png")
        break
print("frame:", path)

img = Image.open(path).convert("RGBA")
px = list(img.getdata())
opaque = [p for p in px if p[3] > 128]
print("tamanho:", img.size, "opacos:", len(opaque), "/", len(px))
colors = Counter((p[0] // 48, p[1] // 48, p[2] // 48) for p in opaque)
print("top 6 (r,g,b)//48:", colors.most_common(6))
# Média por canal
avg_r = sum(p[0] for p in opaque) / len(opaque)
avg_g = sum(p[1] for p in opaque) / len(opaque)
avg_b = sum(p[2] for p in opaque) / len(opaque)
print(f"média canais: R={avg_r:.0f} G={avg_g:.0f} B={avg_b:.0f}")
