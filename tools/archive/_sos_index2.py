import csv
import re
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]
print("total:", len(rows))

# Personagens: nomes terminando _D#_F##
pat = re.compile(r"^(.+)_D(\d+)_F(\d+)$")
by_char = defaultdict(int)
actions = defaultdict(set)
for row in rows:
    m = pat.match(row[1])
    if m:
        by_char[m.group(1)] += 1
        # ação = tudo antes do último _D# no grupo 1 (ex: X_Walk)
        parts = m.group(1).rsplit("_", 1)
        if len(parts) == 2:
            actions[parts[0]].add(parts[1])

print("ciclos animados:", len(by_char))
top = sorted(by_char.items(), key=lambda kv: -kv[1])[:20]
for char, count in top:
    print(f"  {char}: {count}")
