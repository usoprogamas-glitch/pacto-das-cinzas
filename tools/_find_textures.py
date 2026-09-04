import os
import re

root = r"C:\Users\Administrator\Downloads\test\assets_extraidos\texturas"
hits = []
for dirpath, _, files in os.walk(root):
    for f in files:
        low = f.lower()
        if ("garl" in low or "brugaves" in low or "strifeminion" in low) and (".png" in low or ".t2d" in low or low.endswith((".tex", ".dds"))):
            full = os.path.join(dirpath, f)
            hits.append((full, os.path.getsize(full) // 1024))
print("hits:", len(hits))
for h in hits[:15]:
    print(f"  {h[1]} KB  {h[0]}")
