import re

data = open("tools/overworld2.zip", "rb").read().decode("utf-8", errors="replace")
print("tamanho:", len(data))
found = False
for pat in [r'data-upload_url="([^"]+)"', r"download_url = ['\"]([^'\"]+)", r'href="([^"]+/file/[^"]+)"']:
    m = re.findall(pat, data)
    if m:
        print("ACHOU:", m[0][:200])
        found = True
if not found:
    print("sem link; forms:")
    for m in re.findall(r'<form[^>]+action="([^"]+)"', data):
        print("form:", m)
