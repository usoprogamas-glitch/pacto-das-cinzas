import csv
import re
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

# Zale e Valere têm prefixos de DLC/Combate — busca ampla
for hero in ["Zale", "Valere"]:
    names = [r[1] for r in rows if re.match(rf"^\w*{hero}\w*_", r[1])]
    print(f"== {hero}: {len(names)} assets ==")
    # Extrai ações únicas (tudo antes de _D#_F## ou _D#)
    acts = defaultdict(int)
    for n in names:
        m = re.match(r"^(.+)_D\d+_F\d+$", n)
        if m:
            base = re.sub(r"(Loop\d+|TightenKnot|GasSpin)$", "", m.group(1))
            acts[base] += 1
    top = sorted(acts.items(), key=lambda kv: -kv[1])[:12]
    for a, c in top:
        print(f"   {a}: {c}")
