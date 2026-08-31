extends "res://addons/gut/test.gd"
## Testes GUT: normalização de tamanho dos sprites (GDD §10.1 — célula 32px)
## Sprites HD (1024px) e procedurais (64-128px) devem sair de create_unit()
## com tamanho visual = BattleGrid.TILE_SIZE (32px).

const BattleSceneScript := preload("res://scripts/battle/battle_scene.gd")

var fake_battle_scene: Node

func before_each():
	fake_battle_scene = preload("res://scripts/battle/battle_scene.gd").new()
	fake_battle_scene.pixel_art_renderer = preload("res://scripts/visual/pixel_art_renderer.gd").new()
	# NOTA: sem árvore, o _ready do renderer não roda → ShaderMaterials null →
	# o caminho procedural imprime 2 SCRIPT ERRORs benignos de duplicate(null).
	# NÃO chamar create_shaders() aqui: os shaders do renderer têm erros de
	# compilação pré-existentes (hints inválidos/caracteres no GLSL) e poluem
	# o log em massa. Bug do renderer, fora do escopo deste teste.

func _effective_size(sprite: Sprite2D) -> float:
	return sprite.texture.get_width() * sprite.scale.x

## Sprite HD 1024px (tamanho real dos pngs em assets/sprites) → 32px.
func test_hd_sprite_1024_normalized_to_tile():
	var png_path = "res://assets/sprites/zz_scale_test.png"
	var img = Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLUE)
	DirAccess.make_dir_recursive_absolute("res://assets/sprites")
	img.save_png(png_path)
	var sprite = fake_battle_scene.create_unit_sprite("Zz Scale Test", Color.BLUE, true)
	assert_not_null(sprite.texture, "HD carregado")
	assert_almost_eq(_effective_size(sprite), BattleGrid.TILE_SIZE, 0.01,
		"sprite HD 1024px normalizado para 32px")
	DirAccess.remove_absolute(png_path)

## Fallback procedural (64px, scale 1.5 → 96px) → 32px.
func test_fallback_sprite_normalized_to_tile():
	var sprite = fake_battle_scene.create_unit_sprite("FANTASMA", Color.WHITE, true)
	assert_almost_eq(_effective_size(sprite), BattleGrid.TILE_SIZE, 0.01,
		"fallback procedural 96px normalizado para 32px")

## Caminho do PixelArtRenderer (64px, scale 2 → 128px) → 32px.
func test_procedural_renderer_sprite_normalized_to_tile():
	# "Guerreiro" não tem png em assets/sprites → match procedural do renderer.
	var sprite = fake_battle_scene.create_unit_sprite("Guerreiro", Color.RED, false)
	assert_not_null(sprite.texture)
	assert_almost_eq(_effective_size(sprite), BattleGrid.TILE_SIZE, 0.01,
		"sprite procedural 128px normalizado para 32px")

## Bordas: sprite sem textura não deve crashar a normalização.
func test_normalize_handles_null_texture():
	var sprite = Sprite2D.new()
	fake_battle_scene._normalize_sprite_to_tile(sprite)
	assert_null(sprite.texture, "sem textura: nada a fazer, sem crash")
	sprite.free()

## Proporção não quadrada (se um png futuro vier 1024x512): largura ≈ 32.
func test_normalize_uses_width_as_reference():
	var png_path = "res://assets/sprites/zz_wide_test.png"
	var img = Image.create(1024, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color.GREEN)
	DirAccess.make_dir_recursive_absolute("res://assets/sprites")
	img.save_png(png_path)
	var sprite = fake_battle_scene.create_unit_sprite("Zz Wide Test", Color.GREEN, true)
	assert_almost_eq(_effective_size(sprite), BattleGrid.TILE_SIZE, 0.01,
		"largura não quadrada normalizada para 32px")
	DirAccess.remove_absolute(png_path)
