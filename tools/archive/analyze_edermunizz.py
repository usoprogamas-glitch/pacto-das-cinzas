"""Analisa o tileset do Eder Muniz: tamanho, grade, tiles úteis por região."""
from PIL import Image

img = Image.open("assets/tilesets/edermunizz_overworld.png")
w, h = img.size
print("tileset:", img.size)

# O tileset parece ser 16x16 sem margem. Confere proporções.
print("gride 16x16:", w // 16, "x", h // 16)

# Fatia em tiles e classifica por cor média para achar pisos/grama.
cols, rows = w // 16, h // 16
tiles = []
for r in range(rows):
    for c in range(cols):
        t = img.crop((c * 16, r * 16, (c + 1) * 16, (r + 1) * 16))
        if t.getbbox() is None:
            continue
        px = list(t.convert("RGB").getdata())
        opaque = [p for p in px if t.getdata()[px.index(p)][3] > 128] if False else px
        avg = tuple(sum(p[i] for p in opaque) // len(opaque) for i in range(3))
        tiles.append((c, r, avg))
print("tiles com conteudo:", len(tiles))
# Agrupa por cor media aproximada (buckets de 32)
buckets = {}
for c, r, avg in tiles:
    key = (avg[0] // 32, avg[1] // 32, avg[2] // 32)
    buckets.setdefault(key, []).append((c, r))
print("\nBuckets de cor (rgb//32 -> count, tiles ate 12):")
for key, lst in sorted(buckets.items(), key=lambda kv: -len(kv[1])):
    print(f"  rgb{tuple(k * 32 for k in key)}: {len(lst)} tiles -> {lst[:12]}")
