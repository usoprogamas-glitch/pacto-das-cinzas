import os
import shutil

src_root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\sprites"
dest_root = os.path.join("assets", "sos_clean", "_portraits")
os.makedirs(dest_root, exist_ok=True)
WANTED = [
    "dialog-portrait-NarcisKingZale",
    "dialog-portrait-zaleDLCThroes", "dialog-portrait-zaleDLCThroes-Determined",
    "dialog-portrait-valereDLCThroes", "dialog-portrait-ValereDLCThroes_Determined",
    "dialog-portrait-Brugaves", "dialog-portrait-Moraine",
    "dialog-portrait-Garl",
]

copied = 0
for dirpath, _, files in os.walk(src_root):
    for f in files:
        base = f[:-4] if f.endswith(".png") else f
        if base in WANTED and f.endswith(".png"):
            dest = os.path.join(dest_root, f)
            if not os.path.exists(dest):
                shutil.copy2(os.path.join(dirpath, f), dest)
                copied += 1
print("retratos copiados:", copied)
for f in sorted(os.listdir(dest_root)):
    print(" ", f)
