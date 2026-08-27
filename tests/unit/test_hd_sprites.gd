extends "res://addons/gut/test.gd"

## Testes GUT para o pipeline HD 2D de sprites (ComfyUI → assets/sprites/*.png)

var fake_battle_scene: Node


func before_each():
	## Sobe uma instância da script battle_scene (Node2D) sem cena completa
	fake_battle_scene = preload("res://scripts/battle/battle_scene.gd").new()
	## pixel_art_renderer real (mesmo padrão do setup_systems); se o HD carregar,
	## ele nem é usado — mas fica disponível para o fallback procedural.
	fake_battle_scene.pixel_art_renderer = preload("res://scripts/visual/pixel_art_renderer.gd").new()


func test_hd_sprite_loaded_uses_texture():
	var png_path = "res://assets/sprites/kael.png"
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	DirAccess.make_dir_recursive_absolute("res://assets/sprites")
	img.save_png(png_path)
	var sprite = fake_battle_scene.create_unit_sprite("Kael", Color.RED, true)
	assert_not_null(sprite.texture, "Sprite deve carregar a textura HD 2D")
	assert_eq(sprite.texture.get_width(), 64, "Textura 64px em vez do fallback procedural")
	DirAccess.remove_absolute(png_path)


## Sem png em assets/sprites → fallback procedural (_create_fallback_sprite, não usa renderer)
func test_hd_sprite_missing_falls_back():
	var sprite = fake_battle_scene.create_unit_sprite("FANTASMA", Color.WHITE, true)
	assert_not_null(sprite, "Fallback procedural ainda existe")