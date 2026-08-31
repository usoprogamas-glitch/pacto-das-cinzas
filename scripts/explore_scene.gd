extends Node2D

## Cena de exploração contínua no molde Sea of Stars (opção 3): o grupo anda
## pelo mapa em tempo real; inimigos visíveis patrulham/perseguem (SeamlessEncounterSystem)
## e o contato abre a arena de batalha IN-PLACE, sem troca de cena (GDD §6.2).
##
## Teclas: setas/WASD move.

const SPEED := 220.0  ## px/s
const TILE := 64.0

var encounter  # SeamlessEncounterSystem
var player: Node2D
var enemy_nodes: Array = []
var arena: Node = null
var map_id: int = 0

var _enemy_tile_ids: Array = []  # ids registrados no SeamlessEncounterSystem
var _ui: CanvasLayer


func _ready() -> void:
	encounter = SeamlessEncounterSystem.new()
	map_id = GameManager.game_data.get("current_map", 0) if GameManager else 0
	_build_map()
	_spawn_party()
	_spawn_enemies()
	_build_ui()


func _build_map() -> void:
	var map: Dictionary = MapDatabase.get_map(map_id)
	var bg := ColorRect.new()
	bg.color = _terrain_color(String(map.get("terrain", "mixed")))
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_id)
	for i in range(24):
		var deco := ColorRect.new()
		var s := rng.randf_range(10, 26)
		deco.size = Vector2(s, s)
		deco.position = Vector2(rng.randf_range(20, 1240), rng.randf_range(20, 660))
		deco.color = bg.color.darkened(0.35)
		add_child(deco)


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
	player.add_child(_hd_sprite("res://assets/sprites/kael.png", 0.06, Color(0.2, 0.8, 0.3)))
	add_child(player)

	# Kroug segue o Kael (party no mapa, molde SoS).
	if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
		var buddy := Node2D.new()
		buddy.position = Vector2(-44, 26)
		buddy.add_child(_hd_sprite("res://assets/sprites/kroug.png", 0.05, Color(0.8, 0.3, 0.1)))
		player.add_child(buddy)


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
		node.add_child(_hd_sprite("res://assets/sprites/%s.png" % type, 0.05, Color(e["color"])))
		add_child(node)
		enemy_nodes.append(node)
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
	var hint := Label.new()
	hint.position = Vector2(20, 680)
	hint.add_theme_font_size_override("font_size", 15)
	hint.text = "Setas/WASD: mover  |  Encoste no inimigo para lutar (Timed Hit/Block: clique!)"
	_ui.add_child(hint)


func _process(delta: float) -> void:
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
	player.position += dir.normalized() * SPEED * delta
	player.position.x = clampf(player.position.x, 30, 1250)
	player.position.y = clampf(player.position.y, 30, 690)

	for node in enemy_nodes:
		if not is_instance_valid(node):
			continue
		var to_player: Vector2 = player.position - node.position
		if to_player.length() < 260.0:
			node.position += to_player.normalized() * 90.0 * delta

	_check_contact()


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


func _on_battle_ended(victory: bool, rewards: Dictionary, enemy_index: int) -> void:
	arena.queue_free()
	arena = null
	if victory:
		if enemy_index < enemy_nodes.size() and is_instance_valid(enemy_nodes[enemy_index]):
			enemy_nodes[enemy_index].queue_free()
			enemy_nodes.remove_at(enemy_index)
			_enemy_tile_ids.remove_at(enemy_index)
		if GameManager:
			GameManager.add_soul_ether(int(rewards.get("soul_ether", 0)))
		# Vitória encerra o estágio da campanha (mesma porta do fluxo linear).
		if GameManager and GameManager.campaign_system:
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
