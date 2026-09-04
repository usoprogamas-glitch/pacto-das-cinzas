import csv
import re
import os
from PIL import Image, ImageDraw

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
sprites_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

CANDIDATES = ["Acolyte2", "Anointed", "Grassassin", "ClockZombie", "CultistSummoner",
              "Erlina", "Aephorul", "Croube", "Fungtoise", "Gulgul", "Firecracker", "Coilemur",
              "StrifeMinion", "Owlsassin", "BilePile", "Keymouseter", "BoulderDouche", "BoulderGoat"]

# Frame Idle_D3 de cada candidato
frames = {}
for row in rows:
    for c in CANDIDATES:
        if row[1] == f"{c}_Idle_D3_F00":
            for dirpath, _, files in os.walk(sprites_root):
                if row[1] + ".png" in files:
                    frames[c] = os.path.join(dirpath, row[1] + ".png")

# Contact sheet: 6 colunas x 3 linhas, cada frame 128px + rótulo
cell = 128
sheet = Image.new("RGB", (cell * 6, (cell + 24) * ((len(CANDIDATES) + 5) // 6)), (30, 30, 40))
draw = ImageDraw.Draw(sheet)
for i, c in enumerate(CANDIDATES):
    x = (i % 6) * cell
    y = (i // 6) * (cell + 24)
    if c in frames:
        t = Image.open(frames[c]).convert("RGBA")
        bgc = Image.new("RGBA", t.size, (60, 60, 75, 255))
        bgc.alpha_composite(t)
        scale = min(cell / t.width, (cell + 24) / t.height)
        t = t.resize((max(1, int(t.width * scale)), max(1, int(t.height * scale))), Image.NEAREST)
        bgc = Image.new("RGBA", (cell, cell), (60, 60, 75, 255))
        bgc.alpha_composite(t, ((cell - t.width) // 2, (cell - t.height) // 2))
        sheet.paste(bgc.convert("RGB"), (x, y))
    draw.text((x + 4, y + cell + 4), c, fill=(255, 255, 120))
sheet.save("tools/qa_shots/monster_candidates.png")
print("sheet salvo com", len(frames), "frames de", len(CANDIDATES), "candidatos")
