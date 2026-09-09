# -*- coding: utf-8 -*-
"""Processa as poses geradas: flood-fill de fundo + crop + salva RGBA final."""
import os
import sys

sys.path.insert(0, "tools")
from remove_prop_bg2 import remove_bg_multi
from PIL import Image

POSES = r"assets\px\poses"
count = 0
for char_dir in sorted(os.listdir(POSES)):
    cdir = os.path.join(POSES, char_dir)
    if not os.path.isdir(cdir):
        continue
    for f in sorted(os.listdir(cdir)):
        if not f.endswith(".png"):
            continue
        path = os.path.join(cdir, f)
        img = Image.open(path).convert("RGB")
        img.save(path)  # remove_bg_multi trabalha no próprio arquivo
        remove_bg_multi(path)
        out = Image.open(path)
        bbox = out.getbbox()
        if not bbox:
            print("VAZIO:", path)
            continue
        final = out.crop(bbox)
        final.thumbnail((192, 192), Image.LANCZOS)
        q = final.quantize(colors=48, method=Image.FASTOCTREE, dither=Image.NONE).convert("RGBA")
        q.save(path)
        count += 1
        print("OK:", f, q.size)
print("TOTAL:", count)
