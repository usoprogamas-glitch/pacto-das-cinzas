import os

# Procura a pasta Sea of Stars em locais prováveis
roots = [
    r"C:\Users\Administrator\Downloads\jogos",
    r"C:\Users\Administrator\Downloads\Compressed",
    r"C:\Users\Administrator\Desktop",
    r"C:\Games",
    r"D:\\",
]
for root in roots:
    if not os.path.isdir(root):
        continue
    try:
        for n in os.listdir(root):
            if "sea" in n.lower() and "star" in n.lower():
                print("ACHOU:", os.path.join(root, n))
    except PermissionError:
        print("sem permissão:", root)
