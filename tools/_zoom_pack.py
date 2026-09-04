"""Zooms das regiões não exploradas do pack: type 2, shadows, prefab montanhas."""
from PIL import Image, ImageDraw

files = {
    "type2": "tools/edermunizz/Free Pixel Art overworld tileset/PNG/overworld type 2.png",
    "shadows": "tools/edermunizz/Free Pixel Art overworld tileset/PNG/overworld with shadows.png",
    "prefab": "tools/edermunizz/Free Pixel Art overworld tileset/PNG/Prefab mountains and clounds.png",
}
for name, path in files.items():
    img = Image.open(path).convert("RGBA")
    zoom = img.resize((img.width * 4, img.height * 4), Image.NEAREST)
    bg = Image.new("RGBA", zoom.size, (30, 30, 40, 255))
    bg.alpha_composite(zoom)
    bg.convert("RGB").save(f"tools/qa_shots/zoom4_{name}.png")
    print(name, img.size)
