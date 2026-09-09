"""Decodificador dos sprites SoS (formato atlas indexado + paleta 256x1).
Reconstrói qualquer personagem: cor_real = paleta[atlas_pixel.R].
Gera frames limpos em assets/sos_clean/<Char>/ para o SOSMotionLoader.
NÃO commitado (assets/sos_clean/ no .gitignore)."""
import os
import re
import sys
from PIL import Image

TEXTURAS = r"C:\Users\Administrator\Downloads\test\assets_extraidos\texturas"
OUT_ROOT = os.path.join("assets", "sos_clean")


def decode_character(char: str, out_root: str = OUT_ROOT) -> int:
    atlas_path = os.path.join(TEXTURAS, f"{char}_atlas-i.png")
    pal_path = os.path.join(TEXTURAS, f"{char}_OriginalColor_palette-i.png")
    if not os.path.exists(atlas_path) or not os.path.exists(pal_path):
        print("faltando atlas/paleta:", char)
        return 0
    atlas = Image.open(atlas_path).convert("RGBA")
    pal = Image.open(pal_path).convert("RGBA")
    apx = atlas.load()
    ppx = pal.load()
    out = Image.new("RGBA", atlas.size, (0, 0, 0, 0))
    opx = out.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            r, g, b, a = apx[x, y]
            pr, pg, pb, pa = ppx[r, 0]
            if pr == 255 and pg == 0 and pb == 255:
                continue
            opx[x, y] = (pr, pg, pb, 255)

    # Corta bounding box global (remove vazio)
    bbox = out.getbbox()
    if bbox is None:
        print("atlas vazio:", char)
        return 0
    out = out.crop(bbox)
    dest = os.path.join(out_root, f"{char}_sheet.png")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    out.save(dest)
    print(f"OK {char}: {out.size} -> {dest}")
    return 1


def main():
    chars = sys.argv[1:] if len(sys.argv) > 1 else default_chars()
    ok = 0
    for c in chars:
        ok += decode_character(c)
    print(f"decodificados: {ok}/{len(chars)}")


def default_chars():
    return ["Brugaves", "Garl", "NarcisKingZale", "Valere", "Zale", "Moraine",
            "StrifeMinion", "Owlsassin", "BilePile", "Keymouseter", "Acolyte1",
            "Acolyte4", "BoulderDouche", "BoulderGoat", "Aephorul", "Erlina",
            "Anointed", "CultistSummoner", "Croube", "Fungtoise", "Coilemur",
            "Dynamouse", "Grassassin", "ClockZombie", "Arentee", "Braidzard",
            "DukeAventry", "Gulgul", "Firecracker", "DocarriOracle"]


if __name__ == "__main__":
    main()
