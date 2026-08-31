extends "res://addons/gut/test.gd"
## Testes GUT: shaders do PixelArtRenderer compilam (P0-5 da auditoria)
## Antes: 6 shaders com GLSL inválido (hint_range em bool/vec2, divisão de
## array constructor, comentários acentuados) → compilação falhava e outline/
## glow/rim/water/grass/dither ficavam MORTOS silenciosamente.

const PixelArtRendererScript := preload("res://scripts/pixel_art_renderer.gd")

var renderer

func before_each():
	renderer = PixelArtRendererScript.new()
	renderer.create_shaders()

func after_each():
	if is_instance_valid(renderer):
		renderer.free()

## Um ShaderMaterial só é utilizável se .shader != null E o código compilou.
## Godot expõe Shader.get_rid + compiled state indireto: aqui validamos que o
## material existe e que o código não tem as classes de erro conhecidas.
func _assert_shader_ok(material: ShaderMaterial, shader_name: String) -> void:
	assert_not_null(material, shader_name + ": ShaderMaterial criado")
	assert_not_null(material.shader, shader_name + ": Shader != null")
	var code: String = material.shader.code
	# Classes de erro que quebravam os shaders (regressão):
	assert_false(code.contains(": hint_range(0, 1) = true"), shader_name + ": sem hint_range em bool")
	assert_false(code.contains(") / 16.0;"), shader_name + ": sem divisão de array constructor")
	assert_false(code.to_utf8_buffer().size() != code.length(), shader_name + ": código 100% ASCII")

func test_outline_shader_valid():
	_assert_shader_ok(renderer.outline_shader, "outline")

func test_glow_shader_valid():
	_assert_shader_ok(renderer.glow_shader, "glow")

func test_water_shader_valid():
	_assert_shader_ok(renderer.water_shader, "water")

func test_grass_shader_valid():
	_assert_shader_ok(renderer.grass_shader, "grass")

func test_rim_light_shader_valid():
	_assert_shader_ok(renderer.rim_light_shader, "rim_light")

func test_dither_shader_valid():
	_assert_shader_ok(renderer.dither_shader, "dither")

## Guarda-chuva: TODOS os 6 materiais construídos de uma vez.
func test_all_shaders_created():
	for material in [renderer.outline_shader, renderer.glow_shader, renderer.water_shader,
			renderer.grass_shader, renderer.rim_light_shader, renderer.dither_shader]:
		assert_not_null(material, "material criado")
		assert_not_null(material.shader, "shader atribuído")

## O dither corrigido indexa a matriz por int: validar o shape do código.
func test_dither_uses_raw_array_and_int_index():
	var code: String = renderer.dither_shader.shader.code
	assert_true(code.contains("float bayer_raw[16]"), "matriz renomeada (sem divisão no constructor)")
	assert_true(code.contains("bayer_raw[int(y) * 4 + int(x)] / 16.0"), "índice int + divisão por elemento")
