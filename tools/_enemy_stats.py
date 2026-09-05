import re

ed = open(r'scripts\enemy_database.gd', encoding='utf-8').read()
pat = re.compile(
    r'"(\w+)": \{\s*"name": "[^"]*",\s*"class": "[^"]*",\s*'
    r'"hp": (\d+),\s*"atk": (\d+),\s*"def": (\d+),')
for m in pat.finditer(ed):
    print(m.group(1), 'hp', m.group(2), 'atk', m.group(3), 'def', m.group(4))
