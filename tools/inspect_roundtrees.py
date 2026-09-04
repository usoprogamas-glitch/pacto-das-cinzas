from PIL import Image, ImageDraw

img = Image.open("assets/tilesets/edermunizz_overworld.png").convert("RGBA")
crop = img.crop((176, 48, 272, 112))  # cols 11-16, rows 3-7
zoom = crop.resize((crop.width * 6, crop.height * 6), Image.NEAREST)
bg = Image.new("RGBA", zoom.size, (25, 30, 40, 255))
bg.alpha_composite(zoom)
draw = ImageDraw.Draw(bg.convert("RGB"))
for gx in range(0, crop.width + 1, 8):
    draw.line([(gx * 6, 0), (gx * 6, bg.height)], fill=(120, 120, 200), width=1)
for gy in range(0, crop.height + 1, 8):
    draw.line([(0, gy * 6), (bg.width, gy * 6)], fill=(120, 120, 200), width=1)
bg.convert("RGB").save("tools/qa_shots/zoom6_roundtrees.png")
print("ok cols 11-16 rows 3-7")
