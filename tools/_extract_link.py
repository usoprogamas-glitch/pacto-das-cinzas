import re

data = open("tools/overworld.zip", "rb").read().decode("utf-8", errors="replace")
links = re.findall(r'href="([^"]*download[^"]*)"', data)
for l in links[:5]:
    print(l)
