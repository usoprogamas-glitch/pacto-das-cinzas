# -*- coding: utf-8 -*-
"""Recupera as poses do Kael a partir dos raws 768px commitados:
copia o raw para assets/px/poses/ e roda rembg (segmentação IA, segura para
personagens verdes — diferente do chroma/flood-fill por cor que devorou o corpo)."""
import os
import shutil
import sys

sys.path.insert(0, "tools")

RAWS = "assets/sos_raw"
POSES = os.path.join("assets", "px", "poses", "char_kael")
os.makedirs(POSES, exist_ok=True)

from rembg import remove, new_session

session = new_session("u2net")
count = 0
for f in sorted(os.listdir(RAWS)):
    if not f.startswith("char_kael_") or not f.endswith(".png"):
        continue
    raw_path = os.path.join(RAWS, f)
    out_path = os.path.join(POSES, f)
    img = Image.open(raw_path).convert("RGB")
    result = remove(img, session=session)
    bbox = result.getbbox()
    if bbox:
        pad = 8
        crop = result.crop((max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                            min(result.width, bbox[2] + pad), min(result.height, bbox[3] + pad)))
    else:
        crop = result
    crop.thumbnail((192, 192), Image.LANCZOS)
    q = crop.quantize(colors=48, method=Image.FASTOCTREE, dither=Image.NONE).convert("RGBA")
    q.save(out_path)
    count += 1
    print("OK:", f, q.size, flush=True)
print("TOTAL:", count)

from PIL import Image  # noqa
