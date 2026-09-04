import os

# Varredura mais ampla: 2 níveis a partir de Downloads e Desktop
for base in [r"C:\Users\Administrator\Downloads", r"C:\Users\Administrator\Desktop", r"C:\Users\Administrator\Documents"]:
    for dirpath, dirnames, _ in os.walk(base):
        depth = dirpath[len(base):].count(os.sep)
        if depth > 2:
            dirnames.clear()
            continue
        for d in dirnames:
            if "sea" in d.lower() or "sos" in d.lower().replace("sós", ""):
                print("ACHOU:", os.path.join(dirpath, d))
