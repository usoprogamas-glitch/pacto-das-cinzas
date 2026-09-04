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
var _player_shadow: Sprite2D = null
var _buddy_shadow: Sprite2D = null
var _shadow_phase: float = 0.0
var buddy_sos_char: String = ""  # personagem SoS do buddy (piloto: Garl)
var _buddy_sos_sets: Dictionary = {}
var _buddy_sos_sprite: Sprite2D = null
var _buddy_sos_frame: float = 0.0
var player_sos_char: String = ""  # piloto: Kael renderiza Zale
var _player_sos_sets: Dictionary = {}
var _player_sos_sprite: Sprite2D = null
var _player_sos_frame: float = 0.0
var _enemy_animators: Array = []  # paralelo a enemy_nodes
var _enemy_alert: Array = []  # paralelo a enemy_nodes: já percebeu o jogador?

var _enemy_tile_ids: Array = []  # ids registrados no SeamlessEncounterSystem
var _ui: CanvasLayer
var _hint_label: Label
var _e_was_down := false
var _esc_was_down := false
var _pause_menu: PanelContainer = null
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
	_build_lighting()
	_spawn_biome_particles()
	_play_map_intro()


# === PARTÍCULAS POR BIOMA (SoS): cada mundo respira diferente ===
## Padrão das cinzas: update no _process, determinístico, sem tweens.

var _biome_particles: Array = []  # [{node, vy, drift, phase, pulse, base_a}]

func _spawn_biome_particles() -> void:
	var terrain := _map_terrain()
	match terrain:
		"forest":
			_make_particles(14, [Color(0.55, 0.65, 0.3), Color(0.7, 0.55, 0.25), Color(0.45, 0.55, 0.35)], 3, 1, false, false)
		"volcanic":
			_make_particles(16, [Color(1.0, 0.45, 0.15), Color(1.0, 0.6, 0.2)], 3, -1, false, true)
		"cave":
			_make_particles(10, [Color(0.6, 0.9, 1.0)], 3, 0, false, true)
		"castle":
			_make_particles(12, [Color(0.85, 0.85, 0.9)], 2, 1, false, false)
		_:
			_make_particles(10, [Color(0.95, 0.9, 0.5)], 3, 0, false, true)


func _make_particles(count: int, colors: Array, size: int, vy_sign: int, _unused: bool, pulse: bool) -> void:
	var speeds := {"forest": Vector2(28.0, 16.0), "volcanic": Vector2(20.0, 8.0), "cave": Vector2(6.0, 10.0), "castle": Vector2(8.0, 5.0)}
	var sp: Vector2 = speeds.get(_map_terrain(), Vector2(20.0, 10.0))
	for i in range(count):
		var dot := ColorRect.new()
		dot.size = Vector2(size, size)
		var col: Color = colors[i % colors.size()]
		dot.color = Color(col.r, col.g, col.b, randf_range(0.3, 0.7))
		dot.position = Vector2(randf_range(0, 1280), randf_range(-40, 720))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(dot)
		_biome_particles.append({
			"node": dot,
			"vy": sp.y * vy_sign * randf_range(0.7, 1.3),
			"drift": sp.x * randf_range(-1.0, 1.0),
			"phase": randf_range(0.0, TAU),
			"pulse": pulse,
			"base_a": dot.color.a,
			"period": randf_range(1.0, 2.5),
		})


func _process_biome_particles(delta: float) -> void:
	_ash_time += delta
	for p in _biome_particles:
		var dot: ColorRect = p["node"]
		var pos: Vector2 = dot.position
		pos.y += p["vy"] * delta
		pos.x += sin(_ash_time * 0.8 + p["phase"]) * p["drift"] * delta
		var out_bottom: bool = pos.y > 730 and p["vy"] > 0
		var out_top: bool = pos.y < -20 and p["vy"] < 0
		if out_bottom or out_top:
			pos.y = -20.0 if p["vy"] > 0 else 740.0
			pos.x = randf_range(0, 1280)
		dot.position = pos
		if p["pulse"]:
			var a: float = p["base_a"] * (0.55 + 0.45 * sin(_ash_time * TAU / p["period"] + p["phase"]))
			dot.color.a = a


# === ILUMINAÇÃO DINÂMICA (SoS): escurece o mundo + poços de luz aditivos ===

func _build_lighting() -> void:
	# CanvasModulate: escurece o mundo; as luzes "revelam" por cima.
	var modulate := CanvasModulate.new()
	modulate.color = _ambient_color()
	add_child(modulate)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("light_%s" % String(MapDatabase.get_map(map_id).get("name", "")))
	var count: int = int({"cave": 5, "volcanic": 6, "castle": 4, "forest": 2}.get(_map_terrain(), 3))
	for i in range(count):
		var light := Sprite2D.new()
		light.texture = _light_gradient_texture()
		light.material = _add_blend_material()
		light.position = Vector2(rng.randf_range(120, 1160), rng.randf_range(100, 640))
		light.scale = Vector2(2.2, 2.2)
		light.modulate = Color(1.0, 0.75, 0.4, rng.randf_range(0.5, 0.75))
		add_child(light)
		# Flicker sutil (vida da chama).
		var flicker := create_tween().set_loops()
		var base_alpha: float = light.modulate.a
		flicker.tween_property(light, "modulate:a", base_alpha * 0.75, rng.randf_range(0.7, 1.3)).set_trans(Tween.TRANS_SINE)
		flicker.tween_property(light, "modulate:a", base_alpha, rng.randf_range(0.7, 1.3)).set_trans(Tween.TRANS_SINE)


func _light_gradient_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.75, 0.4, 0.6))
	grad.set_color(1, Color(1.0, 0.75, 0.4, 0.0))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	gtex.width = 256
	gtex.height = 256
	return gtex


func _add_blend_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _map_terrain() -> String:
	return String(MapDatabase.get_map(map_id).get("terrain", "mixed"))


func _ambient_color() -> Color:
	match _map_terrain():
		"cave":
			return Color(0.62, 0.62, 0.7)  # caverna fria e escura
		"volcanic":
			return Color(0.85, 0.72, 0.62)  # brasa quente
		"castle":
			return Color(0.78, 0.76, 0.8)  # pedra fria
		"forest":
			return Color(0.72, 0.78, 0.68)  # copas filtrando o sol
		_:
			return Color(0.88, 0.86, 0.8)  # crepúsculo da Fronteira
	_play_map_intro()


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
	_player_shadow = _make_ground_shadow()
	player.add_child(_player_shadow)
	# Piloto SoS (estudo): Kael renderiza NarcisKingZale quando disponível.
	var sos_kael: Dictionary = SOSMotionLoader.build_motion_sets("NarcisKingZale", 3)
	if not sos_kael.is_empty():
		player_sos_char = "NarcisKingZale"
		_player_sos_sets = _hue_shift_sets(sos_kael, 0.55)  # azul Valere: contrasta com o verde do chão
		_player_sos_sprite = Sprite2D.new()
		_player_sos_sprite.texture = _player_sos_sets["idle"][0]
		_player_sos_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_player_sos_sprite.scale = Vector2(1.7, 1.7)
		player.add_child(_player_sos_sprite)
	var kael_sprite := _animated_sprite("res://assets/sprites/kael.png", 0.06, Color(0.2, 0.8, 0.3))
	if player_sos_char == "":
		player.add_child(kael_sprite)
	player_animator = kael_sprite.get_meta("animator", null)
	add_child(player)

	# Kroug segue o Kael com atraso (trilha suave, molde SoS): filho da CENA,
	# não do player — interpola para a posição histórica do líder.
	if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
		buddy_node = Node2D.new()
		buddy_node.position = player.position + Vector2(-44, 26)
		_buddy_shadow = _make_ground_shadow()
		buddy_node.add_child(_buddy_shadow)
		# Sprite SoS do Garl (estudo): walk cycle real por direção.
		if SOSMotionLoader.build_motion_sets("Garl", 1):
			buddy_sos_char = "Garl"
			var sos_sets: Dictionary = _hue_shift_sets(SOSMotionLoader.build_motion_sets("Garl", 1), 0.07)  # laranja Kroug
			var sos_sprite := Sprite2D.new()
			sos_sprite.texture = sos_sets["idle"][0]
			sos_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sos_sprite.scale = Vector2(1.7, 1.7)
			buddy_node.add_child(sos_sprite)
			_buddy_animator = null  # direção manual (ver _process do buddy SoS)
			_buddy_sos_sets = sos_sets
			_buddy_sos_sprite = sos_sprite
		else:
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


## Direções SoS: D1=Sul, D2=SO, D3=Oeste, D4=Norte, D5=Leste.
func _sos_dir_from_vector(v: Vector2) -> int:
	if v == Vector2.ZERO:
		return 1
	if absf(v.x) > absf(v.y):
		return 5 if v.x > 0 else 3
	return 1 if v.y > 0 else 5


## Recoloração por dominância de matiz: pixels do matiz dominante do sprite
## (a roupa do personagem) migram para o matiz alvo. Preserva sombreado.
func _hue_shift_sets(sets: Dictionary, target_hue: float) -> Dictionary:
	var shifted := {}
	for action: String in sets:
		shifted[action] = []
		for tex in sets[action]:
			var img: Image = tex.get_image()
			if img == null:
				continue
			_shift_hue_image(img, target_hue)
			shifted[action].append(ImageTexture.create_from_image(img))
	return shifted


func _shift_hue_image(img: Image, target_hue: float) -> void:
	# 1) matiz dominante (maior soma de saturação^2 * alpha)
	var hue_x := 0.0
	var hue_y := 0.0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.s > 0.25 and c.v > 0.15:
				hue_x += cos(c.h * TAU) * c.s
				hue_y += sin(c.h * TAU) * c.s
	if hue_x == 0.0 and hue_y == 0.0:
		return
	var dominant := atan2(hue_y, hue_x) / TAU
	if dominant < 0:
		dominant += 1.0
	var delta := (target_hue - dominant)
	# 2) rotaciona a matiz dos pixels saturados na mesma proporção
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a < 0.05 or c.s < 0.2:
				continue
			var shifted := c
			shifted.h = fposmod(c.h + delta, 1.0)
			img.set_pixel(x, y, shifted)
	# 3) Contorno interno escuro (assinatura SoS): pixels opacos adjacentes a
	#    transparentes escurecem ~60%, dando leitura de desenho.
	var w2 := img.get_width()
	var h2 := img.get_height()
	var edges := []
	for y in range(h2):
		for x in range(w2):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var transparent_neighbor := false
			for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if nx < 0 or ny < 0 or nx >= w2 or ny >= h2:
					transparent_neighbor = true
					break
				if img.get_pixel(nx, ny).a < 0.5:
					transparent_neighbor = true
					break
			if transparent_neighbor:
				edges.append(Vector2i(x, y))
	for e in edges:
		var c := img.get_pixel(e.x, e.y)
		img.set_pixel(e.x, e.y, Color(c.r * 0.35, c.g * 0.35, c.b * 0.35, c.a))


## Tick do sprite SoS: troca frame do walk cycle na direção dada.
func _tick_sos_sprite(sprite: Sprite2D, sets: Dictionary, dir_key: int, moving: bool, delta: float, frame_state) -> void:
	if sprite == null or sets.is_empty():
		return
	var action := "walk" if moving else "idle"
	var frames: Array = sets.get(action, [])
	if frames.is_empty():
		return
	var fps := 8.0 if moving else 3.0
	frame_state += fps * delta
	if int(frame_state) >= frames.size():
		frame_state = 0.0
	sprite.texture = frames[int(frame_state)]
	# D3 = Oeste: flip para Leste (sprites SoS andam para a esquerda por padrão).
	if dir_key == 5:
		sprite.flip_h = true
	elif dir_key == 3:
		sprite.flip_h = false


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
	# Status real da party (era hardcoded "(HP 80 | MP 50)" — parecia debug).
	var kael: Dictionary = GameManager.party_data[0] if GameManager and GameManager.party_data.size() > 0 else {}
	label.text = "%s   ·   HP %d" % [
		String(MapDatabase.get_map(map_id).get("name", "")),
		int(kael.get("hp", 0)),
	]
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	_ui.add_child(label)
	_hint_label = Label.new()
	_hint_label.position = Vector2(20, 680)
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.text = HINT_BASE
	_ui.add_child(_hint_label)
	_traversal_hint = Label.new()
	_traversal_hint.position = Vector2(20, 650)
	_traversal_hint.add_theme_font_size_override("font_size", 14)
	# Hint só em mapa com nós de travessia (mapa 0 não tem: instrução vazia).
	var has_traversal: bool = MapDatabase.get_map(map_id).get("traversal_nodes", []).size() > 0
	_traversal_hint.text = "TRAVESSIA: aproxime-se de um nó e pressione E" if has_traversal else ""
	_traversal_hint.visible = has_traversal
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

## Entrada do mapa (SoS): fade de preto + banner com nome do local.
func _play_map_intro() -> void:
	var map: Dictionary = MapDatabase.get_map(map_id)
	var banner := Label.new()
	var tutorial: String = ""
	if GameManager and not GameManager.game_data.get("tutorials", {}).get("movement", false):
		GameManager.game_data.get_or_add("tutorials", {})["movement"] = true
		tutorial = "\n\nWASD/Setas: mover · Shift: correr · E: interagir · ESC: pausa"
	banner.text = String(map.get("name", "")) + tutorial
	banner.add_theme_font_size_override("font_size", 34)
	banner.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	banner.add_theme_constant_override("shadow_offset_x", 2)
	banner.add_theme_constant_override("shadow_offset_y", 2)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.position = Vector2(640 - 200, 300)
	banner.custom_minimum_size = Vector2(400, 50)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(banner)
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 1.0)
	fade.size = Vector2(1280, 720)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(fade)
	fade.move_to_front()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.9)
	tween.parallel().tween_property(banner, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.1)
	tween.tween_property(banner, "modulate:a", 0.0, 0.7)
	tween.parallel().tween_callback(banner.queue_free)
	tween.tween_callback(fade.queue_free)

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
	_process_biome_particles(delta)
	if in_encounter() or player == null:
		return
	# Pausado: mundo congelado (movimento/contatos), só o menu respira.
	if _pause_menu != null and is_instance_valid(_pause_menu) and _pause_menu.visible:
		_process_puzzles(delta)
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
	# Sprint (Shift): 1.65x, molde SoS — exploração rápida sem quebrar o trail.
	var sprinting := moving and (Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("ui_shift"))
	var speed := SPEED * (1.65 if sprinting else 1.0)
	if player_animator and sprinting:
		player_animator.animation_speed = 1.4  # passos mais rápidos no walk cycle
	elif player_animator:
		player_animator.animation_speed = 1.0
	_set_move_anim(player_animator, moving, dir.x)
	player.position += dir.normalized() * speed * delta
	player.position.x = clampf(player.position.x, 30, 1250)
	player.position.y = clampf(player.position.y, 30, 690)

	# Trilha do líder (SoS): histórico de posições do player; o buddy segue
	# ~14 pontos atrás com interpolação — vira e anda independentemente.
	if moving:
		_player_trail.push_front(player.position)
		if _player_trail.size() > 40:
			_player_trail.pop_back()
		_step_distance += speed * delta
		# Passos: intervalo menor ao correr (cadência de corrida).
		if _step_distance > (17.0 if sprinting else 26.0):
			_step_distance = 0.0
			if SoundManager:
				SoundManager.play_sfx("step")
	# Sprites SoS na exploração: walk cycle real por direção do movimento.
	var dir_key := _sos_dir_from_vector(dir)
	if player_sos_char != "":
		_tick_sos_sprite(_player_sos_sprite, _player_sos_sets, dir_key, moving, delta, _player_sos_frame)
	if buddy_node and buddy_sos_char != "":
		var target: Vector2 = _player_trail[mini(13, _player_trail.size() - 1)] if _player_trail.size() > 0 else player.position
		var to_target := target - buddy_node.position
		var buddy_moving := to_target.length() > 6.0
		if buddy_moving:
			buddy_node.position += to_target.normalized() * minf(to_target.length(), speed * 1.05 * delta)
		var buddy_dir := _sos_dir_from_vector(to_target) if buddy_moving else dir_key
		_tick_sos_sprite(_buddy_sos_sprite, _buddy_sos_sets, buddy_dir, buddy_moving, delta, _buddy_sos_frame)
	elif buddy_node:
		var target: Vector2 = _player_trail[mini(13, _player_trail.size() - 1)] if _player_trail.size() > 0 else player.position
		var to_target := target - buddy_node.position
		var buddy_moving := to_target.length() > 6.0
		if buddy_moving:
			buddy_node.position += to_target.normalized() * minf(to_target.length(), speed * 1.05 * delta)
		_set_move_anim(_buddy_animator, buddy_moving, to_target.x)

	# Sombras respiram com o idle (fase 4Hz do IDLE_FPS do animator): escala
	# varia sutilmente, lendo como peso do personagem no chão.
	_shadow_phase += delta * TAU * 4.0 * 0.5
	var shadow_scale := 0.55 + sin(_shadow_phase) * 0.02
	if _player_shadow:
		_player_shadow.scale = Vector2(shadow_scale, shadow_scale * 0.35 / 0.55 * 0.55)
	if _buddy_shadow:
		_buddy_shadow.scale = Vector2(shadow_scale, shadow_scale * 0.35 / 0.55 * 0.55)

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


# === MENU DE PAUSA (ESC): status da party + voltar ===

func _toggle_pause_menu() -> void:
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.visible = not _pause_menu.visible
	else:
		_build_pause_menu()
		_pause_menu.visible = true


func _build_pause_menu() -> void:
	_pause_menu = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.94)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	style.border_color = Color(0.5, 0.45, 0.3, 0.8)
	style.set_border_width_all(2)
	_pause_menu.add_theme_stylebox_override("panel", style)
	_pause_menu.position = Vector2(440, 180)
	_pause_menu.custom_minimum_size = Vector2(400, 0)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_pause_menu.add_child(vbox)
	var title := Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	# Status da party (molde SoS: HP/MP por membro).
	for member in GameManager.party_data:
		var row := Label.new()
		row.text = "%s  —  HP %s  ·  Éter %s  ·  ATK %s" % [
			String(member.get("name", "?")),
			str(int(member.get("hp", 0))),
			str(int(member.get("ether", 0))),
			str(int(member.get("atk", 0))),
		]
		row.add_theme_font_size_override("font_size", 15)
		vbox.add_child(row)
	var sep := HSeparator.new()
	vbox.add_child(sep)
	var resumo := Label.new()
	resumo.text = "Ato %d · %s\nÉter %d · Ouro %d · Materiais %d" % [
		GameManager.campaign_system.current_act + 1 if GameManager and GameManager.campaign_system else 1,
		String(MapDatabase.get_map(map_id).get("name", "")),
		int(GameManager.game_data.get("soul_ether", 0)),
		int(GameManager.game_data.get("gold", 0)),
		int(GameManager.building_system.resources.get("materials", 0)) if GameManager else 0,
	]
	resumo.add_theme_font_size_override("font_size", 14)
	resumo.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	vbox.add_child(resumo)
	var close := Button.new()
	close.text = "Continuar (ESC)"
	close.custom_minimum_size = Vector2(220, 32)
	close.pressed.connect(_toggle_pause_menu)
	vbox.add_child(close)
	_ui.add_child(_pause_menu)
	_pause_menu.move_to_front()


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
	# Pedestal de puzzle: base circular escura + anel do tom do pedestal
	# (substitui os quadradinhos chapados vistos no QA visual).
	var base := _make_ground_shadow(Vector2.ZERO)
	base.scale = Vector2(0.5, 0.3)
	node.add_child(base)
	var ring := Line2D.new()
	ring.points = _circle_points(9.0, 10)
	ring.default_color = color
	ring.width = 2.5
	ring.closed = true
	node.add_child(ring)
	var core := ColorRect.new()
	core.size = Vector2(7, 7)
	core.position = Vector2(-3.5, -3.5)
	core.color = color.lightened(0.15)
	node.add_child(core)
	add_child(node)
	return node


func _circle_points(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(sides + 1):
		var angle := TAU * i / sides
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


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
	if Input.is_key_pressed(KEY_ESCAPE) and not _esc_was_down:
		_toggle_pause_menu()
	_esc_was_down = Input.is_key_pressed(KEY_ESCAPE)
	if _pause_menu != null and is_instance_valid(_pause_menu) and _pause_menu.visible:
		return  # pausado: para interações do mundo
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
