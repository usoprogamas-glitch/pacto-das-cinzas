# -*- coding: utf-8 -*-
"""Torna os sprites de personagens (assets/px/) transparentes:
processa os raws 768px com flood-fill de fundo (remove_prop_bg2),
corta bbox e salva 192px RGBA em assets/px/."""
import os
import sys

sys.path.insert(0, "tools")
from remove_prop_bg2 import remove_bg_multi
from PIL import Image

RAWS = r"assets\sos_raw"
OUT = r"assets\px"

count = 0
for f in sorted(os.listdir(RAWS)):
    if not (f.startswith("char_") or f.startswith("npc_")) or not f.endswith(".png"):
        continue
    tmp = os.path.join(os.environ.get("TEMP", "."), "cchar_tmp.png")
    img = Image.open(os.path.join(RAWS, f)).convert("RGB")
    img.save(tmp)
    remove_bg_multi(tmp)
    out = Image.open(tmp)
    bbox = out.getbbox()
    if not bbox:
        print("VAZIO:", f)
        continue
    final = out.crop(bbox)
    final.thumbnail((192, 192), Image.LANCZOS)
    q = final.quantize(colors=48, method=Image.FASTOCTREE, dither=Image.NONE).convert("RGBA")
    q.save(os.path.join(OUT, f))
    count += 1
    print("OK:", f, q.size)
print("TOTAL:", count)
