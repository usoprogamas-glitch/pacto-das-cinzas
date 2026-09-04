extends "res://addons/gut/test.gd"

## Sprites com movimento (SpriteMotionLibrary): ciclos multi-frame gerados em
## runtime a partir do PNG estático (bandas horizontais cutout) e ciclado pelo
## UnitAnimator — walk durante movimento/chase, idle parado.

const ExploreScript := preload("res://scripts/explore_scene.gd")
const MotionLib := preload("res://scripts/sprite_motion_library.gd")

var _explore: Node


func before_each() -> void:
	GameManager.campaign_system.reset()
	GameManager.game_data["current_map"] = 0
	GameManager.game_data["starting_ally"] = "kroug"


func after_each() -> void:
	if _explore and is_instance_valid(_explore):
		_explore.free()
	_explore = null


func _open() -> Node:
	_explore = add_child_autofree(ExploreScript.new())
	return _explore


func test_walk_cycle_generates_4_frames_different_from_base():
	var img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(200, 900):
		for x in range(400, 600):
			img.set_pixel(x, y, Color.RED)
	var sets := MotionLib.build_motion_sets(img)
	assert_eq(sets["walk"].size(), 4, "ciclo de passada tem 4 frames")
	assert_eq(sets["idle"].size(), 2, "idle tem 2 frames (respiração)")
	var base256: Texture2D = sets["walk"][0]
	assert_eq(base256.get_width(), 256, "frames gerados a 256px (downscale de memória)")
	# Frames do ciclo são distintos entre si (movimento real, não estático).
	var f0: Image = sets["walk"][0].get_image()
	var f2: Image = sets["walk"][2].get_image()
	var diff := 0
	for y in range(0, 256, 4):
		for x in range(0, 256, 4):
			if f0.get_pixel(x, y) != f2.get_pixel(x, y):
				diff += 1
	assert_gt(diff, 0, "frame 0 e frame 2 diferem (passada animada)")


func test_frames_keep_silhouette_reasonably_aligned():
	# O deslocamento máximo é pequeno: o corpo não "derrete" entre frames.
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(64, 224):
		for x in range(96, 160):
			img.set_pixel(x, y, Color.BLUE)
	var frames := []
	for i in range(4):
		frames.append(MotionLib._shifted_frame(img, TAU * float(i) / 4.0, 5.0, 2.0))
	for f in frames:
		var opaque := 0
		for y in range(0, 256, 2):
			for x in range(0, 256, 2):
				if f.get_pixel(x, y).a > 0.5:
					opaque += 1
		assert_gt(opaque, 100, "silhueta preservada em cada frame")


func test_explore_attaches_animator_with_frames_to_party_and_enemies():
	var scene := _open()
	assert_not_null(scene.player_animator, "Kael tem animator com ciclos")
	assert_gt(scene.player_animator.walk_frames.size(), 0, "Kael tem frames de passada")
	assert_gt(scene.player_animator.idle_frames.size(), 0, "Kael tem frames de idle")
	# Kroug agora usa sprites SoS (Garl) com walk cycle por direção.
	if scene.buddy_sos_char != "":
		assert_not_null(scene._buddy_sos_sets["walk"], "Kroug-SoS tem walk frames")
		assert_not_null(scene._buddy_sos_sprite, "Kroug-SoS tem sprite")
	else:
		assert_not_null(scene._buddy_animator, "Kroug tem animator com ciclos")
	assert_eq(scene._enemy_animators.size(), scene.enemy_nodes.size(), "cada inimigo tem animator")


func test_animator_cycles_texture_over_time():
	var scene := _open()
	if scene.player_sos_char != "":
		# Sprites SoS: idle é 1 frame estático (autêntico); walk tem 6 frames.
		# Ticka o walk cycle manualmente e valida que a textura muda.
		var spr: Sprite2D = scene._player_sos_sprite
		var frame0: Texture2D = spr.texture
		var changed := false
		for i in range(10):
			scene._player_sos_frame += 0.5  # ~4 frames a 8 FPS
			scene._tick_sos_sprite(spr, scene._player_sos_sets, 1, true, 0.0, scene._player_sos_frame)
			if spr.texture != frame0:
				changed = true
				break
		assert_true(changed, "walk cycle SoS troca frame ao tickar")
		return
	var anim = scene.player_animator
	var frame0: Texture2D = anim.sprite.texture
	await get_tree().create_timer(0.35).timeout  # idle fps 4 → ~1.4 frames
	var frame_later: Texture2D = anim.sprite.texture
	assert_ne(frame_later, frame0, "textura troca com o tempo (ciclo vivo)")


func test_set_moving_switches_between_walk_and_idle_sets():
	var scene := _open()
	var anim = scene.player_animator
	anim.set_moving(true)
	assert_eq(anim.sprite.texture, anim.walk_frames[0], "movendo → frame 0 da passada")
	anim.set_moving(false)
	assert_eq(anim.sprite.texture, anim.idle_frames[0], "parado → frame 0 do idle")


func test_animator_without_frames_keeps_tween_fallback():
	# Sem frames (fallback procedural), play_idle continua usando o bob por tween.
	var unit := Node2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	sprite.scale = Vector2(0.03, 0.03)
	unit.add_child(sprite)
	add_child_autofree(unit)
	var animator := UnitAnimator.new()
	add_child_autofree(animator)
	animator.setup(unit)
	animator.set_frames({})
	animator.play_idle()
	await get_tree().create_timer(0.35).timeout
	assert_almost_eq(sprite.scale.x, 0.03, 0.01, "fallback: bob relativo à escala base, sem explosão")
