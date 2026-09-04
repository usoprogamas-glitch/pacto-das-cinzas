from PIL import Image

root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\texturas"
atlas = Image.open(root + r"\Brugaves_atlas-i.png").convert("RGBA")
pal = Image.open(root + r"\Brugaves_OriginalColor_palette-i.png").convert("RGBA")
print("atlas:", atlas.size, "| paleta:", pal.size)

# Amostra: alguns pixels do atlas e as primeiras cores da paleta
apx = atlas.load()
ppx = pal.load()
print("atlas (0,0):", apx[0, 0], " (50,50):", apx[50, 50], " (100,100):", apx[100, 100])
print("paleta pixels:", [ppx[x, 0] for x in range(0, min(pal.width, 12))])
if pal.height > 1:
    print("paleta linha 1:", [ppx[x, 1] for x in range(0, min(pal.width, 12))])
