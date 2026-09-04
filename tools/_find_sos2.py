import os

base = r"C:\Users\Administrator\Downloads"
names = os.listdir(base)
print("total itens:", len(names))
for n in names:
    if "S" in n.upper() and ("SEA" in n.upper() or "STAR" in n.upper()):
        print("MATCH:", repr(n))
# Printa os 20 primeiros para diagnóstico
for n in names[:20]:
    print("  ", repr(n))
