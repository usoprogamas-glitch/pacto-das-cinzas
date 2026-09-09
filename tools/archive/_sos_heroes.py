import csv
import re
from collections import defaultdict

csv_path = r"C:\Users\Administrator\Downloads\test\assets_extraidos\indice_assets.csv"
with open(csv_path, encoding="utf-8-sig", errors="replace") as f:
    rows = list(csv.reader(f, delimiter=";"))[1:]

heroes = ["Valere", "Zale", "Garl", "Brugaves", "Sernoi", "Serai", "Moraine"]
for hero in heroes:
    matching = [r[1] for r in rows if r[1].startswith(hero + "_")]
    # Agrupa por ação
    actions = defaultdict(lambda: defaultdict(list))
    for name in matching:
        m = re.match(r"^\w+_Idle_D(\d)_F(\d+)$", name)
        if m:
            actions["Idle"][int(m.group(1))].append(name)
        m = re.match(r"^(\w+?)_Walk_D(\d)_F(\d+)$", name)
        if m and m.group(1) == hero:
            actions["Walk"][int(m.group(2))].append(name)
    if actions:
        print(f"== {hero} ==")
        for act in actions:
            print(f"  {act}: dirs {sorted(actions[act].keys())}, frames/dir {[len(v) for v in sorted(actions[act].values())]}")
        # amostra de nomes
        all_names = [n for v in actions.values() for vv in v.values() for n in vv][:3]
        for n in all_names:
            print("    ex:", n)
