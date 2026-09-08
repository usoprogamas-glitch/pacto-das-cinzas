# -*- coding: utf-8 -*-
"""Despeckle de retratos pixel-art: remove pixels orfãos (isolados) fundindo-os
na cor dominante dos vizinhos. Conserva clusters grandes (o desenho) — só limpa
o ruído granular de AI. Padrão de cleanup de ferramentas de pixel art."""
from PIL import Image
import collections


def orphan_cleanup(path, strength=1, min_cluster=2, contrast=26):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()
    removed = 0
    for _pass in range(strength):
        orphans = []
        for y in range(h):
            for x in range(w):
                c = px[x, y]
                if c[3] < 10:
                    continue
                # vizinhança 8-conexa: cores aproximadas por bucket 24
                neigh = collections.Counter()
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            n = px[nx, ny]
                            if n[3] >= 10:
                                key = (n[0] // contrast, n[1] // contrast, n[2] // contrast)
                                neigh[key] += 1
                key = (c[0] // contrast, c[1] // contrast, c[2] // contrast)
                own = neigh.get(key, 0)
                total = sum(neigh.values())
                # órfão: cluster próprio <= min_cluster-1 e tem vizinhança dominante clara
                if own <= min_cluster - 1 and total >= 3:
                    dominant_key = neigh.most_common(1)[0][0]
                    orphans.append((x, y, dominant_key))
        for x, y, key in orphans:
            r, g, b = key[0] * contrast + 12, key[1] * contrast + 12, key[2] * contrast + 12
            px[x, y] = (r, g, b, px[x, y][3])
            removed += 1
    img.save(path)
    return removed


for name in ["pixel_garm", "pixel_lira"]:
    path = r"assets\portraits\%s.png" % name
    removed = orphan_cleanup(path, strength=2)
    print("%s: %d pixels orfãos fundidos" % (name, removed))
