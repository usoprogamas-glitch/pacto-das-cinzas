import re

t = open(r'scripts\map_database.gd', encoding='utf-8').read()
# blocos N: { ... }, de topo (aproximacao: pares de chaves balanceadas por regex simples)
blocks = re.split(r'\n\s*(\d+): \{', t)
# blocks: ['', '0', '...corpo...', '1', '...corpo...', ...]
print('mapa | soul_ether | xp | pool inimigos')
for i in range(1, len(blocks) - 1, 2):
    mid = int(blocks[i])
    body = blocks[i + 1]
    # corta no primeiro "tiles": (geradores tem dicionarios enormes)
    cut = body.find('"tiles"')
    if cut != -1:
        body = body[:cut]
    se = sum(int(x) for x in re.findall(r'"soul_ether": (\d+)', body))
    xp = sum(int(x) for x in re.findall(r'"xp": (\d+)', body))
    pools = re.findall(r'"enemies": \[([^\]]*)\]', body)
    names = []
    for p in pools:
        names += re.findall(r'"(\w+)"', p)
    print(f'{mid:3d} | se={se:3d} | xp={xp:3d} | {names}')

# enemy soul_ether por tipo
ed = open(r'scripts\enemy_database.gd', encoding='utf-8').read()
print('\nenemy soul_ether:')
for m in re.finditer(r' (\w+"): \{[^{}]*?"soul_ether": (\d+)', ed):
    pass
for m in re.finditer(r'("[\w]+): \{\s*"name": "[^"]*",\s*"class": "[^"]*",\s*"hp": (\d+),\s*"atk": (\d+),\s*"def": (\d+),[^{}]*?"soul_ether": (\d+)', ed):
    print(m.group(1), 'hp', m.group(2), 'atk', m.group(3), 'def', m.group(4), 'se', m.group(5))
