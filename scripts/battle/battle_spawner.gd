extends RefCounted
## Spawner de unidades do battle_scene (P2 #13 — extração do god file).
## Responsabilidades: pool data-driven de inimigos (ROADMAP #8), party + almas
## nomeadas, criação de Unit (sprite/HP bar/animator) e binding de bosses ao
## BossSystem. Acessa a cena dona via `battle` (membros públicos/stubs de teste).

var battle: Node2D


func setup_battle() -> void:
	# BGM data-driven (P0-4): o campo "music" do mapa (exploration/battle) nunca
	# era lido — batalhas rodavam em silêncio de fundo.
	var current_map_for_music = MapDatabase.get_map(GameManager.game_data.get("current_map", 0))
	if current_map_for_music and SoundManager:
		SoundManager.play_music(current_map_for_music.get("music", "exploration"))

	# Inicializar sistema de autotile para o mapa (aplicado sobre a camada de terreno do grid)
	battle.autotile_system.auto_tile_map(battle.grid.terrain_layer, 0, Rect2i(0, 0, 12, 12))
	battle.autotile_system.setup_animated_tiles(battle.grid.terrain_layer)
	battle.autotile_system.apply_random_variations(battle.grid.terrain_layer, Rect2i(0, 0, 12, 12), 0.15)

	# Root-cause fix: spawnar o grupo principal ANTES dos inimigos. Antes disso o
	# caminho de current_map spawnava só inimigos -> instant loss. DRY: helper
	# único, usado também pelo fallback abaixo.
	spawn_player_party()

	# Obter o mapa atual
	var current_map = MapDatabase.get_map(GameManager.game_data.get("current_map", 0))
	if current_map:
		# Pool de inimigos resolvido de forma data-driven (ROADMAP #8): o estágio
		# pode declarar "boss_enemy" para substituir o pool do mapa (Ato I
		# compartilha o mapa 0 com batalhas comuns); Atos II-IV têm pool próprio
		# no mapa (Cardeais/Aurius, 1 unidade).
		var pool = resolve_enemy_pool(current_map)
		var enemies = pool.enemies
		var enemy_count = pool.count

		var enemy_positions = MapDatabase.get_enemy_spawn_positions(GameManager.game_data.get("current_map", 0), enemy_count)

		for i in range(min(enemy_count, enemy_positions.size())):
			var enemy_type = enemies[randi() % enemies.size()]
			var enemy_data = EnemyDatabase.get_enemy(enemy_type)
			if enemy_data:
				spawn_enemy_unit(enemy_positions[i], enemy_data.name, Color(enemy_data.color.r, enemy_data.color.g, enemy_data.color.b), enemy_data.class, enemy_data.hp, enemy_data.atk, enemy_data.def, enemy_data.mov, enemy_data.rng)
	else:
		# Fallback para spawn padrão (reusa o helper acima — uma só fonte de verdade)
		spawn_enemy_unit(Vector2i(9, 5), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
		spawn_enemy_unit(Vector2i(10, 6), "Mercenário", Color(0.7, 0.2, 0.2), "Guerreiro", 60, 14, 10, 3, 1)
		spawn_enemy_unit(Vector2i(8, 4), "Caçador", Color(0.6, 0.3, 0.3), "Arqueiro", 45, 16, 5, 4, 3)

	# Iniciar tutorial na primeira batalha
	if not FileAccess.file_exists("user://tutorial_completed"):
		battle.tutorial_system.start_tutorial()


# Pool de inimigos da batalha (ROADMAP #8): fonte de verdade data-driven.
# Estágio de campanha pode declarar "boss_enemy" (chefe sem mapa próprio);
# caso contrário vale o pool do mapa (Cardeais/Aurius já definidos lá).
func resolve_enemy_pool(current_map: Dictionary) -> Dictionary:
	var enemies: Array = current_map.get("enemies", [])
	var enemy_count: int = current_map.get("enemy_count", 1)
	if GameManager and GameManager.campaign_system:
		var stage: Dictionary = GameManager.campaign_system.get_current_stage()
		var boss_enemy: String = stage.get("boss_enemy", "")
		if boss_enemy != "":
			enemies = [boss_enemy]
			enemy_count = 1
	return {"enemies": enemies, "count": enemy_count}


func spawn_player_party() -> void:
	# Stats de CharacterProgression (runtime) — literais preservam o balanço herdado
	# (atk Kael = 12 literal, não o default 8 de protagonist_stats.stats).
	var stats: Dictionary = {}
	if GameManager and GameManager.character_progression:
		stats = GameManager.character_progression.get_protagonist_stats()
	var hp: int = stats.get("hp", 80)
	var atk: int = 12
	var def: int = 8
	# Fonte da verdade: GameManager.party_data (persistida no save). Fallback para
	# jogo novo / caminho legado sem party registrada.
	var party: Array[Dictionary] = []
	if GameManager and GameManager.party_data and not GameManager.party_data.is_empty():
		party = GameManager.party_data
	else:
		party = [{"name": "Kael", "class": "Imp Menor", "hp": hp, "atk": atk, "def": def, "mov": 3, "rng": 1}]
		if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
			party.append({"name": "Kroug", "class": "Goblin da Lama", "hp": 120, "atk": 10, "def": 15, "mov": 2, "rng": 1})
	for i in range(party.size()):
		var m: Dictionary = party[i]
		var grid_pos = Vector2i(2 + i, 6)
		spawn_player_unit(
			grid_pos,
			m.get("name", "Kael"),
			party_color(m.get("name", "")),
			m.get("class", "Imp Menor"),
			int(m.get("hp", 80)),
			int(m.get("atk", atk)),
			int(m.get("def", def)),
			int(m.get("mov", 3)),
			int(m.get("rng", 1))
		)
	spawn_named_souls(party_names(party))


func party_names(party: Array) -> Array:
	var names: Array = []
	for m in party:
		names.append(m.get("name", ""))
	return names


func party_color(member_name: String) -> Color:
	match member_name:
		"Kroug":
			return Color(0.8, 0.3, 0.1)
		"Lira":
			return Color(0.3, 0.8, 0.4)
		"Thal'kor":
			return Color(0.4, 0.3, 0.8)
		_:
			return Color(0.2, 0.8, 0.3)


# Spawna as almas nomeadas do save (NamingSystem) como aliados vivos, usando o
# NOME real persistido + stats evoluídos (ROADMAP #9). Almas canônicas já
# spawnadas (Kroug via starting_ally) são puladas por nome.
func spawn_named_souls(spawned: Array = []) -> void:
	if not GameManager or not GameManager.naming_system:
		return
	# Slots ao redor do Kael (evita sobreposição em party grande).
	var offsets: Array[Vector2i] = [
		Vector2i(3, 6), Vector2i(1, 5), Vector2i(3, 7), Vector2i(2, 8), Vector2i(3, 5)
	]
	var idx: int = 0
	for soul in GameManager.naming_system.get_all_souls():
		if idx >= offsets.size():
			break
		var soul_name: String = soul.get("name", "Alma Nomeada")
		if soul_name in spawned:
			continue
		var soul_stats: Dictionary = soul.get("stats", {})
		var hp_val: int = soul_stats.get("hp", 80)
		var atk_val: int = soul_stats.get("attack", 10)
		var def_val: int = soul_stats.get("defense", 8)
		spawn_player_unit(offsets[idx], soul_name, Color(0.6, 0.6, 0.9), soul.get("original_type", "Monstro"), hp_val, atk_val, def_val, 2, 1)
		spawned.append(soul_name)
		idx += 1


func spawn_player_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
	var unit = create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, true)
	BattleManager.register_unit(unit)
	return unit


func spawn_enemy_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int) -> Unit:
	var unit = create_unit(grid_pos, unit_name, color, unit_class, hp, atk, def, mov, rng, false)
	BattleManager.register_unit(unit)
	# §5 Boss runtime: classe Boss = chefe no campo → sincroniza BossSystem (panel + HP).
	# Cardinal resolvido pelo NOME da unidade (antes: por classe → todos viravam Ignis).
	if unit_class == "Boss" and resolve_cardinal_name(unit_name) != "":
		spawn_runtime_boss(unit)
	return unit


## Vincula o boss em campo ao BossSystem: nome/cardinal resolvido por nome, HP da Unit real.
func spawn_runtime_boss(unit: Unit) -> void:
	var cardinal: String = resolve_cardinal_name(unit.data.unit_name)
	battle.boss_system.spawn_runtime_boss(cardinal, unit.data.max_hp)
	unit.hp_changed.connect(func(hp: int) -> void: battle.boss_system.sync_runtime_hp(hp))


## Nome da unidade → cardinal do BossSystem (data-driven):
## - Cardeais: o nome do EnemyDatabase CASA com a chave de BossSystem.CARDINALS.
## - Aurius: as 3 fases têm nomes distintos no EnemyDatabase → todas viram "Aurius".
## - "Santo Cardeal" (mapa lateral 4): mantém o binding legado com Ignis.
## - Demais nomes: "" (não é chefe conhecido).
func resolve_cardinal_name(unit_name: String) -> String:
	if battle.boss_system and battle.boss_system.CARDINALS.has(unit_name):
		return unit_name
	if unit_name.begins_with("Aurius"):
		return "Aurius"
	if unit_name == "Santo Cardeal":
		return "Ignis"
	return ""


func create_unit(grid_pos: Vector2i, unit_name: String, color: Color, unit_class: String, hp: int, atk: int, def: int, mov: int, rng: int, is_player: bool) -> Unit:
	var unit = Unit.new()
	unit.name = unit_name

	# Criar sprite visual usando PixelArtRenderer
	var sprite = create_unit_sprite(unit_name, color, is_player)
	unit.add_child(sprite)

	# ORDEM IMPORTA: styleboxes ANTES do size (min-height 27px do tema padrão
	# clampeia o size.y e vira bloco sobre o rosto — ver arena_battle).
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.show_percentage = false
	hp_bar.visible = false  # limpa o visual: só aparece quando a unidade estiver ferida
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.8, 0.2)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.2, 0.2)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_bar.position = Vector2(-16, -24)
	hp_bar.size = Vector2(32, 4)
	hp_bar.max_value = hp
	hp_bar.value = hp
	unit.add_child(hp_bar)

	var selection = ColorRect.new()
	selection.name = "SelectionIndicator"
	selection.color = Color(1, 1, 0, 0.4)
	selection.position = Vector2(-4, -4)
	selection.size = Vector2(40, 40)
	selection.visible = false
	unit.add_child(selection)

	var data = UnitData.new()
	data.unit_name = unit_name
	data.is_player = is_player
	data.unit_class = unit_class
	data.max_hp = hp
	data.current_hp = hp
	data.attack = atk
	data.defense = def
	data.move_range = mov
	data.attack_range = rng
	data.color = color
	data.soul_ether_value = 10 if is_player else 15
	unit.data = data

	var inst = place_unit(unit, grid_pos)
	if not inst:
		return null

	# Criar animador
	var animator = UnitAnimator.new()
	animator.name = "Animator"
	(unit as Node).add_child(animator)
	animator.setup(unit)
	# Chave por instância: 2 inimigos de mesmo nome ("Mercenário" ×2) compartilhavam
	# UMA entrada → animações tocavam na unidade errada. Instance ID é único.
	battle.unit_animators[unit.get_instance_id()] = animator
	animator.play_idle()

	# Aplicar efeitos visuais avançados
	if battle.pixel_art_renderer and battle.pixel_art_renderer.has_method("apply_all_effects"):
		battle.pixel_art_renderer.apply_all_effects(sprite, sprite_key(unit_name))

	return unit


# Coloca a unit no grid/rótulo. Isolado p/ stubbing: testes de spawn chamam
# spawn_player_party sem árvore (sem $BattleGrid/$UnitContainer); a variante
# real usa grid à vista, a variante de teste stub usa um fake geométrico.
func place_unit(unit, grid_pos: Vector2i) -> bool:
	unit.grid_position = grid_pos
	if battle.grid:
		unit.position = battle.grid.grid_to_pixel(grid_pos)
	elif unit.has_method("set_grid_position"):
		unit.set_grid_position(grid_pos)
	if battle.unit_container:
		battle.unit_container.add_child(unit)
		return true
	return false


func create_unit_sprite(unit_name: String, color: Color, is_player: bool) -> Sprite2D:
	# Factory única de sprite de unidade: toda saída sai normalizada à célula
	# (BattleGrid.TILE_SIZE) — HD 1024px e procedurais 64-128px entram cruos.
	var sprite = _create_unit_sprite_raw(unit_name, color, is_player)
	normalize_sprite_to_tile(sprite)
	return sprite


## Normaliza o sprite à célula do grid (BattleGrid.TILE_SIZE): sprites HD
## (1024px) e procedurais (64-128px) chegam em tamanhos heterogêneos — sem isto,
## o sprite HD é 32x a célula (GDD §10.1: sprites 32x32).
func normalize_sprite_to_tile(sprite: Sprite2D) -> void:
	if sprite == null or sprite.texture == null:
		return
	var effective := sprite.texture.get_width() * sprite.scale.x
	if effective <= 0.0:
		return
	var factor := float(BattleGrid.TILE_SIZE) / effective
	sprite.scale *= factor


func _create_unit_sprite_raw(unit_name: String, color: Color, is_player: bool) -> Sprite2D:
	# HD 2D: usa textura de assets/sprites/<key>.png se existir (gerada via ComfyUI).
	# Fallback: PixelArtRenderer procedural.
	var char_key = sprite_key(unit_name)
	var hd = load_hd_sprite("res://assets/sprites/" + char_key + ".png")
	if hd:
		return hd

	# Usar PixelArtRenderer para sprites detalhados
	match char_key:
		"kael":
			return battle.pixel_art_renderer.create_kael("imp")
		"kroug":
			return battle.pixel_art_renderer.create_kroug()
		"lira":
			return battle.pixel_art_renderer.create_lira()
		"thal'kor", "thalkor":
			return battle.pixel_art_renderer.create_thalkor()
		"mercenário", "mercenario":
			return battle.pixel_art_renderer.create_enemy("mercenario")
		"guerreiro":
			return battle.pixel_art_renderer.create_enemy("mercenario")
		"caçador", "cacador":
			return battle.pixel_art_renderer.create_enemy("cacador")
		"arqueiro":
			return battle.pixel_art_renderer.create_enemy("cacador")
		"inquisidor":
			return battle.pixel_art_renderer.create_enemy("inquisidor")
		"paladino":
			return battle.pixel_art_renderer.create_enemy("paladino")
		"troll":
			return battle.pixel_art_renderer.create_enemy("troll")
		"lobo_sombrio":
			return battle.pixel_art_renderer.create_enemy("lobo_sombrio")
		"aranha_gigante":
			return battle.pixel_art_renderer.create_enemy("aranha_gigante")
		"esqueleto":
			return battle.pixel_art_renderer.create_enemy("esqueleto")
		"cardeal", "santo_cardeal":
			return battle.pixel_art_renderer.create_enemy("cardeal")
		_:
			# Fallback para sprite procedural se não encontrado
			return _create_fallback_sprite(color, is_player)


## Normaliza nome de unidade → chave de arquivo sprite (minúsculo, sem acento/
## apóstrofo/em-dash, underscores únicos). Ex.: "Aurius — Falso Demiurgo" →
## "aurius_falso_demiurgo", "Arquidemônio" → "arquidemonio".
func sprite_key(unit_name: String) -> String:
	var key := unit_name.to_lower()
	for pair in [["—", ""], ["'", ""], ["á", "a"], ["é", "e"], ["ê", "e"], ["â", "a"], ["ã", "a"], ["õ", "o"], ["ô", "o"], ["í", "i"], ["ú", "u"], ["ç", "c"], [" ", "_"]]:
		key = key.replace(pair[0], pair[1])
	while "__" in key:
		key = key.replace("__", "_")
	return key


## HD 2D: carrega textura png de assets/sprites se existir; null → fallback procedural.
## Pre-check file_exists (P0-6): img.load em arquivo ausente imprime ERROR no
## console para CADA probe (fantasma/teia/guerreiro...) — mascara erros reais.
func load_hd_sprite(path: String) -> Sprite2D:
	var img := Image.new()
	if not FileAccess.file_exists(path):
		return null
	if img.load(path) != OK:
		return null
	var sprite = Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(img)
	return sprite


func _create_fallback_sprite(color: Color, is_player: bool) -> Sprite2D:
	var sprite = Sprite2D.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var base_color = color if is_player else color.darkened(0.3)

	# Desenhar personagem simples mas melhorado
	var center = 32

	# Corpo
	for y in range(center - 10, center + 10):
		for x in range(center - 8, center + 8):
			if x >= 0 && x < 64 && y >= 0 && y < 64:
				var dist = sqrt(pow(x - center, 2) + pow(y - center, 2))
				if dist < 10:
					var shade = 1.0 - dist / 10.0
					if shade > 0.7:
						image.set_pixel(x, y, base_color.lightened(0.3))
					elif shade > 0.4:
						image.set_pixel(x, y, base_color)
					else:
						image.set_pixel(x, y, base_color.darkened(0.3))

	# Olhos
	var eye_color = Color.WHITE if is_player else Color("#FF4444")
	image.set_pixel(center - 4, center - 4, eye_color)
	image.set_pixel(center + 4, center - 4, eye_color)
	image.set_pixel(center - 3, center - 3, Color.BLACK)
	image.set_pixel(center + 3, center - 3, Color.BLACK)

	var texture = ImageTexture.create_from_image(image)
	var sprite_node = Sprite2D.new()
	sprite_node.texture = texture
	sprite_node.scale = Vector2(1.5, 1.5)

	return sprite_node
