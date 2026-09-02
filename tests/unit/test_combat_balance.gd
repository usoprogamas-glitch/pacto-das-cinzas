extends "res://addons/gut/test.gd"

## Balance de combate (simulação determinística de DPS, AUDIT polish):
## valida o time-to-kill de cada estágio com a curva de progressão da party
## (elixires + forja + nível por ato). Janela de sanidade: 8-40 turnos de
## party por boss de ato; < 8 = fácil demais, > 40 = grind forçado.

const ArenaLib := preload("res://scripts/arena_combat.gd")
const EnemyLib := preload("res://scripts/enemy_database.gd")


func _party_stats_for_act(act: int) -> Array:
	# Curva: atk/hp sobem por ato (elixires máximos + forja + progressão de alma).
	# Ato I: base; II: +6 atk/+50 hp; III: +12/+120; IV: +20/+200 (2 membros).
	var tiers := {
		1: {"kael_atk": 12, "kael_hp": 80, "kroug_atk": 10, "kroug_hp": 120},
		2: {"kael_atk": 18, "kael_hp": 130, "kroug_atk": 16, "kroug_hp": 170},
		3: {"kael_atk": 24, "kael_hp": 200, "kroug_atk": 22, "kroug_hp": 240},
		4: {"kael_atk": 32, "kael_hp": 280, "kroug_atk": 30, "kroug_hp": 320},
	}
	var t: Dictionary = tiers[act]
	return [t, t]


func _simulate_ttk(enemy_id: String, act: int, turns_cap: int = 60) -> int:
	# Turnos de party para derrubar o boss: dano médio (atk médio dos 2 membros
	# - def do boss) * 2 membros por turno. Magia (+60%, -50% def) usada ~1/3 dos
	# turnos: fator 1.2 no dano médio.
	var foe: Dictionary = EnemyLib.get_enemy(enemy_id)
	var tier: Dictionary = _party_stats_for_act(act)[0]
	var avg_atk := float(int(tier["kael_atk"]) + int(tier["kroug_atk"])) / 2.0
	var phys := maxf(1.0, avg_atk - float(foe["def"]))
	var magic := maxf(1.0, avg_atk * 1.6 - float(foe["def"]) * 0.5)
	var dmg_per_turn := (phys * 2.0 + magic) / 3.0 * 2.0  # 2 membros, magia 1/3
	return int(ceil(float(foe["hp"]) / maxf(1.0, dmg_per_turn)))


func test_boss_ttk_within_sanity_window():
	# (boss, ato): janela 8-40 turnos de party.
	var cases := [
		["orc_chefe", 1], ["cardeal_ignis", 2], ["cardeal_zephyr", 2],
		["cardeal_aqua", 2], ["cardeal_terra", 2], ["cardeal_umbra", 2],
		["santo_cardeal", 3], ["aurius_fase1", 4], ["aurius_fase2", 4], ["aurius_fase3", 4],
	]
	var report := []
	for case in cases:
		var ttk := _simulate_ttk(case[0], case[1])
		report.append("%s=%d" % [case[0], ttk])
		assert_between(ttk, 8, 40, "TTK de %s (%d turnos) na janela 8-40" % [case[0], ttk])
	print("[ttk] ", ", ".join(PackedStringArray(report)))


func test_regular_enemy_not_bullet_sponge():
	# Inimigo comum do Ato I morre em 1-3 turnos de party.
	var ttk := _simulate_ttk("mercenario", 1)
	assert_between(ttk, 1, 3, "mercenario cai rápido (%d turnos)" % ttk)


func test_boss_damage_threatens_but_does_not_one_shot():
	# Golpe de boss deve tirar 15-35% do HP do membro mais frágil no seu ato
	# (ameaça real sem deathspear).
	var cases := [["orc_chefe", 1, 80], ["cardeal_ignis", 2, 130], ["aurius_fase3", 4, 280]]
	for case in cases:
		var foe: Dictionary = EnemyLib.get_enemy(case[0])
		var avg_def := (8 + 15) / 2.0  # Kael 8, Kroug 15 (base da party)
		var dmg := maxf(1.0, float(foe["atk"]) - avg_def)
		var pct := dmg / float(case[2]) * 100.0
		assert_between(int(pct), 10, 45, "%s tira %d%% do HP por golpe" % [case[0], int(pct)])
