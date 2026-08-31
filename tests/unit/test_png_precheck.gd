extends "res://addons/gut/test.gd"
## Testes GUT: pre-check de png no _load_hd_sprite (P0-6 da auditoria)
## img.load em arquivo ausente imprime ERROR no console para cada probe de nome
## sem png (fantasma, teia, guerreiro...) — o pre-check elimina o spam.

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var bs: Node

func before_each():
	bs = BattleSceneScript.new()
	bs.setup_systems()

func after_each():
	if is_instance_valid(bs):
		bs.free()

func test_missing_png_returns_null_without_error_path():
	assert_null(bs._load_hd_sprite("res://assets/sprites/zz_definitely_missing.png"),
		"png ausente → null (fallback procedural assume)")

func test_existing_png_still_loads():
	# Kael tem png real — path feliz continua funcionando pós-guard.
	var sprite = bs._load_hd_sprite("res://assets/sprites/kael.png")
	assert_not_null(sprite, "png existente carrega")
	assert_eq(sprite.texture.get_width(), 1024)

func test_directory_path_is_not_a_sprite():
	# FileAccess.file_exists em diretório retorna false → guard segura.
	assert_null(bs._load_hd_sprite("res://assets/sprites"))
