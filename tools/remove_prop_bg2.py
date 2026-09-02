#!/usr/bin/env python3
"""Flood-fill de fundo por CANTO (cada canto tem sua própria cor-alvo).
Pega fundos que variam entre bordas (ex: fogueira com canto escuro)."""
import os
from collections import deque
from PIL import Image

DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "props")


def remove_bg_multi(path: str) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]

    def flood_from(sx: int, sy: int) -> int:
        target = px[sx, sy]
        tr, tg, tb = target[0], target[1], target[2]
        seen = set()
        q = deque([(sx, sy)])
        removed = 0
        while q:
            x, y = q.popleft()
            if (x, y) in seen or x < 0 or y < 0 or x >= w or y >= h:
                continue
            seen.add((x, y))
            r, g, b, a = px[x, y]
            if abs(r - tr) > 30 or abs(g - tg) > 30 or abs(b - tb) > 30:
                continue
            px[x, y] = (0, 0, 0, 0)
            removed += 1
            q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
        return removed

    total = sum(flood_from(x, y) for x, y in corners)
    img.save(path)
    print(f"{os.path.basename(path)}: {total}px")


def main() -> None:
    for fname in sorted(os.listdir(DIR)):
        if fname.endswith(".png") and not fname.endswith(".import"):
            remove_bg_multi(os.path.join(DIR, fname))


if __name__ == "__main__":
    main()
