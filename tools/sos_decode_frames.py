"""Decodifica TODOS os frames individuais (sprites/) com a paleta de cada
personagem -> assets/sos_clean/<Char>/<frame>.png (cores reais, alpha correto).
Re-executável: roda de novo depois de copiar novos lotes."""
import os
import re
import sys
from PIL import Image

TEXTURAS = r"C:\Users\Administrator\Downloads\test\assets_extraidos\texturas"
SPRITES = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
OUT_ROOT = os.path.join("assets", "sos_clean")

MAGENTA = (255, 0, 255)


def load_palettes():
    pals = {}
    for f in os.listdir(TEXTURAS):
        m = re.match(r"^(\w+)_OriginalColor_palette-i\.png$", f)
        if m:
            pal = Image.open(os.path.join(TEXTURAS, f)).convert("RGBA")
            pals[m.group(1)] = pal.load()
    return pals


def decode_frame(src, pal, dst):
    img = Image.open(src).convert("RGBA")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ipx = img.load()
    opx = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = ipx[x, y]
            pr, pg, pb, pa = pal[r, 0]
            if (pr, pg, pb) == MAGENTA:
                continue
            opx[x, y] = (pr, pg, pb, 255)
    out.save(dst)


def main():
    pals = load_palettes()
    print("paletas:", len(pals))
    copied = 0
    for dirpath, _, files in os.walk(SPRITES):
        for f in files:
            m = re.match(r"^(\w+?)_(Idle|Walk|Attack)_D(\d)_(F\d+)\.png$", f)
            if not m:
                continue
            char, act, d, frame = m.groups()
            pal = pals.get(char)
            if pal is None:
                continue
            out_dir = os.path.join(OUT_ROOT, char)
            os.makedirs(out_dir, exist_ok=True)
            dst = os.path.join(out_dir, f)
            if os.path.exists(dst):
                continue  # re-executável: pula já decodificados
            try:
                decode_frame(os.path.join(dirpath, f), pal, dst)
                copied += 1
                if copied % 500 == 0:
                    print("...", copied, flush=True)
            except Exception as e:
                print("ERRO", f, e, flush=True)
    print("decodificados:", copied, flush=True)


if __name__ == "__main__":
    main()
