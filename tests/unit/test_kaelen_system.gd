extends "res://addons/gut/test.gd"

## Testes GUT para KaelenSystem (Interface Cognitiva de Kaelen, GDD v2 §3.4)


func test_analyze_target_returns_three_vectors():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"name": "Goblin", "type": "Goblin", "hp": 50, "max_hp": 50})
	assert_eq(result.has("biological"), true, "Deve ter vetor biológico")
	assert_eq(result.has("psychological"), true, "Deve ter vetor psicológico")
	assert_eq(result.has("tactical"), true, "Deve ter vetor tático")


func test_weakness_detected():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"name": "Goblin", "type": "Goblin", "hp": 50, "max_hp": 50})
	var weaknesses = result.biological.weaknesses
	assert_eq(weaknesses.size() > 0, true, "Goblin deve ter fraquezas")
	var has_fogo = false
	for w in weaknesses:
		if w.type == "Fogo":
			has_fogo = true
			assert_eq(w.bonus_percent, 40, "Goblin: Fogo +40%")
	assert_eq(has_fogo, true, "Goblin deve ser fraco a Fogo")


func test_fatigue_levels():
	var ks = KaelenSystem.new()
	var descansado = ks.analyze_target({"hp": 100, "max_hp": 100})
	assert_eq(descansado.biological.fatigue, KaelenSystem.FatigueLevel.DESCANSADO, "100% HP = Descansado")

	var critico = ks.analyze_target({"hp": 10, "max_hp": 100})
	assert_eq(critico.biological.fatigue, KaelenSystem.FatigueLevel.CRITICA, "10% HP = Crítica")


func test_armor_displayed():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"armor": 25})
	assert_eq(result.biological.armor, 25, "Armadura deve ser exibida")


func test_morale_levels():
	var ks = KaelenSystem.new()
	var alta = ks.analyze_target({"morale": 80})
	assert_eq(alta.psychological.morale, KaelenSystem.MoraleLevel.ALTA, "80 = Alta")

	var quebrada = ks.analyze_target({"morale": 10})
	assert_eq(quebrada.psychological.morale, KaelenSystem.MoraleLevel.QUEBRADA, "10 = Quebrada")


func test_flee_chance():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"morale": 10})
	assert_eq(result.psychological.flee_chance, 0.6, "Quebrada = 60% fuga")


func test_threat_level_locks():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({
		"locks": [{"type": "Corte", "remaining": 2}],
		"spell_counter": 1,
	})
	assert_eq(result.tactical.threat_level, "CRÍTICA", "Locks + counter 1 = Crítica")


func test_threat_level_no_locks():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({"locks": [], "attack_range": 1})
	assert_eq(result.tactical.threat_level, "BAIXA", "Sem locks = Baixa")


func test_suggestions_generated():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({
		"locks": [{"type": "Corte", "remaining": 1}],
	})
	assert_eq(result.suggestions.size(), 1, "Deve gerar 1 sugestão")
	assert_eq(result.suggestions[0].lock_type, "Corte", "Sugestão para Corte")


func test_suggestion_text():
	var ks = KaelenSystem.new()
	var result = ks.analyze_target({
		"locks": [{"type": "Contusão", "remaining": 2}],
	})
	assert_eq(result.suggestions[0].suggestion.contains("Kroug"), true, "Contusão → Kroug")


func test_get_weaknesses():
	var ks = KaelenSystem.new()
	var weaknesses = ks.get_weaknesses("Harpias")
	assert_eq(weaknesses.size() >= 1, true, "Harpias deve ter fraquezas")


func test_get_weaknesses_unknown():
	var ks = KaelenSystem.new()
	var weaknesses = ks.get_weaknesses("Banana")
	assert_eq(weaknesses.size(), 0, "Tipo desconhecido = sem fraquezas")


func test_morale_name():
	var ks = KaelenSystem.new()
	assert_eq(ks.get_morale_name(KaelenSystem.MoraleLevel.ALTA), "Alta")
	assert_eq(ks.get_morale_name(KaelenSystem.MoraleLevel.QUEBRADA), "Quebrada")


func test_fatigue_name():
	var ks = KaelenSystem.new()
	assert_eq(ks.get_fatigue_name(KaelenSystem.FatigueLevel.DESCANSADO), "Descansado")
	assert_eq(ks.get_fatigue_name(KaelenSystem.FatigueLevel.CRITICA), "Crítica")


func test_signal_target_analyzed():
	var ks = KaelenSystem.new()
	watch_signals(ks)
	ks.analyze_target({"name": "Goblin", "type": "Goblin"})
	assert_signal_emitted(ks, "target_analyzed", "Sinal deve disparar ao analisar")


func test_signal_suggestion_when_locks():
	var ks = KaelenSystem.new()
	watch_signals(ks)
	ks.analyze_target({"locks": [{"type": "Éter", "remaining": 1}]})
	assert_signal_emitted(ks, "suggestion_generated", "Sinal deve disparar com locks")


# --- ROADMAP #5: HUD de Kaelen vivo (era 🟡 morto) ---

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node

# Grid fake geométrico — subclass de BattleGrid (o tipo do campo `grid` da
# battle_scene) só com o grid_to_pixel estático e clear_highlights sem camadas;
# sem montar camadas de tile.
class FakeGrid:
	extends BattleGrid
	func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
		return Vector2(grid_pos.x * 32, grid_pos.y * 32)
	func clear_highlights() -> void:
		movement_tiles.clear()
		attack_tiles.clear()
	func show_movement_range(_unit, _range) -> void:
		pass
	func show_attack_range(_unit, _range) -> void:
		pass

func _make_combat_feedback_stub() -> CombatFeedback:
	# Mesmo padrão do test_battle_actions: stub que extends CombatFeedback e
	# só zera o flash_unit (exigiria estar na tree para tweens).
	var script = GDScript.new()
	script.source_code = """
extends CombatFeedback
func flash_unit(_unit: Node2D, _color: Color = Color.WHITE, _intensity: float = 1.0) -> void:
	pass
"""
	script.reload()
	var stub = CombatFeedback.new()
	stub.set_script(script)
	return stub

func _open_battle_scene() -> void:
	# Instância fora da árvore: _ready não roda (sem setup_ui), então injetamos
	# os mínimos tree deps + KaelenSystem real. bs é member (como test_battle_actions).
	bs = BattleSceneScript.new()
	bs.grid = FakeGrid.new()
	bs.unit_container = Node2D.new()
	bs.ui_layer = CanvasLayer.new()
	bs.kaelen_system = KaelenSystem.new()
	bs.combat_feedback = _make_combat_feedback_stub()
	# show/hide_unit_info + action_menu acessam esses nós na árvore real; um
	# script-only não os tem, então injetamos minimamente p/ .visible funcionar.
	bs.unit_info_panel = PanelContainer.new()
	bs.unit_name_label = Label.new()
	bs.unit_hp_label = Label.new()
	bs.unit_class_label = Label.new()
	bs.action_menu = PanelContainer.new()
	bs.move_button = Button.new()
	bs.attack_button = Button.new()
	# _ready é quem conecta os sinais na árvore real; aqui chamamos direto para o
	# fluxo de análise chegar aos handlers de HUD (mesmo caminho do runtime).
	bs.connect_signals()

# Inimigo stub para select_unit: UnitData (Resource) + Unit (Node2D).
# soul_type carrega o tipo de criatura (chave da WEAKNESS_TABLE do Kaelen).
func _make_enemy(name: String, soul_type: String, unit_class: String, hp: int, defense: int) -> Unit:
	var data = UnitData.new()
	data.is_player = false
	data.unit_name = name
	data.soul_type = soul_type
	data.unit_class = unit_class
	data.current_hp = hp
	data.max_hp = hp
	data.defense = defense
	data.attack_range = 1
	var unit = Unit.new()
	unit.name = name
	unit.data = data
	return unit

func test_kaelen_hud_panel_present_and_hidden():
	_open_battle_scene()
	bs._create_kaelen_hud()
	assert_not_null(bs.kaelen_hud_panel, "painel existe após _create_kaelen_hud")
	assert_true(not bs.kaelen_hud_panel.visible, "painel começa oculto (§3.4 estava morto)")
	bs.free()

func test_select_enemy_shows_kaelen_hud():
	_open_battle_scene()
	bs._create_kaelen_hud()
	assert_true(not bs.kaelen_hud_panel.visible)
	var enemy = _make_enemy("Orc Chefe", "Orc", "Guerreiro", 60, 12)
	bs.select_unit(enemy)
	assert_true(bs.kaelen_hud_panel.visible, "analisar inimigo revela a interface de Kaelen")
	# WEAKNESS_TABLE["Orc"] = {Perfuração +30%, Éter +20%} — a HUD mostra a fraqueza certa.
	assert_true(bs.kaelen_bio_weaknesses.text.contains("Perfuração"), "fraqueza de Orc (Perfuração +30%) aparece no HUD" + " label=[" + bs.kaelen_bio_weaknesses.text + "]")
	bs.free()

func test_deselect_hides_kaelen_hud():
	_open_battle_scene()
	bs._create_kaelen_hud()
	var enemy = _make_enemy("Inquisidor", "Inquisidor", "Clérigo", 45, 10)
	bs.select_unit(enemy)
	assert_true(bs.kaelen_hud_panel.visible, "seleção mostra o HUD")
	bs.deselect_unit()
	assert_true(not bs.kaelen_hud_panel.visible, "deseleção oculta o HUD")
	bs.free()
