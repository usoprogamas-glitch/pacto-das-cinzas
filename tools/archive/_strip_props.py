path = "scripts/map_database.gd"
lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
out = []
in_props = False
removed = 0
for line in lines:
    stripped = line.strip()
    if stripped.startswith('"props"'):
        in_props = True
        indent = line[: len(line) - len(line.lstrip())]
        out.append(indent + '"props": [],\n')
        removed += 1
        continue
    if in_props:
        if stripped in ("],", "]"):
            in_props = False
            continue
        continue
    out.append(line)
open(path, "w", encoding="utf-8", newline="").writelines(out)
print("blocos props esvaziados:", removed)
