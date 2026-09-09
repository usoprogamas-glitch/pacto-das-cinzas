import csv
import re
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Heróis candidatos: Valere/Zale/Garl + walk em direções
walk = defaultdict(lambda: defaultdict(list))
for row in rows:
    m = re.match(r"^(\w+?)_Walk_D(\d)_F(\d+)$", row[1])
    if m:
        walk[m.group(1)][int(m.group(2))].append(row[1])

print("personagens com Walk_D:", len(walk))
for char in sorted(walk):
    dirs = sorted(walk[char].keys())
    total = sum(len(v) for v in walk[char].values())
    print(f"  {char}: dirs {dirs} ({total} frames)")
