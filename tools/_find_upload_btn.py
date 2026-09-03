data = open("tools/overworld_new.zip", "rb").read().decode("utf-8", errors="replace")
# O upload_list tem o botão de download com a URL /download/<upload_key>
i = data.find('upload_list_3644435')
segment = data[i:i + 2500]
j = 0
while True:
    j = segment.find("href=", j)
    if j < 0:
        break
    print(segment[j:j + 180].replace("\n", " "))
    j += 5
