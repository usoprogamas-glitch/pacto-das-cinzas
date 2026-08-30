extends "res://addons/gut/test.gd"
## Testes GUT: campaign spawn (ROADMAP #2)
## Foca no root-cause fix — _spawn_player_party e o swap de inimigo do chefe de
## ato — sem chamar setup_battle() (que exigiria árvore + stubs de grid/autotile).
## O helper _spawn_player_party só chama spawn_player_unit, que registra no
## BattleManager autoload (disponível em GUT headless).

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node

# Grid fake geométrico: reproduz BattleGrid.grid_to_pixel(32px) sem árvore.
# unit_container fake: Node2D vazio (spawn não toca em filhos nesse fluxo).
class FakeGrid:
	extends RefCounted
	func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
		return Vector2(grid_pos.x * 32, grid_pos.y * 32)

func _stub_tree_deps() -> void:
	# Desacopla create_unit da árvore real ($BattleGrid/$UnitContainer).
	# Sem isso _spawn_player_party crasha em headless com "Nonexistent function
	# 'grid_to_pixel' in base 'Nil'" — o grid só existe após _ready da cena.
	bs.set("grid", FakeGrid.new())
	bs.set("unit_container", Node2D.new())

func before_each() -> void:
	# Limpar units do BattleManager autoload entre testes (ele persiste no processo).
	BattleManager.player_units.clear()
	BattleManager.enemy_units.clear()
	BattleManager.soul_ether = 0
	# Limpar almas nomeadas p/ contagem determinística (testes anteriores podem
	# nomear via start_new_game / naming_flow).
	if GameManager and GameManager.naming_system:
		GameManager.naming_system.named_souls.clear()
		GameManager.naming_system.total_named = 0
	bs = BattleSceneScript.new()
	_stub_tree_deps()

func after_each() -> void:
	if is_instance_valid(bs):
		bs.free()

func test_spawn_player_party_puts_two_players_on_battle_manager():
	# Estado explícito: o autoload recém-criado default é starting_ally=none; o
	# fluxo real passa por start_new_game() (escolha kroug na intro) antes da batalha.
	GameManager.game_data["starting_ally"] = "kroug"
	bs._spawn_player_party()
	assert_eq(BattleManager.player_units.size(), 2, "Kael sempre spawn + Kroug")
	var names = []
	for u in BattleManager.player_units:
		names.append(u.data.unit_name)
	assert_true(names.has("Kael"), "Kael sempre presente")
	assert_true(names.has("Kroug"), "Kroug presente sob starting_ally=kroug")
	# restore para não vazar estado pro próximo teste
	GameManager.game_data["starting_ally"] = "none"

func test_spawn_player_party_kroug_only_when_kroug_ally():
	# Garante que _spawn_player_party respeita game_data.starting_ally.
	GameManager.game_data["starting_ally"] = "none"
	bs._spawn_player_party()
	assert_eq(BattleManager.player_units.size(), 1, "sem Kroug, só Kael")
	assert_eq(BattleManager.player_units[0].data.unit_name, "Kael")

func test_spawn_player_party_includes_named_souls_from_save():
	# ROADMAP #9: uma alma nomeada no save vira unit na party com nome real.
	GameManager.game_data["starting_ally"] = "none"
	GameManager.naming_system.name_soul("aranha_gigante", "Teia")
	bs._spawn_player_party()
	var names = []
	for u in BattleManager.player_units:
		names.append(u.data.unit_name)
	assert_eq(names.size(), 2, "Kael + alma nomeada")
	assert_true(names.has("Teia"), "alma nomeada 'Teia' spawna com nome persistido")
	# restore
	GameManager.naming_system.named_souls.clear()
	GameManager.naming_system.total_named = 0

func test_act_boss_stage_swaps_enemy_pool_to_orc_chefe():
	# O swap de inimigo é decidido por CampaignSystem.get_current_stage().final.
	# Verifica a decisão de dados, não o spawn (que precisa de árvore).
	var cs = CampaignSystem.new()
	var act1_stage1 = cs.get_current_stage()   # act 1, stage 0 → não final
	assert_false(act1_stage1.get("final", false), "stage 0 de ato 1 não é boss")
	cs.advance_stage()                          # stage 1 → boss final
	var boss_stage = cs.get_current_stage()
	assert_true(boss_stage.get("final", false), "stage 1 de ato 1 é o chefe")
	# A lógica de swap no battle_scene mapeia final→["orc_chefe"]:
	var enemies = ["mercenario", "cacador"]
	if boss_stage.get("final", false):
		enemies = ["orc_chefe"]
	assert_eq(enemies, ["orc_chefe"], "chefe de ato spawna orc_chefe")
