import re

data = open("tools/overworld.zip", "rb").read().decode("utf-8", errors="replace")
print("tamanho html:", len(data))
# Procura qualquer URL com /file/ ou .zip
for pattern in [r'(https?://[^"\']*\.zip[^"\']*)', r'(?:"|\')([^"\']*\/file\/[^"\']*)', r'window\.location[^;]*']:
    m = re.findall(pattern, data)
    if m:
        print("ACHOU", pattern[:20], ":", m[:3])
