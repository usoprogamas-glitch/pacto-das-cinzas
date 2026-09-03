import re

data = open("tools/overworld2.zip", "rb").read().decode("utf-8", errors="replace")
# O interstitial "Thanks for downloading" tem o link no corpo: /download/<key>
for m in re.findall(r'href="([^"]+)"', data):
    if "download" in m:
        print("LINK:", m)
# Ou botões com onclick
for m in re.findall(r'location\s*=\s*([^;]+);', data)[:3]:
    print("LOC:", m)
