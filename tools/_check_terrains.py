import re

text = open("scripts/pixel_art_renderer.gd", encoding="utf-8").read()
keys = re.findall(r'^\s+"(\w+)": \{', text, re.M)
print("TERRAINS keys:", [k for k in keys if k in ("grass", "water", "stone", "lava", "forest", "cave", "castle", "snow", "volcanic")])
m = re.search(r'"volcanic": \{', text)
print("tem 'volcanic' em TERRAINS:", bool(m))
