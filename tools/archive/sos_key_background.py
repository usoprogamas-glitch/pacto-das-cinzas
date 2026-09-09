"""Chroma-key dos frames SoS: fundo preto opaco -> transparente.
Flood-fill pelas bordas (o outline interno do sprite sobrevive)."""
import os
from collections import deque
from PIL import Image

DIR = os.path.join("assets", "sos", "NarcisKingZale")


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
        # Fundo preto opaco: só remove se quase preto e opaco.
        if not (r < 18 and g < 18 and b < 18 and a > 200):
            continue
        px[x, y] = (0, 0, 0, 0)
        removed += 1
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    img.save(path)
    print(f"{os.path.basename(path)}: {removed}px removidos")


def main() -> None:
    for fname in sorted(os.listdir(DIR)):
        if fname.endswith(".png") and not fname.endswith(".import"):
            key_black_borders(os.path.join(DIR, fname))


if __name__ == "__main__":
    main()
