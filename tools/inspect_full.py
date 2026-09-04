from PIL import Image, ImageDraw

img = Image.open("assets/tilesets/edermunizz_overworld.png").convert("RGBA")
bg = Image.new("RGBA", img.size, (25, 30, 40, 255))
bg.alpha_composite(img)
zoom = bg.resize((img.width * 3, img.height * 3), Image.NEAREST)
draw = ImageDraw.Draw(zoom)
for c in range(0, img.width + 1, 16):
    draw.line([(c * 3, 0), (c * 3, zoom.height)], fill=(255, 0, 0), width=1)
    if c * 3 + 4 < zoom.width:
        draw.text((c * 3 + 4, 3), str(c // 16), fill=(255, 255, 0))
for r in range(0, img.height + 1, 16):
    draw.line([(0, r * 3), (zoom.width, r * 3)], fill=(255, 0, 0), width=1)
    if r * 3 + 4 < zoom.height:
        draw.text((3, r * 3 + 4), str(r // 16), fill=(255, 255, 0))
zoom.convert("RGB").save("tools/qa_shots/zoom_full_atlas.png")
print("ok")
