import os

base = r"C:\Users\Administrator\Downloads"
for n in os.listdir(base):
    if "sea" in n.lower():
        full = os.path.join(base, n)
        print(repr(n), "isdir:", os.path.isdir(full))
