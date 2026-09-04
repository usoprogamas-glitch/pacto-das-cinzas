from PIL import Image
from collections import Counter

img = Image.open("assets/sos/NarcisKingZale/NarcisKingZale_Idle_D3_F00.png").convert("RGBA")
print("tamanho:", img.size)
px = list(img.getdata())
opaque = [p for p in px if p[3] > 128]
transparent = [p for p in px if p[3] <= 128]
print(f"opacos: {len(opaque)} | transparentes: {len(transparent)}")
if opaque:
    colors = Counter((p[0] // 32, p[1] // 32, p[2] // 32) for p in opaque)
    print("top cores opacas:", colors.most_common(4))
if transparent:
    tcolors = Counter(p[:3] for p in transparent)
    print("cores dos transparentes:", tcolors.most_common(3))
