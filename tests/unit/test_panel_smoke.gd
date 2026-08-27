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
	bs.combo_system = preload("res://scripts/battle/combo_system.gd").new()
	bs.balance_system = preload("res://scripts/battle/balance_system.gd").new()
	bs.boss_system = preload("res://scripts/battle/boss_system.gd").new()
	bs.traversal_system.traversal_completed.connect(bs._on_traversal_completed)
	bs.campfire_system.rest_completed.connect(bs._on_camp_rest_completed)
	bs.cooking_system.recipe_crafted.connect(bs._on_recipe_crafted)
	bs.tavern_minigame.game_over.connect(bs._on_tavern_game_over)
	bs.boss_system.boss_hp_changed.connect(bs.show_boss_hp)
	# HUD de progressão real (labels ActLabel/MemLabel/SoulLabel/XPLabel/FormLabel)
	bs.ui_layer = CanvasLayer.new()
	bs._create_progression_hud()
	bs._update_progression_hud()
	# Membros que _on_turn_started toca (não montados pela UI da cena .tscn)
	bs.turn_label = Label.new()
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
	# Sem injeção demo: o cook cozinha o que foi coletado. Guisado = 2 carne + 1 erva.
	# Coleta direto (o gather em si é testado à parte) para isolar a cadeia cozinhar→HUD.
	bs.cooking_system.collect_ingredient("carne_troll", 2)
	bs.cooking_system.collect_ingredient("ervas_silvestres", 1)
	bs._on_cook_pressed()
	assert_eq(int(_xp().text.trim_prefix("XP ")), 20, "XP subiu 20 (recipe_crafted)")
	assert_eq(_mem().text, "MEM 10%", "MEM subiu 10%")
	bs._on_cook_pressed()  # 2ª: sem receita extra, mas _cook_used já true
	assert_eq(int(_xp().text.trim_prefix("XP ")), 20, "segundo uso não soma XP")


# --- Taberna game_over: +1 ALMA, toast ---

func test_tavern_game_over_adds_soul_to_hud() -> void:
	bs._on_tavern_game_over("Jogador", "IA")
	assert_eq(_soul().text, "ALMAS 1", "game_over dobra as almas nomeadas no HUD")


# --- Buffs de cozinha §7.2 decaem por turno e expiram com toast ---

func test_cook_buff_ticks_and_expires_on_turn() -> void:
	# _on_cook_pressed crafts guisado_goblin (duration 3)
	bs.cooking_system.collect_ingredient("carne_troll", 2)
	bs.cooking_system.collect_ingredient("ervas_silvestres", 1)
	bs._on_cook_pressed()
	assert_eq(bs.cooking_system.get_active_bonuses().size(), 1, "buff ativo pós-craft")
	for i in range(3):
		bs._on_turn_started(null)  # 3 ticks → remaining 0 → expire
	assert_eq(bs.cooking_system.get_active_bonuses().size(), 0, "buff expirou após 3 turns")
	assert_true(_toasts.any(func(t: String) -> bool: return t.begins_with("BUFF EXPIRADO")),
		"toast de expiração emitido")


# --- Buff de ataque §7.2 multiplica o dano do atacante ---

func test_cooking_attack_multiplier() -> void:
	assert_eq(bs._cooking_attack_multiplier(), 1.0, "sem buffs: neutro 1.0")
	# injeta buff de ataque direto (guisado_goblin não tem attack; usa banquete)
	bs.cooking_system.collect_ingredient("carne_troll", 3)
	bs.cooking_system.collect_ingredient("fruta_eterna", 1)
	bs.cooking_system.collect_ingredient("mel_abissal", 2)
	bs.cooking_system.craft("banquete_rei")  # attack: 10
	assert_eq(bs._cooking_attack_multiplier(), 2.0, "+10 attack = x2.0")


# --- Buff de defesa §7.2 reduz dano recebido ---

func test_cooking_defense_bonus() -> void:
	assert_eq(bs._cooking_defense_bonus(), 0, "sem buffs: 0")
	# guisado_goblin: defense 5
	bs.cooking_system.collect_ingredient("carne_troll", 2)
	bs.cooking_system.collect_ingredient("ervas_silvestres", 1)
	bs._on_cook_pressed()
	assert_eq(bs._cooking_defense_bonus(), 5, "guisado_goblin dá +5 defesa")


func test_take_damage_applies_defense_bonus() -> void:
	var data: UnitData = UnitData.new()
	data.max_hp = 50
	data.defense = 0
	var unit: Unit = Unit.new()
	unit.data = data
	unit.current_hp = 50
	unit.take_damage(10, 5)  # 10 - 0(def) - 5(bonus) = 5
	assert_eq(unit.current_hp, 45, "dano reduzido pelo bonus de defesa")
	unit.take_damage(2, 50)  # bonus supera dano → mínimo 1
	assert_eq(unit.current_hp, 44, "dano nunca abaixo de 1")


# --- Buff de hp/mp §7.2 cura imediatamente as units jogador ---

func test_cooked_heal_restores_party_hp() -> void:
	var data: UnitData = UnitData.new()
	data.is_player = true
	data.max_hp = 100
	var party: Unit = Unit.new()
	party.data = data
	party.current_hp = 30
	BattleManager.player_units.append(party)
	bs._apply_cooked_heal({"hp": 20, "mp": 10})
	assert_eq(party.current_hp, 50, "cura +20 HP")

func test_cooked_heal_noop_without_bonuses() -> void:
	# sem hp/mp no buff → nada acontece, sem erro
	var before: Array = BattleManager.player_units.duplicate()
	bs._apply_cooked_heal({"attack": 10})
	assert_eq(BattleManager.player_units.size(), before.size(), "não altera party")


# --- Toast emitido em cada ação (feedback visual) ---

func test_toast_emitted_per_action() -> void:
	bs._on_traverse_pressed()
	bs._on_camp_pressed()
	bs._on_cook_pressed()
	bs._on_tavern_game_over("IA", "Jogador")
	assert_gt(_toasts.size(), 0, "pelo menos um toast por ação")
	# travessia(1, sem drop determinístico → até +1 ENCONTROU) + camp(1) + cook(RECEITA+RECUPEROU) + taverna(1)
	assert_gte(_toasts.size(), 4, "mínimo 4 toasts: travessia, camp, cook(RECEITA+RECUPEROU), taverna")
	assert_true(_toasts[0].begins_with("TRAVESSIA"), "toast de travessia")


# --- §7.2 Gathering: travessia coleta 1 ingrediente (ponderado por raridade) ---

func test_traversal_collects_ingredient() -> void:
	# get_inventory() é a MESMA referência interna → captura a soma ANTES de coletar
	var total_before: int = _inventory_total()
	bs._on_traverse_pressed()
	assert_eq(_inventory_total(), total_before + 1, "travessia coleta exatamente 1 ingrediente")


# --- Combo §3.3: CP reage na UI (dots) e ativa combo spell ---

func test_combo_ui_reacts_to_cp_changed() -> void:
	# UI reativa: ganhar CP via earn_from_timed_hit reflete nos dots
	bs._create_combo_ui()
	bs.combo_system.cp_changed.connect(func(_cp: int, _max: int) -> void: bs.update_combo_ui())
	bs.update_combo_ui()
	var d0: ColorRect = bs.combo_dots[0]
	assert_eq(d0.color, Color(0.3, 0.3, 0.3), "dot 0 apagado com 0 CP")
	bs.combo_system.add_cp(1)
	assert_eq(d0.color, Color(1.0, 0.8, 0.2), "dot 0 aceso após +1 CP")


func test_combo_pressed_activates_with_participants() -> void:
	# (1) gera CP + popula player_units com participantes da Erupção de Éter
	bs.combo_system.add_cp(2)
	var saved_units: Array[Unit] = BattleManager.player_units.duplicate()
	BattleManager.player_units.clear()
	for name in ["Querubim", "Kroug"]:
		var data: UnitData = UnitData.new()
		data.unit_name = name
		data.is_player = true
		data.max_hp = 100
		var u: Unit = Unit.new()
		u.data = data
		BattleManager.player_units.append(u)
	bs._on_combo_pressed()
	assert_eq(bs.combo_system.get_cp(), 1, "Erupção custa 1, tinha 2 CP → sobra 1")
	BattleManager.player_units.clear()
	for u in saved_units:
		BattleManager.player_units.append(u)


# --- Éter/Fúria §3.3: barra bipolar reage a ether/fury/modo ---

func test_balance_bar_bipolar_position() -> void:
	bs._create_balance_ui()
	bs.balance_system.perform_ether_action("heal")  # +10 ether
	bs.balance_system.perform_fury_action("execute")  # +15 fury
	bs.update_balance_ui()
	# Com ether != fury, value foge do centro 50
	assert_ne(bs.balance_bar.value, 50, "desequilibrado foge do centro")
	assert_eq(bs.balance_bar.value, 50 + (bs.balance_system.get_ether() - bs.balance_system.get_fury()) / 2,
		"total bipolar = 50 + (ether - fury)/2")


func test_balance_label_uses_string_modes() -> void:
	bs._create_balance_ui()
	bs.update_balance_ui()
	assert_eq(bs.balance_label.text, "Neutro", "default Neutro")
	bs.balance_system.set_mode(BalanceSystem.Mode.ETHER)
	bs.update_balance_ui()
	assert_eq(bs.balance_label.text, "Modo Éter", "label do modo Éter")
	bs.balance_system.set_mode(BalanceSystem.Mode.FURY)
	bs.update_balance_ui()
	assert_eq(bs.balance_label.text, "Modo Fúria", "label do modo Fúria")


# --- Boss HP §5: panel reage a init/damage via boss_hp_changed ---

func test_boss_panel_shows_on_spawn_and_hp() -> void:
	bs._create_boss_ui()
	bs.boss_system.init_cardinal("Ignis")
	bs.boss_system.damage_boss(100)
	assert_true(bs.boss_panel.visible, "panel visível após spawn")
	assert_eq(bs.boss_hp_bar.value, bs.boss_system.get_boss_hp(),
		"barra reflete HP atual do boss")


func test_boss_panel_updates_on_damage() -> void:
	bs._create_boss_ui()
	bs.boss_system.init_cardinal("Ignis")
	var before: int = bs.boss_system.get_boss_hp()
	bs.boss_system.damage_boss(50)
	assert_eq(bs.boss_system.get_boss_hp(), before - 50, "HP do boss caiu")
	assert_eq(bs.boss_hp_bar.value, before - 50, "barra acompanha damage")


func _inventory_total() -> int:
	var total: int = 0
	for amount in bs.cooking_system.get_inventory().values():
		total += amount
	return total


func test_traversal_emits_encontrou_toast() -> void:
	bs._on_traverse_pressed()
	assert_true(_toasts.any(func(t: String) -> bool: return t.begins_with("ENCONTROU")),
		"toast de item encontrado na travessia")
