import re

path = "scripts/enemy_database.gd"
text = open(path, encoding="utf-8").read()

# (id, campo, antigo, novo) — calibração TTK 8-40 turnos (simulação test_combat_balance)
changes = [
    ("mercenario", "hp", 60, 45), ("mercenario", "def", 10, 5),
    ("inquisidor", "hp", 80, 60), ("inquisidor", "def", 12, 7),
    ("paladino", "hp", 150, 140), ("paladino", "def", 30, 12),
    ("troll", "hp", 200, 170), ("troll", "def", 25, 10),
    ("orc_chefe", "atk", 18, 24),
    ("santo_cardeal", "def", 40, 18),
    ("cardeal_ignis", "hp", 500, 320), ("cardeal_ignis", "def", 30, 16),
    ("cardeal_zephyr", "hp", 450, 300), ("cardeal_zephyr", "def", 20, 14),
    ("cardeal_aqua", "hp", 480, 300), ("cardeal_aqua", "def", 25, 12),
    ("cardeal_terra", "hp", 600, 380), ("cardeal_terra", "def", 50, 15), ("cardeal_terra", "atk", 28, 32),
    ("cardeal_umbra", "hp", 420, 300), ("cardeal_umbra", "def", 22, 12),
    ("aurius_fase1", "hp", 800, 600), ("aurius_fase1", "def", 40, 20),
    ("aurius_fase2", "hp", 600, 550), ("aurius_fase2", "def", 30, 16),
    ("aurius_fase3", "def", 15, 10),
]
applied = 0
for enemy_id, field, old, new in changes:
    block_re = re.compile(
        '("' + enemy_id + '": \\{[^{}]*?)("' + field + '": )' + str(old) + r"\b")
    new_text, n = block_re.subn(lambda m: m.group(1) + m.group(2) + str(new), text, count=1)
    if n == 1:
        text = new_text
        applied += 1
    else:
        print("NAO ACHOU:", enemy_id, field, old)
open(path, "w", encoding="utf-8", newline="").write(text)
print(f"{applied}/{len(changes)} mudancas aplicadas")
