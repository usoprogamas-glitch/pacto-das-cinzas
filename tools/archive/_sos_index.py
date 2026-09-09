import csv
import re
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    first = f.readline()
print("HEADER:", first[:200])

with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    reader = csv.reader(f, delimiter=";")
    rows = list(reader)
print("total linhas:", len(rows))
print("primeiras 3:", rows[:3])

# Agrupa por prefixo de personagem (antes de _D#_F##)
by_char = defaultdict(int)
actions = defaultdict(set)
dirs = set()
pat = re.compile(r"^(?P<char>.+?)_(?P<act>[A-Za-z]+)(?:Loop\d*)?_D(?P<dir>\d)_F(?P<frame>\d+)\.png$", re.I)
for row in rows[1:]:
    if len(row) < 2:
        continue
    name = row[1]
    m = pat.match(name)
    if m:
        by_char[m.group("char")] += 1
        actions[m.group("char")].add(m.group("act").lower())
        dirs.add(m.group("dir"))
print("personagens com ciclo animado:", len(by_char))
# Top 15 por volume
top = sorted(by_char.items(), key=lambda kv: -kv[1])[:15]
for char, count in top:
    print(f"  {char}: {count} frames | acoes: {sorted(actions[char])[:8]}")
