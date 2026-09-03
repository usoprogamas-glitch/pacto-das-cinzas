data = open("tools/overworld_new.zip", "rb").read().decode("utf-8", errors="replace")
# Interstitial costuma conter: <a href="...zip..."> ou window.location = '...zip'
i = 0
while True:
    i = data.find(".zip", i)
    if i < 0:
        break
    start = max(0, i - 150)
    print("...", data[start:i + 10].replace("\n", " ")[-170:])
    i += 4
print("----")
# Procura iframe (downloads no itch abrem num iframe)
i = 0
while True:
    i = data.find("<iframe", i)
    if i < 0:
        break
    print(data[i:i + 260].replace("\n", " "))
    i += 7
