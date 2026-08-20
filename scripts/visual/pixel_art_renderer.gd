class_name PixelArtRenderer
extends Node2D

# Renderer de pixel art estilo Sea of Stars
# - Outlines suaves
# - Sombreamento por dithering
# - Iluminação rim light
# - Profundidade com camadas

var outline_shader: ShaderMaterial
var glow_shader: ShaderMaterial

func _ready() -> void:
 create_shaders()

func create_shaders() -> void:
 # Shader de outline
 outline_shader = ShaderMaterial.new()
 var outline = Shader.new()
 outline.code = """
shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
 vec4 tex_color = texture(TEXTOR, UV);
 vec2 pixel_size = SCREEN_PIXEL_SIZE;

 vec4 outline_sum = vec4(0.0);
 float samples = 0.0;

 for(float x = -1.0; x <= 1.0; x += 1.0) {
  for(float y = -1.0; y <= 1.0; y += 1.0) {
   if(x == 0.0 && y == 0.0) continue;
   vec2 offset = vec2(x, y) * pixel_size * outline_width;
   outline_sum += texture(TEXTOR, UV + offset);
   samples += 1.0;
  }
 }

 outline_sum /= samples;

 if(tex_color.a < 0.1 && outline_sum.a > 0.1) {
  COLOR = outline_color;
 } else {
  COLOR = tex_color;
 }
 }
 """
 outline_shader.shader = outline

 # Shader de glow
 glow_shader = ShaderMaterial.new()
 var glow = Shader.new()
 glow.code = """
shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
 vec4 tex_color = texture(TEXTOR, UV);
 vec3 glow = tex_color.rgb * glow_color.rgb * glow_intensity;
 COLOR = vec4(tex_color.rgb + glow * tex_color.a, tex_color.a);
 }
 """
 glow_shader.shader = glow

func apply_outline(sprite: Sprite2D, width: float = 1.0, color: Color = Color.BLACK) -> void:
 if not sprite:
  return
 var mat = outline_shader.duplicate()
 mat.set_shader_parameter("outline_width", width)
 mat.set_shader_parameter("outline_color", color)
 sprite.material = mat

func apply_glow(sprite: Sprite2D, intensity: float = 0.5, color: Color = Color.WHITE) -> void:
 if not sprite:
  return
 var mat = glow_shader.duplicate()
 mat.set_shader_parameter("glow_intensity", intensity)
 mat.set_shader_parameter("glow_color", color)
 sprite.material = mat

func create_pixel_character(colors: Dictionary, size: int = 32) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

 # Corpo principal
 var body_color = Color(colors.primary)
 var secondary_color = Color(colors.secondary)
 var accent_color = Color(colors.accent)

 # Desenhar corpo (simplificado)
 var center_x = size / 2
 var center_y = size / 2

 # Corpo base
 for y in range(center_y - 8, center_y + 8):
  for x in range(center_x - 6, center_x + 6):
   if x >= 0 and x < size and y >= 0 and y < size:
    image.set_pixel(x, y, body_color)

 # Cabeça
 for y in range(center_y - 12, center_y - 4):
  for x in range(center_x - 4, center_x + 4):
   if x >= 0 and x < size and y >= 0 and y < size:
    image.set_pixel(x, y, body_color)

 # Olhos (brilhantes)
 image.set_pixel(center_x - 2, center_y - 8, accent_color)
 image.set_pixel(center_x + 2, center_y - 8, accent_color)

 # Detalhes secundários
 for y in range(center_y + 4, center_y + 8):
  for x in range(center_x - 4, center_x + 4):
   if x >= 0 and x < size and y >= 0 and y < size:
    image.set_pixel(x, y, secondary_color)

 var texture = ImageTexture.create_from_image(image)
 sprite.texture = texture
 sprite.scale = Vector2(2, 2)

 return sprite

func create_pixel_terrain(terrain_type: String, size: int = 32) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

 match terrain_type:
  "grass":
   var light = Color(SeaOfStarsStyle.palette.grass_light)
   var dark = Color(SeaOfStarsStyle.palette.grass_dark)
   image.fill(light)
   for i in range(50):
    var x = randi() % size
    var y = randi() % size
    image.set_pixel(x, y, dark)
  "stone":
   var light = Color(SeaOfStarsStyle.palette.stone_light)
   var dark = Color(SeaOfStarsStyle.palette.stone_dark)
   image.fill(light)
   for i in range(40):
    var x = randi() % size
    var y = randi() % size
    image.set_pixel(x, y, dark)
  "water":
   var light = Color(SeaOfStarsStyle.palette.water_light)
   var dark = Color(SeaOfStarsStyle.palette.water_dark)
   image.fill(light)
   for i in range(30):
    var x = randi() % size
    var y = randi() % size
    image.set_pixel(x, y, dark)
  _:
   image.fill(Color(0.2, 0.2, 0.2))

 var texture = ImageTexture.create_from_image(image)
 sprite.texture = texture

 return sprite

func add_depth_sorting(units: Array[Node2D]) -> void:
 # Ordenar unidades por posição Y para efeito de profundidade
 units.sort_custom(func(a, b): return a.position.y < b.position.y)
 for i in range(units.size()):
  units[i].z_index = i
