import csv
import re
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Candidatos monstros: Idle + Walk completos em >=3 direções
cands = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
for row in rows:
    m = re.match(r"^(\w+?)_(Idle|Walk)_D(\d)_F(\d+)$", row[1])
    if m:
        cands[m.group(1)][m.group(2)][int(m.group(3))].append(row[1])

good = {}
for char, acts in cands.items():
    if "Idle" in acts and "Walk" in acts:
        idle_dirs = len(acts["Idle"])
        walk_dirs = len(acts["Walk"])
        frames_per_dir = len(next(iter(acts["Walk"].values())))
        if walk_dirs >= 3 and frames_per_dir >= 4:
            good[char] = (idle_dirs, walk_dirs, frames_per_dir)

print("candidatos monstro completos:", len(good))
for c in sorted(good):
    print(" ", c, good[c])
