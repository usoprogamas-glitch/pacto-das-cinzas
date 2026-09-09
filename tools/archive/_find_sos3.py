import os

base = r"C:\Users\Administrator\Downloads"
names = os.listdir(base)
for n in names[20:]:
    print(repr(n))
