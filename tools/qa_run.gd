extends SceneTree

## QA visual automatizado: roda as cenas do jogo com renderização real,
## força interações e salva screenshots para revisão humana/IA.
## Rodar: godot --path . -s tools/qa_run.gd (SEM --headless)

const SHOT_DIR := "res://tools/qa_shots"
var _shots := 0


func gm() -> Node:
	return root.get_node("/root/GameManager")


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	# 1) Intro (cena principal do projeto)
	var intro = load("res://scenes/intro_story.tscn").instantiate()
	root.add_child(intro)
	await _wait(2.0)
	await _shot("01_intro")
	intro.free()

	# 2) Main menu
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await _wait(1.5)
	await _shot("02_main_menu")
	menu.free()

	# 3) Settings
	var settings = load("res://scenes/settings.tscn").instantiate()
	root.add_child(settings)
	await _wait(0.5)
	await _shot("03_settings")
	settings.free()

	# 4) Explore (novo jogo) + HUD + props
	gm().start_new_game()
	gm().sync_current_map_from_campaign()
	var explore = load("res://scenes/explore_scene.tscn").instantiate()
	root.add_child(explore)
	await _wait(2.0)
	await _shot("04_explore_mapa0")

	# 4b) Mover até um inimigo (contato abre a arena)
	if explore.enemy_nodes.size() > 0:
		explore.player.position = explore.enemy_nodes[0].position + Vector2(30, 0)
		await _wait(2.5)  # entrada da arena + menu
		await _shot("05_arena_batalha")

		# 5) Timed hit resolution + result screen
		if explore.arena != null:
			explore.arena.combat_frozen = true
			explore.arena._finish(true)
			await _wait(0.8)
			await _shot("06_result_screen")
			explore.arena._on_result_continue_pressed()
			await _wait(0.5)
			await _shot("07_explore_pos_vitoria")

	# 6) Ativar asas + mapa 5 (Ignis) com boss bar
	gm().game_data["has_wings"] = true
	gm().campaign_system.current_act = 2
	gm().campaign_system.current_stage = 0
	gm().sync_current_map_from_campaign()
	var explore2 = load("res://scenes/explore_scene.tscn").instantiate()
	root.add_child(explore2)
	await _wait(2.0)
	await _shot("08_explore_mapa5_ignis")
	if explore2.enemy_nodes.size() > 0:
		explore2.player.position = explore2.enemy_nodes[0].position + Vector2(30, 0)
		await _wait(3.0)
		await _shot("09_arena_boss_bar")
	explore2.queue_free()
	await _wait(0.3)

	# 7) Cutscene de ato (Ato II)
	gm().campaign_system.current_act = 2
	gm().campaign_system.act_intro_pending = true
	var cutscene = load("res://scenes/act_cutscene.tscn").instantiate()
	root.add_child(cutscene)
	await _wait(0.5)
	await _shot("10_act_cutscene")
	cutscene.free()

	# 8) Epílogo
	gm().campaign_system.game_completed = true
	var epilogue = load("res://scenes/epilogue.tscn").instantiate()
	root.add_child(epilogue)
	await _wait(0.5)
	await _shot("11_epilogue")
	epilogue.free()

	print("QA_RUN_OK: %d screenshots em %s" % [_shots, SHOT_DIR])
	quit()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	if img == null:
		print("SHOT FAIL (null): ", name)
		return
	var path := "%s/%02d_%s.png" % [SHOT_DIR, _shots + 1, name]
	img.save_png(path)
	_shots += 1
	print("SHOT: ", path)
