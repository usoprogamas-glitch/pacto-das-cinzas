data = open("tools/overworld2.zip", "rb").read().decode("utf-8", errors="replace")
# Printa todos os hrefs brutos (sem regex complicada)
i = 0
count = 0
while True:
    i = data.find("href=", i)
    if i < 0:
        break
    print(data[i:i + 110])
    count += 1
    i += 5
    if count > 25:
        break
