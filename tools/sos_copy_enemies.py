import csv
import re
import os
import shutil
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
sprites_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
base_dest = os.path.join("assets", "sos")

# Mapeamento inimigo do jogo -> personagem SoS com Idle/Walk.
ENEMY_CHARS = {
    "mercenario": "StrifeMinion",
    "cacador": "Owlsassin",
    "esqueleto": "BilePile",
    "mago": "Keymouseter",
    "inquisidor": "Acolyte1",
    "paladino": "Acolyte4",
    "orc_chefe": "BoulderDouche",
    "troll": "BoulderGoat",
}

with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Indexa: char -> {nome arquivo}
available = defaultdict(dict)
for row in rows:
    m = re.match(r"^(\w+?)_(Idle|Walk)_D(\d)_F(\d+)$", row[1])
    if m:
        available[m.group(1)][row[1]] = row

copied = 0
for game_type, sos_char in ENEMY_CHARS.items():
    files = available.get(sos_char, {})
    if not files:
        print(f"AVISO: {sos_char} sem frames")
        continue
    dest_root = os.path.join(base_dest, sos_char)
    for name, row in files.items():
        src = None
        for dirpath, _, fs in os.walk(sprites_root):
            if name + ".png" in fs:
                src = os.path.join(dirpath, name + ".png")
                break
        if src is None:
            continue
        dest = os.path.join(dest_root, name + ".png")
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(src, dest)
        copied += 1
print("copiados:", copied)
