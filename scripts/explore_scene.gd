extends Node2D

## Cena de exploração contínua no molde Sea of Stars (opção 3): o grupo anda
## pelo mapa em tempo real; inimigos visíveis patrulham/perseguem (SeamlessEncounterSystem)
## e o contato abre a arena de batalha IN-PLACE, sem troca de cena (GDD §6.2).
## Puzzles de luz data-driven do MapDatabase (GDD §6.3) spawham no mapa: espelhos
## de obsidiana e relógio cósmico giram com E; resolvidos, projetam o feixe e
## pagam as recompensas declaradas nos dados.
##
## Teclas: setas/WASD move, E interage com puzzle.

const SPEED := 220.0  ## px/s
const TILE := 64.0
const PUZZLE_RANGE := 52.0  ## px de distância para interagir
const TERRAIN_TILE_PX := 128  ## tile visual decorado (PixelArtRenderer)
const TERRAIN_GRID := Vector2i(10, 6)  ## 1280x720 coberto por tiles de 128px
const HINT_BASE := "Setas/WASD: mover  |  E: puzzle  |  Encoste no inimigo para lutar (Timed Hit/Block: clique!)"

const MotionLib := preload("res://scripts/sprite_motion_library.gd")

var encounter  # SeamlessEncounterSystem
var player: Node2D
var enemy_nodes: Array = []
var arena: Node = null
var map_id: int = 0
var puzzles: Array = []  # [{id, data, system, nodes, clock_node, solved}]
var terrain_tiles: Array = []  # [{node, kind}] - fundo decorado data-driven
var pixel_renderer  # PixelArtRenderer
var player_animator  # UnitAnimator (ciclos do MotionLib)
var _buddy_animator
var buddy_node: Node2D = null  # Kroug na cena (não filho do player: trilha suave)
var _player_trail: Array = []  # histórico de posições do player (trilha do buddy)
var _step_distance: float = 0.0  # distância desde o último SFX de passo
var _enemy_animators: Array = []  # paralelo a enemy_nodes
var _enemy_alert: Array = []  # paralelo a enemy_nodes: já percebeu o jogador?

var _enemy_tile_ids: Array = []  # ids registrados no SeamlessEncounterSystem
var _ui: CanvasLayer
var _hint_label: Label
var _e_was_down := false
# Travessia §6.1 (data-driven via MapDatabase.traversal_nodes)
var traversal  # TraversalSystem
var traversal_nodes: Array = []  # [{id, data, node, solved}]
var _traversal_hint: Label


func _ready() -> void:
	encounter = SeamlessEncounterSystem.new()
	map_id = GameManager.game_data.get("current_map", 0) if GameManager else 0
	_build_map()
	_spawn_props()
	_spawn_party()
	_spawn_enemies()
	_spawn_puzzles()
	_spawn_traversal_nodes()
	_build_ui()


# === PROPS VISUAIS (assets ComfyUI, data-driven via MapDatabase.props) ===

func _spawn_props() -> void:
	var map: Dictionary = MapDatabase.get_map(map_id)
	for cfg in map.get("props", []):
		var path: String = "res://assets/props/%s.png" % String(cfg.get("texture", ""))
		if not ResourceLoader.exists(path):
			continue  # asset ausente: pula sem quebrar a cena
		var sprite := Sprite2D.new()
		sprite.texture = load(path)
		sprite.position = _tile_center(cfg.get("pos", Vector2i.ZERO))
		sprite.scale = Vector2.ONE * float(cfg.get("scale", 1.0))
		# Ordem de adição (depois de bg/tiles, antes de units) garante props
		# acima do chão e abaixo das unidades — z_index -1 ficava ATRÁS do bg.
		add_child(sprite)
		sprite.add_child(_make_ground_shadow(Vector2(0, sprite.texture.get_height() * 0.42)))


func _build_map() -> void:
	var map: Dictionary = MapDatabase.get_map(map_id)
	var terrain_name: String = String(map.get("terrain", "mixed"))

	# Fundo (molde SoS v2): um único canvas low-res escalado com nearest —
	# paleta coesa por terreno, sem emendas de grade. O pixel_renderer fica
	# para os tiles animados de água usados na arena legada.
	pixel_renderer = PixelArtRenderer.new()
	add_child(pixel_renderer)
	var terrain_sprite: Sprite2D = pixel_renderer.build_terrain_canvas(terrain_name, hash("terrain_%d" % map_id))
	add_child(terrain_sprite)
	_spawn_tile_decorations(terrain_name)


## Árvores decorativas do tileset do Eder Muniz (world-map 16px) escaladas
## com nearest: dão profundidade sem brigar com o piso.
func _spawn_tile_decorations(terrain_name: String) -> void:
	var atlas: Texture2D = ResourceLoader.load("res://assets/tilesets/edermunizz_overworld.png")
	if atlas == null:
		return
	var at_img: Image = atlas.get_image()
	if at_img.get_width() < 64 or at_img.get_height() < 32:
		return
	# Tiles de árvore densa: col 0-2, rows 0-2 (bloco verde escuro do atlas).
	var tree_cells := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("trees_%s" % terrain_name)
	var count := 10 if terrain_name == "forest" else (4 if terrain_name == "mixed" else 2)
	for i in range(count):
		var cell: Vector2i = tree_cells[rng.randi() % tree_cells.size()]
		var tile := AtlasTexture.new()
		tile.atlas = atlas
		tile.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
		var deco := Sprite2D.new()
		deco.texture = tile
		deco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		deco.position = _tile_center(Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 4)))
		deco.scale = Vector2(3, 3)  # 16px -> 48px na tela
		add_child(deco)
		deco.add_child(_make_ground_shadow(Vector2(0, 20)))

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = hash(map_id)
	for i in range(24):
		# Decoração orgânica (pedras/cinzas/arbustos): polígono irregular escuro
		# em vez de quadrados chapados (pareciam artefatos no screenshot QA).
		var deco := Polygon2D.new()
		var s := rng2.randf_range(6, 14)
		var points := PackedVector2Array()
		var sides := rng2.randi_range(5, 8)
		for side in range(sides):
			var angle := TAU * side / sides
			var radius := s * rng2.randf_range(0.6, 1.0)
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		deco.polygon = points
		deco.position = Vector2(rng2.randf_range(20, 1240), rng2.randf_range(20, 660))
		deco.color = _terrain_color(terrain_name).darkened(0.55)
		deco.z_index = -1
		add_child(deco)


func _terrain_tile_kind(terrain: String, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	match terrain:
		"forest":
			return "forest" if roll < 0.7 else ("grass" if roll < 0.9 else "stone")
		"cave":
			return "cave" if roll < 0.6 else "stone"
		"castle":
			return "castle" if roll < 0.7 else "stone"
		"volcanic":
			return "lava" if roll < 0.5 else "stone"
		_:
			return "grass" if roll < 0.7 else ("stone" if roll < 0.9 else "water")


func _terrain_color(terrain: String) -> Color:
	match terrain:
		"forest": return Color(0.10, 0.22, 0.12)
		"cave": return Color(0.12, 0.10, 0.14)
		"castle": return Color(0.22, 0.20, 0.24)
		"volcanic": return Color(0.25, 0.10, 0.08)
		_: return Color(0.14, 0.16, 0.11)


func _spawn_party() -> void:
	player = Node2D.new()
	player.position = Vector2(160, 360)
	player.add_child(_make_ground_shadow())
	var kael_sprite := _animated_sprite("res://assets/sprites/kael.png", 0.06, Color(0.2, 0.8, 0.3))
	player.add_child(kael_sprite)
	player_animator = kael_sprite.get_meta("animator", null)
	add_child(player)

	# Kroug segue o Kael com atraso (trilha suave, molde SoS): filho da CENA,
	# não do player — interpola para a posição histórica do líder.
	if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
		buddy_node = Node2D.new()
		buddy_node.position = player.position + Vector2(-44, 26)
		buddy_node.add_child(_make_ground_shadow())
		var kroug_sprite := _animated_sprite("res://assets/sprites/kroug.png", 0.05, Color(0.8, 0.3, 0.1))
		buddy_node.add_child(kroug_sprite)
		_buddy_animator = kroug_sprite.get_meta("animator", null)
		add_child(buddy_node)


## Sprite HD com ciclos de movimento gerados em runtime (MotionLib). Mantém o
## contrato Sprite2D (textura = frame 0 do idle); o UnitAnimator anexado troca
## as texturas a cada frame do ciclo.
func _animated_sprite(path: String, scale_f: float, fallback_color: Color) -> Sprite2D:
	var s := _hd_sprite(path, scale_f, fallback_color)
	if s.texture == null or not FileAccess.file_exists(path):
		return s
	var img: Image = s.texture.get_image()
	if img == null or img.get_width() < 64:
		return s
	var sets := MotionLib.build_motion_sets(img)
	if sets.is_empty():
		return s
	var animator := UnitAnimator.new()
	s.add_child(animator)
	animator.setup(s)
	animator.set_frames(sets)
	# Frames são 256px; o PNG era ~4x maior — compensa a escala de exibição.
	s.scale = s.scale * (float(img.get_width()) / float(MotionLib.FRAME_SIZE))
	s.set_meta("animator", animator)
	return s


func _set_move_anim(anim, moving: bool, dir_x: float = 0.0) -> void:
	if anim == null:
		return
	anim.set_moving(moving)
	if moving and absf(dir_x) > 0.01:
		anim.face_direction(dir_x)


func _make_ground_shadow(offset: Vector2 = Vector2.ZERO) -> Sprite2D:
	## Sombra elíptica suave sob unidades/props (ancora no chão do sprite).
	var shadow := Sprite2D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.4))
	grad.set_color(1, Color(0, 0, 0, 0))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.width = 64
	gtex.height = 32
	shadow.texture = gtex
	shadow.position = offset
	shadow.scale = Vector2(0.55, 0.35)
	return shadow


func _hd_sprite(path: String, scale_f: float, fallback_color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			s.texture = ImageTexture.create_from_image(img)
			s.scale = Vector2(scale_f, scale_f)
			return s
	var fallback := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	fallback.fill(fallback_color)
	s.texture = ImageTexture.create_from_image(fallback)
	return s


func _spawn_enemies() -> void:
	var map: Dictionary = MapDatabase.get_map(map_id)
	var pool: Array = map.get("enemies", ["mercenario"])
	var stage: Dictionary = GameManager.campaign_system.get_current_stage() if GameManager and GameManager.campaign_system else {}
	var count: int = 1 if stage.get("boss", false) else int(map.get("enemy_count", 2))
	if stage.get("boss_enemy", "") != "":
		pool = [stage["boss_enemy"]]

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("enemies_%d_%d" % [map_id, int(GameManager.campaign_system.current_stage if GameManager and GameManager.campaign_system else 0)])
	for i in range(count):
		var type: String = pool[rng.randi() % pool.size()]
		var e: Dictionary = EnemyDatabase.get_enemy(type)
		if e.is_empty():
			continue
		var node := Node2D.new()
		node.position = Vector2(rng.randf_range(760, 1180), rng.randf_range(120, 620))
		node.add_child(_make_ground_shadow())
		node.add_child(_animated_sprite("res://assets/sprites/%s.png" % type, 0.05, Color(e["color"])))
		add_child(node)
		enemy_nodes.append(node)
		_enemy_alert.append(false)
		var foe_sprite: Sprite2D = node.get_children()[0]
		_enemy_animators.append(foe_sprite.get_meta("animator", null))
		var foe_type := "boss" if stage.get("boss", false) else "random"
		encounter.register_enemy("foe_%d" % i, Vector2i(int(node.position.x / TILE), int(node.position.y / TILE)), foe_type, 1)
		_enemy_tile_ids.append("foe_%d" % i)


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var label := Label.new()
	label.position = Vector2(20, 12)
	label.add_theme_font_size_override("font_size", 20)
	label.text = "%s  (HP 80 | MP 50)" % MapDatabase.get_map(map_id).get("name", "")
	_ui.add_child(label)
	_hint_label = Label.new()
	_hint_label.position = Vector2(20, 680)
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.text = HINT_BASE
	_ui.add_child(_hint_label)
	_traversal_hint = Label.new()
	_traversal_hint.position = Vector2(20, 650)
	_traversal_hint.add_theme_font_size_override("font_size", 14)
	_traversal_hint.text = "TRAVESSIA: aproxime-se de um nó e pressione E"
	_ui.add_child(_traversal_hint)
	_build_atmosphere()


# === ATMOSFERA (molde SoS): vinheta + cinzas caindo ===

func _build_atmosphere() -> void:
	# Vinheta: GradientTexture2D radial invertido sobre a tela (elege o centro).
	var vignette := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.45))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.width = 640
	gtex.height = 360
	vignette.texture = gtex
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(vignette)

	# Cinzas: 36 partículas caindo devagar com deriva (lore do mundo).
	_ash_particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("ash_%d" % map_id)
	for i in range(36):
		var dot := ColorRect.new()
		var size := rng.randf_range(1.5, 3.5)
		dot.size = Vector2(size, size)
		dot.color = Color(0.75, 0.72, 0.68, rng.randf_range(0.25, 0.55))
		dot.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(-40, 720))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(dot)
		_ash_particles.append({
			"node": dot,
			"fall": rng.randf_range(18.0, 42.0),
			"drift": rng.randf_range(-10.0, 10.0),
			"phase": rng.randf_range(0.0, TAU),
		})

var _ash_particles: Array = []
var _ash_time: float = 0.0

func _process_atmosphere(delta: float) -> void:
	_ash_time += delta
	for ash in _ash_particles:
		var dot: ColorRect = ash["node"]
		var pos := dot.position
		pos.y += ash["fall"] * delta
		pos.x += sin(_ash_time * 0.8 + ash["phase"]) * ash["drift"] * delta
		if pos.y > 730:
			pos.y = -10
			pos.x = fmod(pos.x + 311.0, 1280.0)
		dot.position = pos


func _process(delta: float) -> void:
	_process_atmosphere(delta)
	if in_encounter() or player == null:
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1
	var moving := dir != Vector2.ZERO
	_set_move_anim(player_animator, moving, dir.x)
	player.position += dir.normalized() * SPEED * delta
	player.position.x = clampf(player.position.x, 30, 1250)
	player.position.y = clampf(player.position.y, 30, 690)

	# Trilha do líder (SoS): histórico de posições do player; o buddy segue
	# ~14 pontos atrás com interpolação — vira e anda independentemente.
	if moving:
		_player_trail.push_front(player.position)
		if _player_trail.size() > 40:
			_player_trail.pop_back()
		_step_distance += SPEED * delta
		if _step_distance > 26.0:
			_step_distance = 0.0
			if SoundManager:
				SoundManager.play_sfx("step")
	if buddy_node:
		var target: Vector2 = _player_trail[mini(13, _player_trail.size() - 1)] if _player_trail.size() > 0 else player.position
		var to_target := target - buddy_node.position
		var buddy_moving := to_target.length() > 6.0
		if buddy_moving:
			buddy_node.position += to_target.normalized() * minf(to_target.length(), SPEED * 1.05 * delta)
		_set_move_anim(_buddy_animator, buddy_moving, to_target.x)

	for i in range(enemy_nodes.size()):
		var node = enemy_nodes[i]
		if not is_instance_valid(node):
			continue
		var to_player: Vector2 = player.position - node.position
		var dist := to_player.length()
		# Telegraph de percepção (SoS): "!" visual + SFX quando entra no raio.
		if dist < 260.0 and not _enemy_alert[i]:
			_enemy_alert[i] = true
			if node.has_node("alert_label") == false:
				var alert := Label.new()
				alert.name = "alert_label"
				alert.text = "!"
				alert.position = Vector2(-6, -64)
				alert.add_theme_font_size_override("font_size", 22)
				alert.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
				node.add_child(alert)
				if SoundManager:
					SoundManager.play_select()
		elif dist >= 300.0:
			_enemy_alert[i] = false
			if node.has_node("alert_label"):
				node.get_node("alert_label").queue_free()
		if dist < 260.0:
			node.position += to_player.normalized() * 90.0 * delta
			_set_move_anim(_enemy_animators[i], true, to_player.x)
		else:
			_set_move_anim(_enemy_animators[i], false)

	_check_contact()
	_process_puzzles(delta)


func in_encounter() -> bool:
	return arena != null


func _check_contact() -> void:
	for i in range(enemy_nodes.size()):
		var node = enemy_nodes[i]
		if not is_instance_valid(node):
			continue
		if player.position.distance_to(node.position) < 44.0:
			_start_arena(i)
			return


func _start_arena(enemy_index: int) -> void:
	arena = load("res://scripts/arena_battle.gd").new()
	arena.battle_ended.connect(_on_battle_ended.bind(enemy_index))
	arena.battle_fled.connect(_on_battle_fled)
	add_child(arena)
	# Labels da exploração somem durante a arena (evita sobreposição com os
	# da batalha: "Agindo", turn_label e hints na mesma região da tela).
	if _ui:
		_ui.visible = false


func _set_explore_ui_visible(visible: bool) -> void:
	if _ui and is_instance_valid(_ui):
		_ui.visible = visible


func _on_battle_ended(victory: bool, rewards: Dictionary, enemy_index: int) -> void:
	arena.queue_free()
	arena = null
	_set_explore_ui_visible(true)
	if victory:
		if enemy_index < enemy_nodes.size() and is_instance_valid(enemy_nodes[enemy_index]):
			enemy_nodes[enemy_index].queue_free()
			enemy_nodes.remove_at(enemy_index)
			_enemy_tile_ids.remove_at(enemy_index)
			if enemy_index < _enemy_animators.size():
				_enemy_animators.remove_at(enemy_index)
		if GameManager:
			GameManager.add_soul_ether(int(rewards.get("soul_ether", 0)))
			# Economia (balance campanha): ouro/XP/materiais da batalha chegam
			# pela mesma porta do soul_ether.
			if int(rewards.get("gold", 0)) > 0:
				GameManager.add_gold(int(rewards["gold"]))
			if int(rewards.get("experience", 0)) > 0 and GameManager.progression_system:
				GameManager.progression_system.add_experience(int(rewards["experience"]))
			if int(rewards.get("materials", 0)) > 0:
				GameManager.building_system.add_resource("materials", int(rewards["materials"]))
		# Vitória encerra o estágio da campanha (mesma porta do fluxo linear)
		# apenas quando o mapa foi LIMPO — 1 estágio por mapa, não por inimigo.
		if enemy_nodes.is_empty() and GameManager and GameManager.campaign_system:
			if GameManager.campaign_system.is_act_boss_stage():
				GameManager.campaign_system.complete_act()
				if GameManager.has_method("save_game"):
					GameManager.save_game()
			else:
				GameManager.campaign_system.advance_stage()
				if GameManager.has_method("save_game"):
					GameManager.save_game()
		if enemy_nodes.is_empty():
			_advance_story()
	else:
		# Derrota: de volta ao menu (retry pelo menu/continuar).
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_battle_fled() -> void:
	arena.queue_free()
	arena = null
	_set_explore_ui_visible(true)
	# Fuga empurra o inimigo para longe (SoS): sem isso o contato <44px
	# reabre o encontro no frame seguinte (loop fugir→reencontrar).
	for i in range(enemy_nodes.size()):
		var node = enemy_nodes[i]
		if is_instance_valid(node) and player != null:
			var away: Vector2 = (node.position - player.position).normalized()
			if away == Vector2.ZERO:
				away = Vector2.RIGHT
			node.position += away * 260.0


func _advance_story() -> void:
	if GameManager and GameManager.campaign_system:
		if GameManager.campaign_system.is_game_complete():
			get_tree().change_scene_to_file("res://scenes/epilogue.tscn")
			return
		if GameManager.campaign_system.has_pending_act_intro():
			get_tree().change_scene_to_file("res://scenes/act_cutscene.tscn")
			return
	# Próximo estágio: recarrega a exploração com o novo mapa/estágio.
	GameManager.sync_current_map_from_campaign()
	get_tree().reload_current_scene()


# === PUZZLES DE LUZ (GDD §6.3) — data-driven via MapDatabase.puzzles ===

func _spawn_puzzles() -> void:
	var map: Dictionary = MapDatabase.get_map(map_id)
	for cfg in map.get("puzzles", []):
		# Persistência §6.3: puzzle já resolvido num save anterior reaparece
		# resolvido (visual) e sem recompensa dupla.
		var already: bool = GameManager.is_puzzle_solved(map_id, String(cfg["id"])) if GameManager else false
		var sys := LightPuzzleSystem.new()
		if not sys.start_puzzle(String(cfg["id"]), String(cfg["type"]), cfg.get("light", Vector2i.ZERO), cfg.get("target", Vector2i.ZERO)):
			continue  # tipo inválido nos dados: pula sem quebrar a cena
		var entry := {"id": String(cfg["id"]), "data": cfg, "system": sys, "nodes": {}, "solved": already}
		for m in cfg.get("mirrors", []):
			sys.add_mirror(String(m["id"]), m.get("pos", Vector2i.ZERO), int(m.get("angle", 0)))
			var node := _make_mirror_node(m)
			entry["nodes"][String(m["id"])] = node
			_update_pointer(entry, String(m["id"]))
		entry["light_node"] = _make_pedestal(cfg.get("light", Vector2i.ZERO), Color(1.0, 0.85, 0.3))
		entry["target_node"] = _make_pedestal(cfg.get("target", Vector2i.ZERO), Color(0.75, 0.3, 0.8))
		if LightPuzzleSystem.PUZZLE_TYPES.get(String(cfg["type"]), {}).get("has_clock", false):
			entry["clock_node"] = _make_clock_node(cfg.get("clock", Vector2i(4, 1)))
		if already:
			entry["light_node"].modulate = Color(0.5, 1.0, 0.5)
			entry["target_node"].modulate = Color(0.5, 1.0, 0.5)
		sys.puzzle_solved.connect(_on_puzzle_solved.bind(entry))
		puzzles.append(entry)


func _tile_center(tile: Vector2) -> Vector2:
	return Vector2(tile.x * TILE + TILE / 2.0, tile.y * TILE + TILE / 2.0)


func _make_mirror_node(m: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.position = _tile_center(m.get("pos", Vector2i.ZERO))
	var core := ColorRect.new()
	core.size = Vector2(14, 14)
	core.position = Vector2(-7, -7)
	core.color = Color(0.65, 0.85, 1.0)
	node.add_child(core)
	var pointer := Line2D.new()
	pointer.points = PackedVector2Array([Vector2.ZERO, Vector2(22, 0)])
	pointer.width = 3.0
	pointer.default_color = Color(1, 1, 1, 0.85)
	node.add_child(pointer)
	node.set_meta("pointer", pointer)
	add_child(node)
	return node


func _make_pedestal(tile: Vector2i, color: Color) -> Node2D:
	var node := Node2D.new()
	node.position = _tile_center(tile)
	var core := ColorRect.new()
	core.size = Vector2(16, 16)
	core.position = Vector2(-8, -8)
	core.color = color
	node.add_child(core)
	add_child(node)
	return node


func _make_clock_node(tile: Vector2i) -> Node2D:
	var node := _make_pedestal(tile, Color(0.95, 0.95, 0.85))
	var sign_label := Label.new()
	sign_label.position = Vector2(-30, -26)
	sign_label.add_theme_font_size_override("font_size", 12)
	sign_label.text = "RELÓGIO"
	node.add_child(sign_label)
	return node


func _update_pointer(entry: Dictionary, mirror_id: String) -> void:
	var node: Node2D = entry["nodes"].get(mirror_id)
	if node == null or not node.has_meta("pointer"):
		return
	var mirror: Dictionary = entry["system"].get_mirror(mirror_id)
	var pointer: Line2D = node.get_meta("pointer")
	# Ângulo 0 do sistema = Norte: Line2D aponta +X, então rotaciona -90°.
	pointer.rotation = deg_to_rad(float(int(mirror.get("angle", 0)) * 45 - 90))
	node.modulate = Color(0.6, 1.0, 0.6) if mirror.get("aligned", false) else Color.WHITE


func _process_puzzles(_delta: float) -> void:
	if traversal:
		traversal.regen_stamina(_delta)
	if Input.is_key_pressed(KEY_E) and not _e_was_down:
		_interact_traversal()
		_interact_puzzles()
	_e_was_down = Input.is_key_pressed(KEY_E)
	_update_puzzle_hint()


# === TRAVESSIA DINÂMICA (GDD §6.1) — nós data-driven via MapDatabase ===

func _spawn_traversal_nodes() -> void:
	traversal = TraversalSystem.new()
	# Asas de Cinzas: unlock de progressão (data-driven do save); sem elas, nós
	# de arpéu exibem o motivo (§6.1) e continuam no mapa.
	traversal.setup(bool(GameManager.game_data.get("has_wings", false)) if GameManager else false)
	var map: Dictionary = MapDatabase.get_map(map_id)
	for cfg in map.get("traversal_nodes", []):
		var node := _make_traversal_node(cfg)
		# Persistência §6.1: nó já feito num save anterior nasce resolvido.
		var already: bool = GameManager.is_traversal_done(map_id, String(cfg["id"])) if GameManager else false
		if already:
			node.modulate = Color(0.5, 1.0, 0.5)
		traversal_nodes.append({"id": String(cfg["id"]), "data": cfg, "node": node, "solved": already})


func _make_traversal_node(cfg: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.position = _tile_center(cfg.get("pos", Vector2i.ZERO))
	var core := ColorRect.new()
	core.size = Vector2(18, 18)
	core.position = Vector2(-9, -9)
	core.color = Color(0.4, 0.9, 0.8)
	node.add_child(core)
	var sign_label := Label.new()
	sign_label.position = Vector2(-40, -30)
	sign_label.add_theme_font_size_override("font_size", 11)
	sign_label.text = String(cfg.get("label", "TRAVESSIA"))
	node.add_child(sign_label)
	add_child(node)
	return node


func _nearest_traversal_node() -> Dictionary:
	if player == null:
		return {}
	var best := {}
	var best_dist: float = PUZZLE_RANGE
	for entry in traversal_nodes:
		if entry.get("solved", false):
			continue
		var node: Node2D = entry["node"]
		var d: float = player.position.distance_to(node.position)
		if d < best_dist:
			best_dist = d
			best = entry
	return best


func _interact_traversal() -> void:
	var entry := _nearest_traversal_node()
	if entry.is_empty():
		return
	var result: Dictionary = traversal.attempt_traversal(String(entry["data"]["ability"]))
	if not result.can:
		_show_traversal_hint("TRAVESSIA: " + result.reason)
		return
	traversal.end_traversal()
	entry["solved"] = true
	entry["node"].modulate = Color(0.5, 1.0, 0.5)
	if GameManager:
		GameManager.mark_traversal_done(map_id, String(entry["id"]))
		if GameManager.has_method("save_game"):
			GameManager.save_game()  # progressão permanente: recompensas + world_state
	var rewards: Dictionary = entry["data"].get("rewards", {})
	if int(rewards.get("soul_ether", 0)) > 0 and GameManager:
		GameManager.add_soul_ether(int(rewards["soul_ether"]))
	if int(rewards.get("gold", 0)) > 0 and GameManager:
		GameManager.add_gold(int(rewards["gold"]))
	if rewards.has("xp") and GameManager and GameManager.progression_system:
		GameManager.progression_system.add_experience(int(rewards["xp"]))
	if entry["data"].get("grants_wings", false) and GameManager:
		GameManager.game_data["has_wings"] = true
		traversal.setup(true)
	_show_traversal_hint("TRAVESSIA CONCLUÍDA! +%d éter, +%d ouro" % [int(rewards.get("soul_ether", 0)), int(rewards.get("gold", 0))])
	if SoundManager:
		SoundManager.play_traversal()


func _show_traversal_hint(text: String) -> void:
	if _traversal_hint and is_instance_valid(_traversal_hint):
		_traversal_hint.text = text


func _nearest_puzzle_node() -> Dictionary:
	if player == null:
		return {}
	var best := {}
	var best_dist := PUZZLE_RANGE
	for entry in puzzles:
		if entry.get("solved", false):
			continue
		for mirror_id in entry["nodes"]:
			var node: Node2D = entry["nodes"][mirror_id]
			var d: float = player.position.distance_to(node.position)
			if d < best_dist:
				best_dist = d
				best = {"entry": entry, "kind": "mirror", "id": mirror_id}
		var clock = entry.get("clock_node")
		if clock != null:
			var dc: float = player.position.distance_to(clock.position)
			if dc < best_dist:
				best_dist = dc
				best = {"entry": entry, "kind": "clock", "id": ""}
	return best


func _interact_puzzles() -> void:
	var target := _nearest_puzzle_node()
	if target.is_empty():
		return
	var entry: Dictionary = target["entry"]
	var sys = entry["system"]
	if String(target["kind"]) == "mirror":
		sys.rotate_mirror(String(target["id"]), 1)
		_update_pointer(entry, String(target["id"]))
	else:
		sys.advance_clock()
	if not entry["solved"] and sys.check_solved():
		sys.complete_puzzle(entry["data"].get("rewards", {}))


func _on_puzzle_solved(puzzle_id: String, rewards: Dictionary, entry: Dictionary) -> void:
	entry["solved"] = true
	if GameManager:
		GameManager.mark_puzzle_solved(map_id, puzzle_id)
		if int(rewards.get("soul_ether", 0)) > 0:
			GameManager.add_soul_ether(int(rewards["soul_ether"]))
		if int(rewards.get("gold", 0)) > 0:
			GameManager.add_gold(int(rewards["gold"]))
		if rewards.has("xp") and GameManager.progression_system:
			GameManager.progression_system.add_experience(int(rewards["xp"]))
		if GameManager.has_method("save_game"):
			GameManager.save_game()  # progressão permanente: recompensas + world_state
	_show_beam(entry)
	if SoundManager:
		SoundManager.play_puzzle()
	if _hint_label:
		_hint_label.text = "Puzzle resolvido: %s (+recompensa)" % puzzle_id


func _show_beam(entry: Dictionary) -> void:
	var data: Dictionary = entry["data"]
	var points: Array = [_tile_center(data.get("light", Vector2i.ZERO))]
	for m in data.get("mirrors", []):
		points.append(_tile_center(m.get("pos", Vector2i.ZERO)))
	points.append(_tile_center(data.get("target", Vector2i.ZERO)))
	var beam := Line2D.new()
	beam.points = PackedVector2Array(points)
	beam.width = 5.0
	beam.default_color = Color(1.0, 0.9, 0.4, 0.9)
	add_child(beam)
	entry["beam"] = beam


func _update_puzzle_hint() -> void:
	if _hint_label == null:
		return
	var target := _nearest_puzzle_node()
	if target.is_empty():
		if _hint_label.text != HINT_BASE and _hint_label.text.begins_with("E:"):
			_hint_label.text = HINT_BASE
		return
	if String(target["kind"]) == "mirror":
		_hint_label.text = "E: girar espelho de obsidiana"
	else:
		_hint_label.text = "E: girar o relógio cósmico"
