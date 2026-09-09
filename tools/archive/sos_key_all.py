"""Chroma-key de fundo preto em TODOS os frames SoS (recursivo em assets/sos)."""
import os
from collections import deque
from PIL import Image

BASE = os.path.join("assets", "sos")


def key_black_borders(path: str) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()
    seen = set()
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
        if (x, y) in seen or x < 0 or y < 0 or x >= w or y >= h:
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if not (r < 18 and g < 18 and b < 18 and a > 200):
            continue
        px[x, y] = (0, 0, 0, 0)
        removed += 1
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    img.save(path)


def main() -> None:
    count = 0
    for dirpath, _, files in os.walk(BASE):
        for f in files:
            if f.endswith(".png") and not f.endswith(".import"):
                key_black_borders(os.path.join(dirpath, f))
                count += 1
    print("frames processados:", count)


if __name__ == "__main__":
    main()
