extends SceneTree
const RLib := preload("res://scripts/pixel_art_renderer.gd")
func _init():
	# 1) canvas LoRA do explore
	var sprite: Sprite2D = RLib.build_lora_terrain_canvas("mixed")
	if sprite == null:
		print("DBG canvas LoRA = NULL (fallback procedural ativo!)")
	else:
		var img: Image = sprite.texture.get_image()
		var px: Color = img.get_pixel(160, 90)
		print("DBG lora canvas ok size=", img.get_width(), "x", img.get_height(), " pixel centro=", px)
		img.save_png("res://tools/_dbg_lora_canvas.png")
	# 2) formato do tile PNG
	var tex: Texture2D = load("res://assets/pixel/tile_fronteira.png")
	var timg: Image = tex.get_image()
	print("DBG tile_fronteira format=", timg.get_format(), " size=", timg.get_width(), "x", timg.get_height())
	# 3) piso da arena
	var floor_tex: ImageTexture = RLib.build_lora_floor_texture("fronteira", Rect2(140, 280, 1000, 380), 0.88)
	if floor_tex == null:
		print("DBG floor = NULL")
	else:
		var fimg: Image = floor_tex.get_image()
		print("DBG floor ok ", fimg.get_width(), "x", fimg.get_height(), " pixel=", fimg.get_pixel(500, 190))
		fimg.save_png("res://tools/_dbg_floor.png")
	quit()
