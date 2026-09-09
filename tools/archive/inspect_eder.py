"""Zoom nas regiões de castelo/cidade e árvores do atlas do Eder."""
from PIL import Image, ImageDraw

img = Image.open("assets/tilesets/edermunizz_overworld.png")
regions = {
    "castle_city": (192, 80, 304, 112),   # tiles brancos (castelos) rows 5-6
    "trees_dense": (0, 0, 64, 48),        # bloco verde escuro rows 0-2
    "mountains": (96, 16, 208, 64),       # tons 32,96,64 rows 1-3
}
for name, (x0, y0, x1, y1) in regions.items():
    crop = img.crop((x0, y0, x1, y1))
    zoom = crop.resize((crop.width * 5, crop.height * 5), Image.NEAREST)
    draw = ImageDraw.Draw(zoom)
    n = 0
    for gy in range(0, crop.height + 1, 16):
        draw.line([(0, gy * 5), (zoom.width, gy * 5)], fill=(255, 0, 0), width=1)
        for gx in range(0, crop.width + 1, 16):
            if gy == 0:
                draw.line([(gx * 5, 0), (gx * 5, zoom.height)], fill=(255, 0, 0), width=1)
            # rótulo: col,row no atlas
            draw.text((gx * 5 + 3, gy * 5 + 3), f"{(x0//16)+n}", fill=(255, 255, 0))
            n += 1
    zoom.save(f"tools/qa_shots/zoom3_{name}.png")
    print(name, "->", f"tools/qa_shots/zoom3_{name}.png")
