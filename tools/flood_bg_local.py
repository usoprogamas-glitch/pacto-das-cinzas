# -*- coding: utf-8 -*-
"""Flood-fill de fundo com DIFERENÇA LOCAL: um pixel entra se for similar ao
vizinho já removido (atravessa gradientes suaves, para em bordas do corpo).
Aplica nos raws 768px das poses do Kael e salva 192px RGBA."""
from PIL import Image
from collections import deque
import os
import sys

def remove_bg_local(img: Image.Image, tol: int = 13) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    removed = [[False] * w for _ in range(h)]

    def similar(a, b):
        return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2]) <= tol

    q = deque()
    # sementes: 4 cantos + meio das bordas
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
             (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]
    for sx, sy in seeds:
        if not removed[sy][sx]:
            q.append((sx, sy))
            removed[sy][sx] = True
    while q:
        x, y = q.popleft()
        cur = px[x, y]
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not removed[ny][nx]:
                if similar(cur, px[nx, ny]):
                    removed[ny][nx] = True
                    q.append((nx, ny))
    # pixels removidos ficam transparentes
    for y in range(h):
        row = removed[y]
        for x in range(w):
            if row[x]:
                px[x, y] = (0, 0, 0, 0)
    return img


def process(raw_path, out_path, target=192):
    img = Image.open(raw_path).convert("RGB")
    clean = remove_bg_local(img)
    bbox = clean.getbbox()
    if bbox:
        clean = clean.crop(bbox)
    clean.thumbnail((target, target), Image.LANCZOS)
    clean.save(out_path)
    print("OK", out_path, clean.size)


base = r"assets\sos_raw"
for pose in ["walk_a", "walk_b", "walk_c", "walk_d", "attack"]:
    process(
        os.path.join(base, "char_kael_%s.png" % pose),
        os.path.join("assets", "px", "poses", "char_kael", "char_kael_%s.png" % pose),
    )
