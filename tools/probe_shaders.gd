extends SceneTree
## Probe P0-5: valida que os 6 shaders do PixelArtRenderer compilam de verdade.
## Headless NAO compila shader (RasterizerDummy) - rodar com renderer real:
##   Godot_v4.3-stable_win64_console.exe --path . --rendering-driver opengl3 -s tools/probe_shaders.gd
## Criterio de sucesso: 6x "PROBE OK" e nenhuma linha "SHADER ERROR" no stderr.

var frames := 0
var started := false

func _initialize() -> void:
	var script := load("res://scripts/pixel_art_renderer.gd")
	var renderer: Node2D = script.new()
	renderer.create_shaders()
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.2, 0.2, 1.0))
	var tex := ImageTexture.create_from_image(img)
	var shader_names := ["outline_shader", "glow_shader", "water_shader", "grass_shader", "rim_light_shader", "dither_shader"]
	for i in shader_names.size():
		var material: ShaderMaterial = renderer.get(shader_names[i])
		if material == null or material.shader == null:
			print("PROBE FAIL ", shader_names[i], ": material/shader null")
			quit(1)
			return
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.position = Vector2(32 + i * 40, 40)
		sprite.material = material
		root.add_child(sprite)
	print("PROBE STAGED 6 shaders em 6 sprites")
	started = true

func _process(_delta: float) -> bool:
	if not started:
		return false
	frames += 1
	if frames == 5:
		print("PROBE OK 6 shaders desenhados por 5 frames sem erro de compilacao")
		quit(0)
	return false
