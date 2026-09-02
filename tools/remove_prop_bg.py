#!/usr/bin/env python3
"""Remove o fundo cinza dos props finais (flood-fill a partir dos cantos).
Roda sobre assets/props/*.png in-place; raws ficam intactos."""
import os
from collections import deque
from PIL import Image

DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "props")


def remove_bg(path: str) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()
    # Cor de fundo = média dos 4 cantos (o prompt pede cinza uniforme).
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    br = sum(c[0] for c in corners) // 4
    bg_c = sum(c[1] for c in corners) // 4
    bb = sum(c[2] for c in corners) // 4

    def is_bg(r, g, b, a) -> bool:
        return abs(r - br) < 38 and abs(g - bg_c) < 38 and abs(b - bb) < 38

    # Flood-fill dos cantos (não apaga cinza DENTRO do prop, tipo pedra do chão).
    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    removed = 0
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
            continue
        seen[y][x] = True
        r, g, b, a = px[x, y]
        if not is_bg(r, g, b, a):
            continue
        px[x, y] = (0, 0, 0, 0)
        removed += 1
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    img.save(path)
    print(f"{os.path.basename(path)}: fundo removido ({removed}px)")


def main() -> None:
    for fname in sorted(os.listdir(DIR)):
        if fname.endswith(".png") and not fname.endswith(".import"):
            remove_bg(os.path.join(DIR, fname))


if __name__ == "__main__":
    main()
