extends "res://addons/gut/test.gd"

## Smoke automático do Painel de Ações §6-7.
## Valida a CADEIA runtime completa por botão:
##   handler do painel -> sistema emite sinal -> _on_* consome ->
##   progression_system atualiza -> _update_progression_hud() -> labels mudam
##   + toast (combat_feedback.show_status_effect) emitido.
## Complementa test_battle_actions.gd, que só valida a emissão do sinal.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node
# toasts capturados pelo stub do combat_feedback
var _toasts: Array[String] = []


func before_each() -> void:
	bs = BattleSceneScript.new()
	bs.combat_feedback = _make_combat_feedback_stub()
	# Monta progress_system + os 4 sistemas §6-7 e conecta os sinais
	# (mesma ligação de setup_systems(), sem montar a cena .tscn)
	bs.progression_system = preload("res://scripts/narrative/progression_system.gd").new()
	bs.traversal_system = preload("res://scripts/battle/traversal_system.gd").new()
	bs.campfire_system = preload("res://scripts/battle/campfire_system.gd").new()
	bs.cooking_system = preload("res://scripts/battle/cooking_system.gd").new()
	bs.tavern_minigame = preload("res://scripts/battle/tavern_minigame.gd").new()
	bs.traversal_system.traversal_completed.connect(bs._on_traversal_completed)
	bs.campfire_system.rest_completed.connect(bs._on_camp_rest_completed)
	bs.cooking_system.recipe_crafted.connect(bs._on_recipe_crafted)
	bs.tavern_minigame.game_over.connect(bs._on_tavern_game_over)
	# HUD de progressão real (labels ActLabel/MemLabel/SoulLabel/XPLabel/FormLabel)
	bs.ui_layer = CanvasLayer.new()
	bs._create_progression_hud()
	bs._update_progression_hud()
	_toasts = []


func after_each() -> void:
	if is_instance_valid(bs):
		bs.free()


func _make_combat_feedback_stub() -> CombatFeedback:
	# Stub que sobreescreve show_status_effect para capturar toasts: emite
	# um signal que o teste conecta a _toasts (evita criar tweens fora da tree).
	var script = GDScript.new()
	script.source_code = """
extends CombatFeedback
signal toast(msg: String)
func show_status_effect(_pos: Vector2, msg: String) -> void:
	toast.emit(msg)
"""
	script.reload()
	var stub = CombatFeedback.new()
	stub.set_script(script)
	stub.toast.connect(func(msg: String) -> void: _toasts.append(msg))
	return stub


func _soul() -> Label:
	return bs.progression_hud.find_child("SoulLabel", true, false) as Label


func _xp() -> Label:
	return bs.progression_hud.find_child("XPLabel", true, false) as Label


func _mem() -> Label:
	return bs.progression_hud.find_child("MemLabel", true, false) as Label


# --- Travessia: +25 XP, +10 MEM, toast ---

func test_traverse_updates_hud_and_toast() -> void:
	bs._update_progression_hud()
	var xp_before: int = int(_xp().text.trim_prefix("XP "))
	bs._on_traverse_pressed()
	assert_eq(int(_xp().text.trim_prefix("XP ")), xp_before + 25, "XP subiu 25")
	assert_eq(_mem().text, "MEM 10%", "MEM subiu 10%")


# --- Acampamento: +15 XP, +5 MEM, gating 1/batalha ---

func test_camp_updates_hud_and_gates() -> void:
	bs.campfire_system.register_apostle("Kroug")
	bs._update_progression_hud()
	var xp_before: int = int(_xp().text.trim_prefix("XP "))
	bs._on_camp_pressed()
	assert_eq(int(_xp().text.trim_prefix("XP ")), xp_before + 15, "XP subiu 15 (rest_completed)")
	assert_eq(_mem().text, "MEM 5%", "MEM subiu 5%")
	var xp_after1: int = int(_xp().text.trim_prefix("XP "))
	bs._on_camp_pressed()  # gatilho: 2ª chamada só toast, sem XP extra
	assert_eq(int(_xp().text.trim_prefix("XP ")), xp_after1, "segundo uso não soma XP")


# --- Cozinhar: +20 XP, +10 MEM, gating 1/batalha ---

func test_cook_updates_hud_and_gates() -> void:
	bs._on_cook_pressed()
	assert_eq(int(_xp().text.trim_prefix("XP ")), 20, "XP subiu 20 (recipe_crafted)")
	assert_eq(_mem().text, "MEM 10%", "MEM subiu 10%")
	bs._on_cook_pressed()  # 2ª: sem receita extra, mas _cook_used já true
	assert_eq(int(_xp().text.trim_prefix("XP ")), 20, "segundo uso não soma XP")


# --- Taberna game_over: +1 ALMA, toast ---

func test_tavern_game_over_adds_soul_to_hud() -> void:
	bs._on_tavern_game_over("Jogador", "IA")
	assert_eq(_soul().text, "ALMAS 1", "game_over dobra as almas nomeadas no HUD")


# --- Toast emitido em cada ação (feedback visual) ---

func test_toast_emitted_per_action() -> void:
	bs._on_traverse_pressed()
	bs._on_camp_pressed()
	bs._on_cook_pressed()
	bs._on_tavern_game_over("IA", "Jogador")
	assert_gt(_toasts.size(), 0, "pelo menos um toast por ação")
	assert_eq(_toasts.size(), 4, "4 toasts: travessia, camp, cook, taverna")
	assert_true(_toasts[0].begins_with("TRAVESSIA"), "toast de travessia")
