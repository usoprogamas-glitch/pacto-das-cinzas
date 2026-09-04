from PIL import Image

root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\texturas"
atlas = Image.open(root + r"\Brugaves_atlas-i.png").convert("RGBA")
pal = Image.open(root + r"\Brugaves_OriginalColor_palette-i.png").convert("RGBA")

apx = atlas.load()
ppx = pal.load()
out = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
opx = out.load()

for y in range(256):
    for x in range(256):
        r, g, b, a = apx[x, y]
        idx = r
        pr, pg, pb, pa = ppx[idx, 0]
        if pr == 255 and pg == 0 and pb == 255:
            opx[x, y] = (0, 0, 0, 0)
        else:
            opx[x, y] = (pr, pg, pb, 255)

out.save("tools/qa_shots/reconstruct_test.png")
print("ok")
