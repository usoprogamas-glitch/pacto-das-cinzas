extends Node2D

## Arena de batalha no molde Sea of Stars (decisão 2026-08-31, opção 3):
## sem grid tático. Overlay IN-PLACE sobre a exploração (GDD §6.2), turnos por
## agilidade (TurnOrderManager), menu Atacar/Magia/Fugir + Timed Hit/Block.
## Lógica no ArenaCombat (puro, headless-testável); esta cena só apresenta.

const ArenaCombatLib := preload("res://scripts/arena_combat.gd")
const MotionLib := preload("res://scripts/sprite_motion_library.gd")

signal battle_ended(victory: bool, rewards: Dictionary)
signal battle_fled()

var combat  # ArenaCombat (núcleo puro)
var combatants: Array = []  # Unit (contrato: get_speed/is_player_side/is_alive)
var enemies_meta: Array = []  # [{type, soul_ether}] para recompensas
var turn_queue: Array = []
var turn_index: int = 0
var current_actor = null

# Timed hit / block (mesma mecânica do timed_combat_system, GDD §3.1)
var _timed_hit_active := false
var _timed_hit_start := 0.0
var _pending_target = null
var _pending_is_magic := false
var _block_window_open := false
var _block_start := 0.0
var _block_reduction := 0.0

# UI
var action_menu: VBoxContainer
var turn_label: Label
var log_label: Label
var result_panel: Control  # result screen dedicada (AUDIT 7d)
var result_title: Label
var result_rewards: Label
var result_continue: Button
var _result_shown := false
var _pending_victory := false
var _pending_rewards := {}
var _hp_labels: Dictionary = {}  # unit -> Label
var _animators: Dictionary = {}  # instance_id -> UnitAnimator (P0-2: key por instância)
var _home_positions: Dictionary = {}  # instance_id -> Vector2 (destino da entrada)
var _entrance_tweens: Array = []
var combat_frozen := false  # testes: congela o loop de turnos (IA não age)
var _wave_specs: Array = []  # ondas data-driven (MapDatabase.waves)
var _wave_index := 0


func _ready() -> void:
	combat = ArenaCombatLib.new()
	_build_arena()
	_setup_from_campaign()
	_entrance_walk()
	if not combat_frozen:
		_start_round()


# --- Setup ---

func _setup_from_campaign() -> void:
	var map_id: int = GameManager.game_data.get("current_map", 0) if GameManager else 0
	var map: Dictionary = MapDatabase.get_map(map_id)
	var stage: Dictionary = GameManager.campaign_system.get_current_stage() if GameManager and GameManager.campaign_system else {}

	# Ondas escaladas (GDD §1 Ato III, decisão ROADMAP #7): mapa declara
	# data-driven. Onda 1 = spawn inicial (abaixo); 2..N reinjetam no _check_end.
	var wave_specs: Array = map.get("waves", [])
	if wave_specs.size() > 0:
		_wave_specs = wave_specs
		_wave_index = 1

	var kael := _make_combatant("Kael", true, 80, 12, 8, 11, 50)
	combatants = [kael]
	_arena_position(kael, Vector2(430, 430), Color(0.2, 0.8, 0.3), "kael")

	if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
		var kroug := _make_combatant("Kroug", true, 120, 10, 15, 8, 20)
		combatants.append(kroug)
		_arena_position(kroug, Vector2(330, 500), Color(0.8, 0.3, 0.1), "kroug")

	# Inimigos: boss_enemy do estágio sobrepõe o pool do mapa (ROADMAP #8).
	# Com ondas declaradas, o spawn inicial segue a composição da onda 1.
	var scale_spawn := 1.0
	var pool: Array
	var count: int
	if _wave_specs.size() > 0:
		var w1: Dictionary = _wave_specs[0]
		pool = w1.get("enemies", ["mercenario"])
		count = pool.size()
		scale_spawn = float(w1.get("stat_scale", 1.0))
	else:
		pool = map.get("enemies", ["mercenario"])
		count = 1 if stage.get("boss", false) else int(map.get("enemy_count", 2))
		if stage.get("boss_enemy", "") != "":
			pool = [stage["boss_enemy"]]
	var pos_x := 860.0
	for i in range(count):
		var type: String = String(pool[i % pool.size()])
		var e: Dictionary = EnemyDatabase.get_enemy(type)
		if e.is_empty():
			continue
		var foe := _make_combatant(e["name"], false,
			int(round(float(e["hp"]) * scale_spawn)), int(round(float(e["atk"]) * scale_spawn)),
			int(round(float(e["def"]) * scale_spawn)), int(round(float(e["spd"]) * scale_spawn)),
			int(e.get("mp", 30)))
		combatants.append(foe)
		_arena_position(foe, Vector2(pos_x, 400 + i * 130), Color(e["color"]), _sprite_key(e["name"]))
		pos_x += 40
		enemies_meta.append({"type": type, "soul_ether": e.get("soul_ether", 10)})


func _make_combatant(unit_name: String, is_player: bool, hp: int, atk: int, def: int, spd: int, mp: int) -> Unit:
	var u := Unit.new()
	var d := UnitData.new()
	d.unit_name = unit_name
	d.is_player = is_player
	d.max_hp = hp
	d.current_hp = hp
	d.attack = atk
	d.defense = def
	d.speed = spd
	d.max_mp = mp
	d.current_mp = mp
	u.data = d
	u.current_hp = hp
	u.current_mp = mp
	# Dummies para os @onready do Unit ($Sprite2D/$HPBar/$SelectionIndicator),
	# que exigem os nós antes de entrar na árvore. A arte real é adicionada em
	# _arena_position; o HP real é a barra flutuante dali.
	var dummy_sprite := Sprite2D.new()
	dummy_sprite.name = "Sprite2D"
	dummy_sprite.visible = false
	u.add_child(dummy_sprite)
	var dummy_hp := ProgressBar.new()
	dummy_hp.name = "HPBar"
	dummy_hp.visible = false
	u.add_child(dummy_hp)
	var dummy_sel := ColorRect.new()
	dummy_sel.name = "SelectionIndicator"
	dummy_sel.visible = false
	u.add_child(dummy_sel)
	add_child(u)
	return u


func _arena_position(u: Unit, pos: Vector2, color: Color, sprite_key: String) -> void:
	u.position = pos
	u.visible = true
	_home_positions[u.get_instance_id()] = pos
	var path := "res://assets/sprites/%s.png" % sprite_key
	var sprite: Sprite2D
	var motion_sets := {}
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			motion_sets = MotionLib.build_motion_sets(img)
			sprite = Sprite2D.new()
			# Frame 0 do idle (256px); UnitAnimator cicla a partir daqui.
			sprite.texture = motion_sets["idle"][0]
			sprite.scale = Vector2(0.09, 0.09) * (float(img.get_width()) / float(MotionLib.FRAME_SIZE))
		else:
			sprite = _fallback_sprite(color)
	else:
		sprite = _fallback_sprite(color)
	u.add_child(sprite)

	# Barra de HP flutuante (molde SoS: HP visível sobre o combatente).
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = u.data.max_hp
	bar.value = u.current_hp
	bar.position = Vector2(-30, -62)
	bar.size = Vector2(60, 8)
	bar.show_percentage = false
	u.add_child(bar)
	u.hp_changed.connect(func(hp): bar.value = hp)

	# Animador (idle respirando; lunge/hit/death/victory nos eventos).
	var animator := UnitAnimator.new()
	u.add_child(animator)
	animator.setup(u)
	animator.set_frames(motion_sets)
	animator.play_idle()
	_animators[u.get_instance_id()] = animator


func _animator_for(u) -> UnitAnimator:
	if u == null or not _animators.has(u.get_instance_id()):
		return null
	return _animators[u.get_instance_id()]


## Entrada no molde SoS: cada grupo caminha até sua posição de arena
## (jogadores pela esquerda, inimigos pela direita).
func _entrance_walk() -> void:
	for u in combatants:
		var animator := _animator_for(u)
		var target: Vector2 = _home_positions[u.get_instance_id()]
		var from_x: float = -80.0 if u.is_player_side() else 1360.0
		u.position = Vector2(from_x, target.y)
		if animator:
			animator.current_animation = "walk"
			animator.face_direction(target.x - from_x)
			animator.set_moving(true)  # passada real (frames) durante a entrada
		var tween := create_tween()
		_entrance_tweens.append(tween)
		tween.tween_property(u, "position", target, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if animator and animator.sprite:
			tween.parallel().tween_property(animator.sprite, "rotation", 0.08, 0.45)
			tween.tween_property(animator.sprite, "rotation", 0.0, 0.45)
		tween.finished.connect(_on_entrance_finished.bind(animator))


func _on_entrance_finished(animator) -> void:
	if animator:
		animator.current_animation = "idle"
		animator.set_moving(false)


## Mata os tweens de entrada e encaixa todos nos destinos (evita conflito de
## tween quando o primeiro golpe sai durante a caminhada).
func _finish_entrance() -> void:
	for t in _entrance_tweens:
		if t.is_valid():
			t.kill()
	_entrance_tweens.clear()
	for u in combatants:
		if _home_positions.has(u.get_instance_id()):
			u.position = _home_positions[u.get_instance_id()]
			var animator := _animator_for(u)
			if animator and animator.current_animation == "walk":
				animator.current_animation = "idle"
				animator.set_moving(false)


func _sprite_key(unit_name: String) -> String:
	var key := unit_name.to_lower()
	for pair in [["—", ""], ["'", ""], ["á", "a"], ["é", "e"], ["ê", "e"], ["â", "a"], ["ã", "a"], ["õ", "o"], ["ô", "o"], ["í", "i"], ["ú", "u"], ["ç", "c"], [" ", "_"]]:
		key = key.replace(pair[0], pair[1])
	while "__" in key:
		key = key.replace("__", "_")
	return key


func _fallback_sprite(color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6, 22):
		for x in range(6, 18):
			img.set_pixel(x, y, color)
	s.texture = ImageTexture.create_from_image(img)
	return s


# --- Fluxo de turnos (velocity-based, igual TurnOrderManager) ---

func _start_round() -> void:
	turn_queue = combat.build_turn_order(combatants)
	turn_index = 0
	_next_turn()


func _next_turn() -> void:
	if _check_end():
		return
	while turn_index < turn_queue.size() and not turn_queue[turn_index].is_alive():
		turn_index += 1
	if turn_index >= turn_queue.size():
		_start_round()
		return
	current_actor = turn_queue[turn_index]
	_update_turn_label()
	if current_actor.is_player_side():
		_show_action_menu(true)
	else:
		_enemy_act()


func _advance() -> void:
	turn_index += 1
	_next_turn()


func _check_end() -> bool:
	var result: String = combat.is_battle_over(combatants)
	if result == "":
		return false
	# Ondas escaladas (Ato III): vitória com onda pendente reinjeta a próxima —
	# false mantém o loop de turnos vivo (round seguinte traz os reforços).
	if result == "victory" and _wave_index < _wave_specs.size():
		_spawn_next_wave()
		return false
	_finish(result == "victory")
	return true


func _finish(victory: bool) -> void:
	if _result_shown:
		return
	_result_shown = true
	_show_action_menu(false)
	var rewards := {"soul_ether": 0, "gold": 0, "experience": 0}
	if victory:
		for m in enemies_meta:
			rewards["soul_ether"] += m["soul_ether"]
		# Vitória: sobreviventes celebram. (Derrota não anima: is_battle_over
		# só encerra com a party inteira morta — o luto é da result screen.)
		for u in combatants:
			if u.is_player_side() and u.is_alive() and _animator_for(u):
				_animator_for(u).play_victory()
	_log("VITÓRIA!" if victory else "DERROTA...")
	_show_result_screen(victory, rewards)


# --- Result screen dedicada (molde SoS) ---
# O sinal battle_ended só dispara quando o jogador clica "Continuar" — a
# campanha avança DEPOIS que o resultado é visto.

func _show_result_screen(victory: bool, rewards: Dictionary) -> void:
	_pending_victory = victory
	_pending_rewards = rewards
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(420, 230)
	result_panel.custom_minimum_size = Vector2(440, 260)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	result_panel.add_child(vbox)

	result_title = Label.new()
	result_title.text = "VITÓRIA!" if victory else "DERROTA..."
	result_title.add_theme_font_size_override("font_size", 42)
	result_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if victory else Color(0.9, 0.3, 0.3))
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result_title)

	result_rewards = Label.new()
	result_rewards.text = "\n".join(PackedStringArray(_result_lines(victory, rewards)))
	result_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result_rewards)

	result_continue = Button.new()
	result_continue.text = "Continuar"
	result_continue.pressed.connect(_on_result_continue_pressed)
	vbox.add_child(result_continue)

	add_child(result_panel)
	result_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(result_panel, "modulate:a", 1.0, 0.25)


func _result_lines(victory: bool, rewards: Dictionary) -> Array:
	if not victory:
		return ["A cinza reclama outro corpo...", "Retorne pelo menu para tentar de novo."]
	var lines := []
	if int(rewards.get("soul_ether", 0)) > 0:
		lines.append("+%d Soul Éter" % int(rewards["soul_ether"]))
	if int(rewards.get("gold", 0)) > 0:
		lines.append("+%d ouro" % int(rewards["gold"]))
	if int(rewards.get("experience", 0)) > 0:
		lines.append("+%d XP" % int(rewards["experience"]))
	lines.append("O caminho segue adiante...")
	return lines


func _on_result_continue_pressed() -> void:
	if not _result_shown:
		return
	_result_shown = false
	if result_panel:
		result_panel.queue_free()
		result_panel = null
	battle_ended.emit(_pending_victory, _pending_rewards)


func result_visible() -> bool:
	return result_panel != null and is_instance_valid(result_panel) and result_panel.visible


## Reinjeta a próxima onda (2..N): inimigos com stats escalados por stat_scale,
## entrando pela mesma porta do spawn normal (factory + posição de arena).
## Contrato: _wave_index = próxima onda a reinjetar (1-based; 1 = spawn inicial).
func _spawn_next_wave() -> void:
	var wave: Dictionary = _wave_specs[_wave_index]
	_wave_index += 1
	var scale: float = float(wave.get("stat_scale", 1.0 + 0.25 * _wave_index))
	var pos_x := 900.0
	for type in wave.get("enemies", []):
		var e: Dictionary = EnemyDatabase.get_enemy(String(type))
		if e.is_empty():
			continue
		var foe := _make_combatant("%s (Onda %d)" % [e["name"], _wave_index], false,
			int(round(float(e["hp"]) * scale)), int(round(float(e["atk"]) * scale)),
			int(round(float(e["def"]) * scale)), int(round(float(e["spd"]) * scale)),
			int(e.get("mp", 30)))
		combatants.append(foe)
		_arena_position(foe, Vector2(pos_x, 380 + (_wave_index % 2) * 90), Color(e["color"]), _sprite_key(e["name"]))
		pos_x += 40
		enemies_meta.append({"type": String(type), "soul_ether": int(e.get("soul_ether", 10))})
	_log("ONDA %d/%d entra na arena!" % [_wave_index, _wave_specs.size()])


# --- Ações do jogador ---

func _show_action_menu(show: bool) -> void:
	action_menu.visible = show
	if show:
		_log("Vez de %s" % current_actor.data.unit_name)


func _on_attack_pressed() -> void:
	if not _can_player_act():
		return
	_show_action_menu(false)
	_pending_is_magic = false
	_begin_timed_hit()


func _on_magic_pressed() -> void:
	if not _can_player_act():
		return
	if current_actor.current_mp < ArenaCombatLib.MAGIC_COST:
		_log("MP insuficiente!")
		return
	_show_action_menu(false)
	_pending_is_magic = true
	_begin_timed_hit()


func _on_flee_pressed() -> void:
	if not _can_player_act():
		return
	_show_action_menu(false)
	if randf() < 0.5:
		_log("Fuga bem-sucedida!")
		battle_fled.emit()
	else:
		_log("A fuga falhou!")
		_advance()


func _can_player_act() -> bool:
	return current_actor != null and current_actor.is_player_side() and action_menu.visible


func _begin_timed_hit() -> void:
	# Alvo: inimigo vivo de menor HP (foca kill, espelho da IA).
	var foes := combatants.filter(func(u): return u.is_alive() and not u.is_player_side())
	if foes.is_empty():
		_advance()
		return
	foes.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	_pending_target = foes[0]
	_timed_hit_active = true
	_timed_hit_start = Time.get_ticks_msec() / 1000.0
	_log("TIMED HIT! Clique no impacto!")
	await get_tree().create_timer(ArenaCombatLib.TIMED_HIT_WINDOW).timeout
	if _timed_hit_active:
		_resolve_action(1.0, "MISS")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _timed_hit_active:
			var elapsed := (Time.get_ticks_msec() / 1000.0) - _timed_hit_start
			var grade = combat.timed_combat.resolve_timing(elapsed)
			_timed_hit_active = false
			_resolve_action(grade.multiplier, grade.grade)
		elif _block_window_open:
			var elapsed := (Time.get_ticks_msec() / 1000.0) - _block_start
			var result = combat.timed_combat.resolve_block_timing(elapsed)
			_block_reduction = combat.timed_combat.get_block_reduction(result)
			_block_window_open = false
			_log("BLOCK %s!" % result.grade)


func _resolve_action(multiplier: float, grade: String) -> void:
	if _pending_target == null or not _pending_target.is_alive():
		_advance()
		return
	var attacker_anim := _animator_for(current_actor)
	if attacker_anim:
		if _pending_is_magic:
			await attacker_anim.play_magic_cast()
		else:
			await attacker_anim.play_attack(_pending_target)
	var damage: int
	if _pending_is_magic:
		var cast: Dictionary = combat.cast_damage_spell(current_actor, _pending_target)
		if not cast.success:
			_log("MP insuficiente!")
			_advance()
			return
		damage = int(cast.damage * multiplier)
	else:
		damage = combat.calculate_damage(current_actor, _pending_target, multiplier)
	combat.apply_hit(current_actor, _pending_target, damage)
	_pending_target.hp_changed.emit(_pending_target.current_hp)
	_log("%s → %s: %d de dano (%s)" % [current_actor.data.unit_name, _pending_target.data.unit_name, damage, grade])
	await _play_aftermath(_pending_target)
	_pending_target = null
	_advance()


func _play_aftermath(target) -> void:
	var target_anim := _animator_for(target)
	if target_anim == null:
		return
	if target.is_alive():
		await target_anim.play_hit()
	else:
		await target_anim.play_death()


# --- IA inimiga ---

func _enemy_act() -> void:
	if _check_end():
		return
	var players := combatants.filter(func(u): return u.is_alive() and u.is_player_side())
	var target = combat.choose_enemy_target(players)
	if target == null:
		return
	# Janela de defesa reativa (timed block) durante o golpe inimigo.
	var actor_anim := _animator_for(current_actor)
	if actor_anim:
		await actor_anim.play_attack(target)
	_block_window_open = true
	_block_start = Time.get_ticks_msec() / 1000.0
	_block_reduction = 0.0
	_log("%s ataca! Clique para bloquear!" % current_actor.data.unit_name)
	await get_tree().create_timer(ArenaCombatLib.TIMED_BLOCK_WINDOW).timeout
	_block_window_open = false
	var damage: int = combat.calculate_damage(current_actor, target)
	damage = int(damage * (1.0 - _block_reduction))
	combat.apply_hit(current_actor, target, damage)
	target.hp_changed.emit(target.current_hp)
	_log("%s sofreu %d de dano" % [target.data.unit_name, damage])
	await _play_aftermath(target)
	if not _check_end():
		_advance()


# --- UI (overlay in-place, sem .tscn) ---

func _build_arena() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.55)
	dim.size = Vector2(1280, 720)
	add_child(dim)

	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.13, 0.11, 0.16, 0.9)
	floor_rect.position = Vector2(140, 280)
	floor_rect.size = Vector2(1000, 380)
	add_child(floor_rect)

	turn_label = Label.new()
	turn_label.position = Vector2(20, 12)
	turn_label.add_theme_font_size_override("font_size", 22)
	add_child(turn_label)

	log_label = Label.new()
	log_label.position = Vector2(20, 668)
	log_label.add_theme_font_size_override("font_size", 18)
	add_child(log_label)

	action_menu = VBoxContainer.new()
	action_menu.position = Vector2(40, 320)
	action_menu.add_theme_constant_override("separation", 12)
	add_child(action_menu)

	var atk_btn := Button.new()
	atk_btn.text = "Atacar"
	atk_btn.pressed.connect(_on_attack_pressed)
	action_menu.add_child(atk_btn)

	var magic_btn := Button.new()
	magic_btn.text = "Magia (%d MP)" % ArenaCombatLib.MAGIC_COST
	magic_btn.pressed.connect(_on_magic_pressed)
	action_menu.add_child(magic_btn)

	var flee_btn := Button.new()
	flee_btn.text = "Fugir"
	flee_btn.pressed.connect(_on_flee_pressed)
	action_menu.add_child(flee_btn)

	action_menu.visible = false


func _update_turn_label() -> void:
	turn_label.text = "Agindo: %s (HP %d/%d)" % [
		current_actor.data.unit_name, current_actor.current_hp, current_actor.data.max_hp]


func _log(msg: String) -> void:
	log_label.text = msg
