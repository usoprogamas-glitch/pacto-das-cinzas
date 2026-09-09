# -*- coding: utf-8 -*-
"""QA de consistência de poses: paleta, bbox do corpo e visual por personagem."""
from PIL import Image
import os
import sys

sys.path.insert(0, "tools")

for char in ["char_kael", "char_kroug"]:
    cdir = os.path.join("assets", "px", "poses", char)
    if not os.path.isdir(cdir):
        continue
    print("===", char, "===")
    poses = ["walk_a", "walk_b", "walk_c", "walk_d", "attack"]
    base_means = []
    for pose in poses:
        path = os.path.join(cdir, "%s_%s.png" % (char, pose))
        if not os.path.exists(path):
            print(" ", pose, "AUSENTE")
            continue
        img = Image.open(path).convert("RGBA")
        w, h = img.size
        # bbox de pixels não transparentes (corpo)
        bbox = img.getbbox()
        body_h = bbox[3] - bbox[1] if bbox else 0
        body_w = bbox[2] - bbox[0] if bbox else 0
        # paleta: cores dominantes (top 6 clusters 32-bucket)
        px = img.convert("RGB").load()
        buckets = {}
        total = 0
        for y in range(0, h, 4):
            for x in range(0, w, 4):
                c = px[x, y]
                if c[0] > 200 and c[1] > 200 and c[2] > 200:
                    continue
                key = (c[0] // 32, c[1] // 32, c[2] // 32)
                buckets[key] = buckets.get(key, 0) + 1
                total += 1
        top = sorted(buckets.items(), key=lambda x: -x[1])[:6]
        mean_r = sum(k[0] * 32 * n for k, n in top) / max(sum(n for _, n in top), 1)
        mean_g = sum(k[1] * 32 * n for k, n in top) / max(sum(n for _, n in top), 1)
        mean_b = sum(k[2] * 32 * n for k, n in top) / max(sum(n for _, n in top), 1)
        print("  %-7s %dx%d corpo=%dx%d paleta-média=(%d,%d,%d)" % (
            pose, w, h, body_w, body_h, int(mean_r), int(mean_g), int(mean_b)))
        base_means.append((pose, int(mean_r), int(mean_g), int(mean_b), body_h))
    # consistência: delta de paleta entre walk frames e attack
    if len(base_means) >= 2:
        ref = base_means[0]
        for m in base_means[1:]:
            d = abs(m[1] - ref[1]) + abs(m[2] - ref[2]) + abs(m[3] - ref[3])
            dh = abs(m[4] - ref[4])
            flag = "OK" if d < 90 and dh < 40 else "DIVERGENTE"
            print("  delta %-7s vs %-7s: paleta %d altura %d → %s" % (m[0], ref[0], d, dh, flag))
