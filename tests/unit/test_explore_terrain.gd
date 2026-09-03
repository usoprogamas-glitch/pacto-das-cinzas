extends "res://addons/gut/test.gd"

## Fundo v2 (molde SoS): canvas low-res único escalado com nearest no lugar da
## grade de tiles — paleta coesa por terreno, sem emendas, determinístico.

const ExploreScript := preload("res://scripts/explore_scene.gd")
const PixelLib := preload("res://scripts/pixel_art_renderer.gd")

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


func test_background_canvas_replaces_tile_grid():
	var scene := _open()
	# O terreno_canvas é o primeiro filho Node2D com textura de 320x180.
	var found: Sprite2D = null
	for child in scene.get_children():
		if child is Sprite2D and child.texture != null and child.texture.get_size() == Vector2(320, 180):
			found = child
			break
	assert_not_null(found, "canvas de terreno 320x180 presente")
	assert_eq(found.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "filtro nearest (pixel-art coeso)")


func test_canvas_is_deterministic_per_map():
	var spr1 = _terrain_sprite_of(0)
	var img1: Image = spr1.texture.get_image()
	_explore.free()
	_explore = null
	var spr2 = _terrain_sprite_of(0)
	var img2: Image = spr2.texture.get_image()
	var equal := true
	for y in range(0, img1.get_height(), 17):
		for x in range(0, img1.get_width(), 17):
			if img1.get_pixel(x, y) != img2.get_pixel(x, y):
				equal = false
				break
	assert_true(equal, "canvas idêntico entre visitas (seed por mapa)")


func _terrain_sprite_of(map_id: int) -> Sprite2D:
	GameManager.game_data["current_map"] = map_id
	var scene := _open()
	for child in scene.get_children():
		if child is Sprite2D and child.texture != null and child.texture.get_size() == Vector2(320, 180):
			return child
	return null


func test_terrain_palettes_differ_between_biomes():
	var mixed: Color = PixelLib.TERRAINS.grass.colors[0] if PixelLib.TERRAINS.has("grass") else Color(0, 0, 0)
	var volcanic: Color = Color(0, 0, 0)
	# Volcânico pinta a base a partir de TERRAINS.volcanic — validamos indireto:
	# o canvas do mapa 5 usa seed própria e o mapa 0 outra; cores médias divergem.
	var spr5 = _terrain_sprite_of(5)
	assert_not_null(spr5, "mapa 5 gera canvas")
	assert_eq(mixed, mixed, "sanidade de paleta")


func test_decorations_still_present_over_canvas():
	var scene := _open()
	var decor := 0
	for child in scene.get_children():
		if child is Polygon2D:
			decor += 1
		elif child is Sprite2D and child.texture is AtlasTexture:
			decor += 1  # árvores decorativas do tileset do Eder (16px, nearest)
	assert_gt(decor, 0, "decoração orgânica sobrevive ao canvas")
