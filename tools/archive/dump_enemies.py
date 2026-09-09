import re

text = open("scripts/enemy_database.gd", encoding="utf-8").read()
pattern = re.compile(r'"(\w+)": \{[^{}]*?"hp": (\d+),[^{}]*?"atk": (\d+),[^{}]*?"def": (\d+)', re.S)
for m in pattern.finditer(text):
    print(f"{m.group(1):22} hp={m.group(2):>4} atk={m.group(3):>3} def={m.group(4):>3}")
