"""Contact sheet dos frames decodificados (validação visual)."""
import os
from PIL import Image, ImageDraw

root = os.path.join("assets", "sos_clean")
frames = []
for char in ["NarcisKingZale", "Garl", "Brugaves", "StrifeMinion", "Owlsassin",
             "Keymouseter", "Acolyte1", "BoulderGoat", "Moraine"]:
    d = os.path.join(root, char)
    if not os.path.isdir(d):
        continue
    pngs = sorted(f for f in os.listdir(d) if f.endswith(".png"))
    for f in pngs[:3]:
        frames.append((char, os.path.join(d, f)))

cell = 96
cols = 9
rows = (len(frames) + cols - 1) // cols
sheet = Image.new("RGB", (cell * cols, (cell + 18) * rows), (40, 40, 55))
draw = ImageDraw.Draw(sheet)
for i, (char, path) in enumerate(frames[:54]):
    img = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", (cell, cell), (60, 60, 80, 255))
    scale = min(cell / img.width, cell / img.height, 3.0)
    img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.NEAREST)
    bg.alpha_composite(img, ((cell - img.width) // 2, (cell - img.height) // 2))
    x = (i % cols) * cell
    y = (i // cols) * (cell + 18)
    sheet.paste(bg.convert("RGB"), (x, y))
    draw.text((x + 3, y + cell + 2), char[:14], fill=(255, 255, 120))
sheet.save("tools/qa_shots/decoded_frames_sheet.png")
print("salvo com", min(len(frames), 54), "frames")
