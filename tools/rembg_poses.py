# -*- coding: utf-8 -*-
"""Remove fundo das poses com rembg (U2Net) — IA de segmentação, não heurística.
Processa assets/px/poses/<char>/*.png in-place (RGBA com fundo transparente)."""
import os
import io
from PIL import Image
from rembg import remove, new_session

SESSION = new_session("u2net")
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
        result = remove(img, session=SESSION)
        # corte do bbox com margem
        bbox = result.getbbox()
        if bbox:
            pad = 8
            crop = result.crop((max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                                min(result.width, bbox[2] + pad), min(result.height, bbox[3] + pad)))
        else:
            crop = result
        crop.thumbnail((192, 192), Image.LANCZOS)
        q = crop.quantize(colors=48, method=Image.FASTOCTREE, dither=Image.NONE).convert("RGBA")
        q.save(path)
        count += 1
        print("OK:", f, q.size, flush=True)
print("TOTAL:", count)
