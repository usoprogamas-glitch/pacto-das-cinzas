extends "res://addons/gut/test.gd"
## Testes GUT: UnitAnimator — movimento dos sprites HD
## Bug corrigido: setup() procurava o filho "Sprite2D" pelo nome, mas add_child
## sem nome gera "@Sprite2D@N" → idle/hit/cast/death ficavam null e mortos.

const UnitAnimatorScript := preload("res://scripts/unit_animator.gd")

func _make_unit_with_sprite() -> Node2D:
	# Reproduz create_unit: sprite adicionado SEM nome explícito.
	var unit = Node2D.new()
	var sprite = Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	sprite.scale = Vector2(1.0, 1.0)  # base conhecida p/ asserções
	unit.add_child(sprite)
	return unit

func test_setup_finds_unnamed_sprite_child():
	var unit = _make_unit_with_sprite()
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	assert_not_null(animator.sprite, "sprite encontrado mesmo com nome automático @Sprite2D@N")
	assert_eq(animator.sprite.texture.get_width(), 32)

func test_setup_finds_explicitly_named_sprite():
	var unit = Node2D.new()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = ImageTexture.create_from_image(Image.create(64, 64, false, Image.FORMAT_RGBA8))
	unit.add_child(sprite)
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	assert_not_null(animator.sprite, "nome explícito continua funcionando")

func test_setup_without_sprite_is_null_and_animations_are_null_safe():
	var unit = Node2D.new()
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	assert_null(animator.sprite)
	# Nenhuma das animações pode crashar sem sprite (early return)
	animator.play_idle()
	animator.play_hit()
	animator.play_magic_cast()
	animator.play_evolution()
	await animator.play_death()
	assert_eq(animator.get_current_animation(), "death", "estado avançado mesmo sem sprite")

func test_setup_with_null_unit_is_null_safe():
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(null)
	assert_null(animator.sprite, "unit null → sprite null, sem crash")

func test_idle_bobs_around_base_scale_without_exploding():
	# Regressão: animar para escala ABSOLUTA (1.0/1.02) explodia sprites HD
	# normalizados (scale ~0.03). O bob deve ser relativo à escala base.
	var unit = _make_unit_with_sprite()
	var sprite: Sprite2D = unit.get_children()[0]
	sprite.scale = Vector2(0.03125, 0.03125)  # 1024px → 32px
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	animator.play_idle()
	await get_tree().create_timer(0.7).timeout  # meio ciclo do bob
	assert_lt(sprite.scale.y, 0.03125 * 1.08, "scale.y limitada ao bob de ~6%")
	assert_gt(sprite.scale.y, 0.03125 * 0.98, "scale.y nunca colapsa")

func test_death_fades_sprite_out():
	var unit = _make_unit_with_sprite()
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	await animator.play_death()
	var sprite: Sprite2D = unit.get_children()[0]
	assert_almost_eq(sprite.modulate.a, 0.0, 0.01, "morte: sprite some")

## Direção: virar para o alvo/movimento via flip horizontal.
func test_face_direction_flips_sprite_left():
	var unit = _make_unit_with_sprite()
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	animator.face_direction(-10.0)
	assert_true(animator.sprite.flip_h, "movimento para a esquerda → flip")

func test_face_direction_unflips_sprite_right():
	var unit = _make_unit_with_sprite()
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	animator.sprite.flip_h = true
	animator.face_direction(10.0)
	assert_false(animator.sprite.flip_h, "movimento para a direita → sem flip")

func test_face_direction_zero_delta_keeps_flip():
	var unit = _make_unit_with_sprite()
	add_child_autofree(unit)
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(unit)
	animator.sprite.flip_h = true
	animator.face_direction(0.0)
	assert_true(animator.sprite.flip_h, "delta ~0 não mexe no flip")

func test_face_direction_without_sprite_is_null_safe():
	var animator = UnitAnimatorScript.new()
	add_child_autofree(animator)
	animator.setup(Node2D.new())
	animator.face_direction(-5.0)
	assert_eq(animator.get_current_animation(), "idle", "sem sprite: sem crash")
