import re

text = open("scripts/sprite_motion_library.gd", encoding="utf-8").read()
idx = text.find('"idle"')
print(text[max(0, idx - 300):idx + 600])
