path = "scripts/game_manager.gd"
lines = open(path, encoding="utf-8").read().splitlines()
# Localiza a função _restore_save e corrige o bloco party_data para base de 1 espaço.
start = next(i for i, l in enumerate(lines) if l.startswith("func _restore_save"))
end = next(i for i in range(start, len(lines)) if lines[i].startswith("func ") and i > start)
fixed = 0
for i in range(start, end):
    stripped = lines[i].lstrip(" ")
    if stripped.startswith(("if save_data.has(\"party_data\")", "# JSON devolve", "party_data.clear()", "for member in save_data.party_data", "if member is Dictionary", "party_data.append(member)", "return true")):
        depth = 1
        if stripped.startswith(("if member is", "party_data.append")):
            depth = 2
        if stripped.startswith(("party_data.clear", "for member", "# JSON", "return true", "if save_data.has")):
            depth = 1
        lines[i] = " " * depth + stripped
        fixed += 1
open(path, "w", encoding="utf-8", newline="").writelines(l + "\n" for l in lines)
print("linhas corrigidas:", fixed)
