class_name PixelArtRenderer
extends Node2D

# Renderer de pixel art estilo Sea of Stars (QUALIDADE ALTA)
# - Sprites detalhados com sombreamento
# - Tiles com transições suaves
# - Shaders avançados (outline, glow, rim light, water, grass)
# - Partículas avançadas
# - Paletas Sea of Stars autênticas

var outline_shader: ShaderMaterial
var glow_shader: ShaderMaterial
var water_shader: ShaderMaterial
var grass_shader: ShaderMaterial
var rim_light_shader: ShaderMaterial
var dither_shader: ShaderMaterial

func _ready() -> void:
 create_shaders()

func create_shaders() -> void:
 # === OUTLINE SHADER (melhorado) ===
 outline_shader = ShaderMaterial.new()
 var outline = Shader.new()
 outline.code = """
shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 4.0) = 1.5;
uniform vec4 outline_color : source_color = vec4(0.05, 0.05, 0.1, 1.0);
uniform bool use_dither : hint_range(0, 1) = true;

void fragment() {
 vec4 tex_color = texture(TEXTURE, UV);
 vec2 pixel_size = SCREEN_PIXEL_SIZE;
 
 vec4 outline_sum = vec4(0.0);
 float samples = 0.0;
 
 for(float x = -1.0; x <= 1.0; x += 1.0) {
  for(float y = -1.0; y <= 1.0; y += 1.0) {
   if(x == 0.0 && y == 0.0) continue;
   vec2 offset = vec2(x, y) * pixel_size * outline_width;
   outline_sum += texture(TEXTURE, UV + offset);
   samples += 1.0;
  }
 }
 
 outline_sum /= samples;
 
 // Dithering para transição suave
 float alpha_threshold = 0.15;
 if(use_dither) {
  vec2 dither_uv = UV * 100.0;
  float dither = fract(sin(dot(dither_uv, vec2(12.9898, 78.233))) * 43758.5453);
  alpha_threshold += dither * 0.1;
 }
 
 if(tex_color.a < alpha_threshold && outline_sum.a > 0.1) {
  COLOR = outline_color;
 } else {
  COLOR = tex_color;
 }
 }
 """
 outline_shader.shader = outline

 # === GLOW SHADER (melhorado com pulsação) ===
 glow_shader = ShaderMaterial.new()
 var glow = Shader.new()
 glow.code = """
shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 3.0) = 0.8;
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform bool pulse : hint_range(0, 1) = true;

void fragment() {
 vec4 tex_color = texture(TEXTURE, UV);
 
 float pulse_factor = 1.0;
 if(pulse) {
  pulse_factor = 1.0 + sin(TIME * pulse_speed) * 0.3;
 }
 
 vec3 glow = tex_color.rgb * glow_color.rgb * glow_intensity * pulse_factor;
 COLOR = vec4(tex_color.rgb + glow * tex_color.a, tex_color.a);
 }
 """
 glow_shader.shader = glow

 # === WATER SHADER (animado, reflexos) ===
 water_shader = ShaderMaterial.new()
 var water = Shader.new()
 water.code = """
shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_height : hint_range(0.0, 10.0) = 2.0;
uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.35, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.15, 0.35, 0.55, 1.0);
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 0.8);

void fragment() {
 vec2 uv = UV;
 
 // Ondas animadas
 float wave1 = sin(uv.x * 20.0 + time * wave_speed) * wave_height * 0.5;
 float wave2 = sin(uv.y * 15.0 - time * wave_speed * 0.7) * wave_height * 0.3;
 float wave3 = sin((uv.x + uv.y) * 10.0 + time * wave_speed * 1.3) * wave_height * 0.2;
 
 float wave = wave1 + wave2 + wave3;
 
 // Profundidade baseada na posição Y + ondas
 float depth = uv.y + wave * 0.02;
 
 // Interpolação entre cor profunda e rasa
 vec3 color = mix(deep_color.rgb, shallow_color.rgb, smoothstep(0.3, 0.8, depth));
 
 // Espuma nas cristas das ondas
 float foam = smoothstep(0.85, 1.0, sin(uv.x * 30.0 + time * 3.0) * 0.5 + 0.5);
 foam *= smoothstep(0.7, 1.0, depth);
 
 vec3 final_color = color + foam_color.rgb * foam;
 
 // Reflexo sutil
 float reflection = smoothstep(0.1, 0.3, depth) * sin(uv.x * 50.0 + time * 2.0) * 0.1;
 final_color += vec3(reflection);
 
 COLOR = vec4(final_color, 1.0);
 }
 """
 water_shader.shader = water

 # === GRASS SHADER (ondulante) ===
 grass_shader = ShaderMaterial.new()
 var grass = Shader.new()
 grass.code = """
shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float wind_speed : hint_range(0.1, 3.0) = 0.8;
uniform float wind_strength : hint_range(0.0, 5.0) = 1.5;
uniform vec4 grass_light : source_color = vec4(0.35, 0.55, 0.25, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.2, 0.35, 0.15, 1.0);

void fragment() {
 vec2 uv = UV;
 
 // Vento nas gramas
 float wind = sin(uv.x * 25.0 + time * wind_speed * 2.0) * wind_strength * 0.02;
 wind += sin(uv.y * 15.0 - time * wind_speed * 1.5) * wind_strength * 0.01;
 
 uv.x += wind;
 
 // Textura de grama procedural
 float grass_pattern = 0.0;
 for(int i = 0; i < 5; i++) {
  float freq = float(i + 1) * 20.0;
  grass_pattern += sin(uv.x * freq + time) * sin(uv.y * freq * 1.3) * (1.0 / float(i + 1));
 }
 grass_pattern *= 0.15;
 
 // Cor base com variação
 vec3 color = mix(grass_dark.rgb, grass_light.rgb, smoothstep(0.3, 0.7, uv.y + grass_pattern));
 
 // Highlights nas pontas
 float highlight = smoothstep(0.85, 1.0, uv.y + grass_pattern * 0.5);
 color += vec3(0.15, 0.2, 0.1) * highlight;
 
 COLOR = vec4(color, 1.0);
 }
 """
 grass_shader.shader = grass

 # === RIM LIGHT SHADER (iluminação de contorno) ===
 rim_light_shader = ShaderMaterial.new()
 var rim = Shader.new()
 rim.code = """
shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform float rim_width : hint_range(0.0, 2.0) = 0.5;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.8;
uniform vec2 light_direction : hint_range(-1.0, 1.0) = vec2(0.5, -0.5);

void fragment() {
 vec4 tex_color = texture(TEXTURE, UV);
 
 if(tex_color.a < 0.01) discard;
 
 // Calcular normal aproximada baseada na transparência
 vec2 pixel_size = SCREEN_PIXEL_SIZE;
 float alpha_center = tex_color.a;
 float alpha_left = texture(TEXTURE, UV - vec2(pixel_size.x, 0.0)).a;
 float alpha_right = texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a;
 float alpha_up = texture(TEXTURE, UV - vec2(0.0, pixel_size.y)).a;
 float alpha_down = texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a;
 
 vec2 normal = normalize(vec2(alpha_left - alpha_right, alpha_up - alpha_down));
 
 // Produto escalar com direção da luz
 float rim = max(0.0, dot(normal, normalize(light_direction)));
 rim = pow(rim, 2.0) * rim_intensity;
 
 // Aplicar rim light apenas nas bordas
 float edge = step(0.1, tex_color.a) * step(0.99, tex_color.a);
 rim *= (1.0 - edge) * 2.0;
 
 COLOR = vec4(tex_color.rgb + rim_color.rgb * rim * tex_color.a, tex_color.a);
 }
 """
 rim_light_shader.shader = rim

 # === DITHER SHADER (transições suaves estilo retro) ===
 dither_shader = ShaderMaterial.new()
 var dither = Shader.new()
 dither.code = """
shader_type canvas_item;

uniform float dither_amount : hint_range(0.0, 1.0) = 0.3;
uniform vec2 dither_scale : hint_range(1.0, 100.0) = vec2(50.0, 50.0);

void fragment() {
 vec4 tex_color = texture(TEXTURE, UV);
 
 // Bayer dithering 4x4
 vec2 dither_uv = UV * dither_scale;
 float dither_pattern = 0.0;
 
 // Matriz de Bayer 4x4
 float bayer[16] = float[16](
  0.0, 8.0, 2.0, 10.0,
  12.0, 4.0, 14.0, 6.0,
  3.0, 11.0, 1.0, 9.0,
  15.0, 7.0, 13.0, 5.0
 ) / 16.0;
 
 int x = int(mod(floor(UV.x * dither_scale.x), 4.0));
 int y = int(mod(floor(UV.y * dither_scale.y), 4.0));
 float bayer_val = bayer[y * 4 + x];
 
 float threshold = bayer_val + dither_amount * 0.5;
 
 // Aplicar dithering na transparência
 float alpha = tex_color.a;
 alpha = mix(alpha, step(threshold, alpha), dither_amount);
 
 COLOR = vec4(tex_color.rgb, alpha);
 }
 """
 dither_shader.shader = dither

# === PALETAS SEA OF STARS AUTÊNTICAS ===
static var PALETTES: Dictionary = {
 "kael_imp": {
  "skin_dark": "#3D2B1F",
  "skin_mid": "#5D3A2E",
  "skin_light": "#8B5E3C",
  "eyes": "#00FF88",
  "horns": "#1A1A1A",
  "shadow": "#0D0D0D",
  "highlight": "#A0E8C0"
 },
 "kael_noble": {
  "skin_dark": "#2D2D3A",
  "skin_mid": "#3D3D5A",
  "skin_light": "#5D5D7A",
  "runes": "#00BFFF",
  "eyes": "#40E0D0",
  "horns": "#1A1A2E",
  "wings": "#1A1A3E",
  "accent": "#FFD93D"
 },
 "kael_arch": {
  "skin_dark": "#1A0A1A",
  "skin_mid": "#2A1A2A",
  "skin_light": "#4A2A4A",
  "runes": "#FF4444",
  "eyes": "#FF8800",
  "wings": "#0A0A1A",
  "aura": "#FF4444"
 },
 "kael_avatar": {
  "skin_dark": "#2D2020",
  "skin_mid": "#4D3530",
  "skin_light": "#8D6555",
  "eyes": "#FFD700",
  "horns": "#FFD700",
  "wings": "#FFF8E7",
  "aura": "#FFD700"
 },
 "kroug": {
  "skin_dark": "#3A4A2A",
  "skin_mid": "#5A6B3C",
  "skin_light": "#7A8B4C",
  "armor_dark": "#4A3A2A",
  "armor_mid": "#8B7355",
  "armor_light": "#CDAA7D",
  "fire": "#FF4500",
  "eyes": "#FF4444"
 },
 "lira": {
  "bark_dark": "#2D3A1A",
  "bark_mid": "#4A5A2A",
  "bark_light": "#6A7A3A",
  "leaves_dark": "#1E5A2E",
  "leaves_mid": "#2E8B57",
  "leaves_light": "#90EE90",
  "glow": "#98FF98",
  "flowers": "#FF69B4"
 },
 "thalkor": {
  "feathers_dark": "#1C1C2E",
  "feathers_mid": "#2C2C4E",
  "feathers_light": "#3C3C6E",
  "corruption": "#8B008B",
  "halo": "#FFD700",
  "eyes": "#8B008B",
  "shadow": "#0A0A0A"
 },
 "enemy_mercenary": {
  "armor_dark": "#4A2A1A",
  "armor_mid": "#8B4513",
  "armor_light": "#CD853F",
  "skin": "#D4A574",
  "eyes": "#FFFFFF"
 },
 "enemy_paladin": {
  "gold_dark": "#B8860B",
  "gold_mid": "#DAA520",
  "gold_light": "#FFD700",
  "white_dark": "#D0D0D0",
  "white_mid": "#F0F0F0",
  "white_light": "#FFFFFF",
  "light": "#FFFFAA",
  "eyes": "#444444"
 },
 "enemy_inquisitor": {
  "robe_dark": "#1A1A2E",
  "robe_mid": "#2A2A4A",
  "robe_light": "#3A3A6A",
  "chains": "#4A4A5A",
  "magic": "#9370DB",
  "eyes": "#9370DB"
 }
}

# === TERRENOS DETALHADOS ===
static var TERRAINS: Dictionary = {
 "grass": {
  "colors": ["#2D4A1A", "#3D5A2A", "#4D6A3A", "#5D7A4A"],
  "flowers": ["#FF69B4", "#FFD700", "#FF6347", "#FFFFFF"],
  "rocks": ["#3A3A3A", "#4A4A4A", "#5A5A5A"]
 },
 "stone": {
  "colors": ["#3A3A4A", "#4A4A5A", "#5A5A6A", "#6A6A7A"],
  "moss": ["#2A4A2A", "#3A5A3A"],
  "cracks": ["#1A1A1A", "#2A2A2A"]
 },
 "water": {
  "deep": "#0A1A3A",
  "mid": "#1A2A5A",
  "shallow": "#2A4A7A",
  "foam": "#E0F0FF",
  "reflection": "#4A8FD0"
 },
 "lava": {
  "colors": ["#8B0000", "#CC3300", "#FF4500", "#FF6600", "#FF8800"],
  "glow": "#FF4500",
  "smoke": "#3A3A3A",
  "ash": "#2A2A2A"
 },
 "castle": {
  "stone_dark": "#3A3A4A",
  "stone_mid": "#5A5A6A",
  "stone_light": "#7A7A8A",
  "gold": "#DAA520",
  "flags": "#CC3333",
  "windows": "#FFF8DC"
 },
 "cave": {
  "wall_dark": "#1A1A1A",
  "wall_mid": "#2A2A2A",
  "wall_light": "#3A3A3A",
  "crystals": ["#00FFFF", "#FF00FF", "#FFFF00", "#00FF00"],
  "glow": "#4444FF"
 },
 "forest": {
  "ground": "#2D3A1A",
  "grass": "#3D5A2A",
  "leaves": ["#2E8B57", "#3CB371", "#556B2F", "#6B8E23"],
  "trunks": ["#4A3A2A", "#5A4A3A", "#6A5A4A"],
  "canopy": "#1A3A1A"
 }
}

func _ready() -> void:
 create_shaders()

# === FUNÇÕES DE CRIAÇÃO AVANÇADAS ===

func create_detailed_character(char_type: String, size: int = 64) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
 image.fill(Color(0, 0, 0, 0))
 
 var palette = PALETTES.get(char_type, PALETTES.kael_imp)
 
 _draw_detailed_character(image, palette, size)
 
 var texture = ImageTexture.create_from_image(image)
 var sprite_node = Sprite2D.new()
 sprite_node.texture = texture
 sprite_node.scale = Vector2(2, 2)
 
 # Aplicar shaders
 apply_outline(sprite_node, 1.5, Color(0.05, 0.05, 0.1))
 apply_rim_light(sprite_node)
 
 return sprite_node

func _draw_detailed_character(image: Image, palette: Dictionary, size: int) -> void:
 var center_x = size / 2
 var center_y = size / 2
 
 # Cores da paleta
 var skin_dark = Color(palette.get("skin_dark", "#3D2B1F"))
 var skin_mid = Color(palette.get("skin_mid", "#5D3A2E"))
 var skin_light = Color(palette.get("skin_light", "#8B5E3C"))
 var accent = Color(palette.get("eyes", "#00FF88"))
 var shadow = Color(palette.get("shadow", "#0D0D0D"))
 var highlight = Color(palette.get("highlight", "#FFFFFF"))
 
 var cx = size / 2
 var cy = size / 2
 var scale = size / 32.0
 
 # === CORPO PRINCIPAL ===
 # Torso
 _draw_ellipse(image, cx, cy + 4, int(8 * size/32), int(10 * size/32), 
   [skin_dark, skin_mid, skin_light], true)
 
 # Cabeça
 _draw_ellipse(image, cx, cy - 10, int(8 * size/32), int(8 * size/32),
   [skin_dark, skin_mid, skin_light], false)
 
 # Olhos
 var eye_color = Color(PALETTES.get("kael_imp", {}).get("eyes", "#00FF88"))
 _draw_pixel(image, cx - 3, cy - 12, accent)
 _draw_pixel(image, cx + 1, cy - 12, accent)
 _draw_pixel(image, cx - 3, cy - 11, Color(1,1,1,0.3))
 _draw_pixel(image, cx + 1, cy - 11, Color(1,1,1,0.3))
 
 # Chifres (se tiver)
 if PALETTES.get("kael_imp", {}).has("horns"):
  var horn_color = Color(PALETTES["kael_imp"]["horns"])
  _draw_triangle(image, cx - 6, cy - 16, cx - 4, cy - 22, cx - 2, cy - 16, Color(PALETTES["kael_imp"]["horns"]))
  _draw_triangle(image, cx + 2, cy - 16, cx + 4, cy - 22, cx + 6, cy - 16, Color(PALETTES["kael_imp"]["horns"]))
 
 # Braços
 _draw_rect(image, cx - 12, cy - 2, 4, 10, Color(PALETTES["kael_imp"]["skin_mid"]))
 _draw_rect(image, cx + 8, cy - 2, 4, 10, Color(PALETTES["kael_imp"]["skin_mid"]))
 
 # Pernas
 _draw_rect(image, cx - 5, cy + 8, 3, 10, Color(PALETTES["kael_imp"]["skin_dark"]))
 _draw_rect(image, cx + 2, cy + 8, 3, 10, Color(PALETTES["kael_imp"]["skin_dark"]))
 
 # Detalhes de roupa/armadura
 var armor_color = Color("#4A3A2A")
 _draw_rect(image, cx - 6, cy - 2, 12, 6, armor_color)
 
 # Sombra projetada
 _draw_ellipse_shadow(image, cx, cy + 14, 10, 3, Color(0,0,0,0.3))

func _draw_ellipse(image: Image, cx: int, cy: int, rx: int, ry: int, colors: Array, filled: bool) -> void:
 var color_dark = colors[0]
 var color_mid = colors[1]
 var color_light = colors[2]
 
 for y in range(-ry, ry + 1):
  for x in range(-rx, rx + 1):
   var dx = float(x) / rx
   var dy = float(y) / ry
   var dist = sqrt(dx * dx + dy * dy)
   
   if (filled and dist <= 1.0) or (!filled and abs(dist - 1.0) < 0.15):
    var px = cx + x
    var py = cy + y
    if px >= 0 and px < 64 and py >= 0 and py < 64:
     var shade = 1.0 - dist * 0.5
     if shade > 0.7:
      image.set_pixel(cx + x, cy + y, colors[2])
     elif shade > 0.4:
      image.set_pixel(cx + x, cy + y, colors[1])
     else:
      image.set_pixel(cx + x, cy + y, colors[0])

func _draw_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
 for i in range(w):
  for j in range(h):
   if x + i >= 0 and x + i < 64 and y + j >= 0 and y + j < 64:
    image.set_pixel(x + i, y + j, color)

func _draw_triangle(image: Image, x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, color: Color) -> void:
 # Algoritmo de Bresenham para triângulo preenchido
 var min_y = min(y1, min(y2, y3))
 var max_y = max(y1, max(y2, y3))
 
 for y in range(min_y, max_y + 1):
  var intersections = []
  
  _line_intersection(x1, y1, x2, y2, y, intersections)
  _line_intersection(x2, y2, x3, y3, y, intersections)
  _line_intersection(x3, y3, x1, y1, y, intersections)
  
  intersections.sort()
  for i in range(0, intersections.size(), 2):
   if i + 1 < intersections.size():
    for x in range(intersections[i], intersections[i + 1] + 1):
     if x >= 0 and x < 64 and y >= 0 and y < 64:
      image.set_pixel(x, y, color)

func _line_intersection(x1: int, y1: int, x2: int, y2: int, y: int, intersections: Array) -> void:
 if (y1 <= y and y2 > y) or (y2 <= y and y1 > y):
  var t = float(y - y1) / float(y2 - y1)
  var x = int(x1 + t * (x2 - x1))
  intersections.append(x)

func _draw_ellipse_shadow(image: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
 for y in range(-ry, ry + 1):
  for x in range(-rx, rx + 1):
   var dx = float(x) / rx
   var dy = float(y) / ry
   if dx * dx + dy * dy <= 1.0:
    var px = cx + x
    var py = cy + y
    if px >= 0 and px < 64 and py >= 0 and py < 64:
     image.set_pixel(px, py, color)

# === TERRENOS AVANÇADOS ===

func create_detailed_terrain(terrain_type: String, size: int = 64, animated: bool = false) -> Sprite2D:
 var sprite = Sprite2D.new()
 var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
 
 var terrain = TERRAINS.get(terrain_type, TERRAINS.grass)
 
 if terrain_type == "grass":
  _generate_grass(image, terrain)
 elif terrain_type == "water":
  _generate_water_static(image)
 elif terrain_type == "stone":
  _generate_stone(image, terrain)
 elif terrain_type == "lava":
  _generate_lava_static(image)
 elif terrain_type == "castle":
  _generate_castle(image, terrain)
 elif terrain_type == "cave":
  _generate_cave(image, terrain)
 elif terrain_type == "forest":
  _generate_forest(image, terrain)
 else:
  image.fill(Color(0.2, 0.2, 0.2))
 
 var texture = ImageTexture.create_from_image(image)
 var sprite_node = Sprite2D.new()
 sprite_node.texture = texture
 
 if terrain_type == "water" or terrain_type == "grass":
  if animated:
   # Adicionar script de animação depois
   pass
 
 return sprite_node

func _generate_grass(image: Image, terrain: Dictionary) -> void:
 var light = Color(terrain["colors"][1])
 var dark = Color(terrain["colors"][0])
 var mid = Color(terrain["colors"][2])
 var size = image.get_width()
 
 image.fill(light)
 
 # Base noise
 for i in range(size * size / 4):
  var x = randi() % size
  var y = randi() % size
  var noise = randf()
  if noise < 0.3:
   image.set_pixel(x, y, dark)
  elif noise < 0.5:
   image.set_pixel(x, y, mid)
 
 # Grama em tufos
 for i in range(20):
  var x = randi() % (size - 4)
  var y = randi() % (size - 4)
  var h = randi_range(2, 5)
  var blade_color = Color(terrain["colors"][randi() % terrain["colors"].size()])
  for j in range(h):
   if y - j >= 0:
    image.set_pixel(x, y - j, blade_color)
 
 # Flores
 if terrain.has("flowers"):
  for flower_color_str in terrain["flowers"]:
   var flower_color = Color(flower_color_str)
   for i in range(5):
    var x = randi() % (size - 2)
    var y = randi() % (size - 2)
    if randf() < 0.1:
     image.set_pixel(x, y, Color(flower_color_str))
     image.set_pixel(x+1, y, Color(flower_color_str))
     image.set_pixel(x, y+1, Color(flower_color_str))

func _generate_water_static(image: Image) -> void:
 var size = image.get_width()
 var deep = Color("#0A1A3A")
 var mid = Color("#1A3A5A")
 var shallow = Color("#2A5A8A")
 var foam = Color("#E0F0FF")
 
 for y in range(image.get_height()):
  for x in range(image.get_width()):
   var dy = float(y) / size
   var base = lerp(deep, shallow, dy)
   
   // Ondas sutis
   var wave = sin(float(x) * 0.3) * 0.1 + sin(float(x) * 0.1) * 0.05
   var depth = clamp(float(y) / image.get_height() + wave, 0.0, 1.0)
   
   var color = lerp(Color("#0A1A3A"), Color("#2A5A8A"), depth)
   
   // Espuma nas bordas
   var foam_amount = sin(float(x) * 0.5 + float(y) * 0.3) * 0.5 + 0.5
   if foam_amount > 0.9 and randf() < 0.1:
    image.set_pixel(x, y, Color("#E0F0FF"))
   else:
    image.set_pixel(x, y, color)

func _generate_stone(image: Image, terrain: Dictionary) -> void:
 var size = image.get_width()
 var colors = terrain["colors"]
 var moss_colors = terrain.get("moss", [])
 var crack_color = Color(terrain["cracks"][0])
 
 image.fill(Color(colors[0]))
 
 // Ruído base
 for i in range(size * size / 3):
  var x = randi() % size
  var y = randi() % size
  image.set_pixel(x, y, Color(colors[randi() % colors.size()]))
 
 // Musgo
 for moss_str in moss_colors:
  var moss_color = Color(moss_str)
  for i in range(30):
   var x = randi() % size
   var y = randi() % size
   if randf() < 0.15:
    image.set_pixel(x, y, moss_color)
 
 // Rachaduras
 for i in range(8):
  var x1 = randi() % size
  var y1 = randi() % size
  var x2 = x1 + randi_range(-5, 5)
  var y2 = y1 + randi_range(-5, 5)
  _draw_line(image, x1, y1, x2, y2, crack_color)

func _generate_lava_static(image: Image) -> void:
 var size = image.get_width()
 var colors = ["#8B0000", "#CC3300", "#FF4500", "#FF6600", "#FF8800", "#FFAA00"]
 
 for y in range(image.get_height()):
  for x in range(image.get_width()):
   var dy = float(y) / size
   var base_idx = int(lerp(0, 5, dy))
   var base = Color(colors[min(base_idx, 5)])
   
   // Bolhas
   var bubble = sin(float(x) * 0.4 + float(y) * 0.3) * 0.3
   var heat = clamp(bubble + randf() * 0.5, 0.0, 1.0)
   
   var color = lerp(Color("#8B0000"), Color("#FFAA00"), heat)
   image.set_pixel(x, y, color)

func _generate_castle(image: Image, terrain: Dictionary) -> void:
 var size = image.get_width()
 var stone_dark = Color(terrain["stone_dark"])
 var stone_mid = Color(terrain["stone_mid"])
 var stone_light = Color(terrain["stone_light"])
 var gold = Color(terrain["gold"])
 
 image.fill(stone_dark)
 
 // Padrão de tijolos
 for y in range(0, size, 8):
  for x in range(0, size, 16):
   var offset = (y / 8) % 2 * 8
   var bx = (x + offset) % size
   for by in range(y, min(y + 8, size)):
    for bx2 in range(bx, min(bx + 14, size)):
     if bx2 < size and by < size:
      var noise = randf()
      if noise < 0.1:
       image.set_pixel(bx2, by, Color(terrain["stone_light"]))
      elif noise < 0.2:
       image.set_pixel(bx2, by, Color(terrain["stone_mid"]))
      else:
       image.set_pixel(bx2, by, Color(terrain["stone_dark"]))
 
 // Detalhes dourados
 for i in range(5):
  var x = randi() % size
  var y = randi() % (size / 2)
  for dy in range(3):
   if y + dy < size:
    image.set_pixel(x, y + dy, Color("#DAA520"))

func _generate_forest(image: Image, terrain: Dictionary) -> void:
 var size = image.get_width()
 var ground = Color(terrain["ground"])
 var grass = Color(terrain["grass"])
 var leaves_colors = terrain["leaves"]
 var trunks = terrain["trunks"]
 var canopy = Color(terrain["canopy"])
 
 image.fill(ground)
 
 // Grama base
 for i in range(size * size / 3):
  var x = randi() % size
  var y = randi() % size
  if randf() < 0.5:
   image.set_pixel(x, y, grass)
  else:
   image.set_pixel(x, y, Color(terrain["ground"]))
 
 // Árvores
 for i in range(12):
  var tx = randi() % (size - 6)
  var ty = randi() % (size - 10)
  var trunk_color = Color(trunks[randi() % trunks.size()])
  var leaf_color = Color(leaves_colors[randi() % leaves_colors.size()])
  var h = randi_range(6, 12)
  var w = randi_range(4, 8)
  
  // Tronco
  for y in range(h):
   for x in range(2):
    if tx + x < size and ty + y < size:
     image.set_pixel(tx + x, ty + y, trunk_color)
  
  // Copa
  for ly in range(h):
   var lw = w - abs(ly - h/2) * w / h * 0.8
   for lx in range(int(lw)):
    if tx + lx < size and ty + ly < size:
     image.set_pixel(tx + lx, ty + ly, Color(leaves_colors[randi() % leaves_colors.size()]))

func _generate_cave(image: Image, terrain: Dictionary) -> void:
 var size = image.get_width()
 var wall_dark = Color(terrain["wall_dark"])
 var wall_mid = Color(terrain["wall_mid"])
 var wall_light = Color(terrain["wall_light"])
 var crystals = terrain["crystals"]
 
 image.fill(wall_dark)
 
 // Textura de parede
 for i in range(size * size / 2):
  var x = randi() % size
  var y = randi() % size
  var c = randf()
  if c < 0.33:
   image.set_pixel(x, y, wall_dark)
  elif c < 0.66:
   image.set_pixel(x, y, wall_mid)
  else:
   image.set_pixel(x, y, wall_light)
 
 // Cristais
 for crystal_str in crystals:
  var c = Color(crystal_str)
  for i in range(5):
   var cx = randi() % (size - 4)
   var cy = randi() % (size - 4)
   var s = randi_range(2, 5)
   for dy in range(s):
    for dx in range(s - abs(dy - s/2)):
     if cx + dx < size and cy + dy < size:
      image.set_pixel(cx + dx, cy + dy, c)

# === FUNÇÕES AUXILIARES ===

func _draw_line(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
 var dx = abs(x2 - x1)
 var dy = abs(y2 - y1)
 var sx = 1 if x1 < x2 else -1
 var sy = 1 if y1 < y2 else -1
 var err = dx - dy
 
 while true:
  if x1 >= 0 and x1 < 64 and y1 >= 0 and y1 < 64:
   image.set_pixel(x1, y1, color)
  if x1 == x2 and y1 == y2:
   break
  var e2 = 2 * err
  if e2 > -dy:
   err -= dy
   x1 += 1 if x1 < x2 else -1
  if e2 < dx:
   err += dx
   y1 += 1 if y1 < y2 else -1

# === APLICAR SHADERS ===

func apply_outline(sprite: Sprite2D, width: float = 1.5, color: Color = Color(0.05, 0.05, 0.1)) -> void:
 if not sprite:
  return
 var mat = outline_shader.duplicate()
 mat.set_shader_parameter("outline_width", width)
 mat.set_shader_parameter("outline_color", color)
 sprite.material = mat

func apply_glow(sprite: Sprite2D, intensity: float = 0.8, color: Color = Color(1.0, 0.95, 0.7, 1.0)) -> void:
 if not sprite:
  return
 var mat = glow_shader.duplicate()
 mat.set_shader_parameter("glow_intensity", intensity)
 mat.set_shader_parameter("glow_color", color)
 mat.set_shader_parameter("pulse", true)
 mat.set_shader_parameter("pulse_speed", 2.0)
 sprite.material = mat

func apply_water_shader(sprite: Sprite2D) -> void:
 if not sprite:
  return
 var mat = water_shader.duplicate()
 mat.set_shader_parameter("time", 0.0)
 mat.set_shader_parameter("wave_speed", 1.2)
 mat.set_shader_parameter("wave_height", 2.0)
 sprite.material = mat

func apply_grass_shader(sprite: Sprite2D) -> void:
 if not sprite:
  return
 var mat = grass_shader.duplicate()
 mat.set_shader_parameter("time", 0.0)
 mat.set_shader_parameter("wind_speed", 0.8)
 mat.set_shader_parameter("wind_strength", 1.5)
 sprite.material = mat

func apply_rim_light(sprite: Sprite2D, intensity: float = 0.8, color: Color = Color(0.2, 0.6, 1.0)) -> void:
 if not sprite:
  return
 var mat = rim_light_shader.duplicate()
 mat.set_shader_parameter("rim_intensity", intensity)
 mat.set_shader_parameter("rim_color", color)
 sprite.material = mat

func apply_dither(sprite: Sprite2D, amount: float = 0.3) -> void:
 if not sprite:
  return
 var mat = dither_shader.duplicate()
 mat.set_shader_parameter("dither_amount", amount)
 sprite.material = mat

func apply_all_effects(sprite: Sprite2D, character_type: String = "default") -> void:
 if not sprite:
  return
 apply_outline(sprite, 1.5, Color(0.05, 0.05, 0.1))
 apply_rim_light(sprite, 0.6, Color(0.2, 0.6, 1.0))
 if character_type == "magic":
  apply_glow(sprite, 0.6, Color(0.2, 0.8, 1.0))
 elif character_type == "fire":
  apply_glow(sprite, 0.8, Color(1.0, 0.4, 0.1))

# === CRIAÇÃO DE PERSONAGENS ESPECÍFICOS ===

func create_kael(form: String = "imp") -> Sprite2D:
 var palette = PALETTES.get("kael_" + form, PALETTES.kael_imp)
 return create_detailed_character("kael_" + form, 64)

func create_kroug(form: String = "base") -> Sprite2D:
 var palette = PALETTES.get("kroug", PALETTES.kroug)
 return create_detailed_character("kroug", 64)

func create_lira(form: String = "base") -> Sprite2D:
 var palette = PALETTES.get("lira", PALETTES.lira)
 return create_detailed_character("lira", 64)

func create_thalkor(form: String = "base") -> Sprite2D:
 var palette = PALETTES.get("thalkor", PALETTES.thalkor)
 return create_detailed_character("thalkor", 64)

func create_enemy(enemy_type: String) -> Sprite2D:
 var palette = PALETTES.get("enemy_" + enemy_type, PALETTES.enemy_mercenary)
 return create_detailed_character("enemy_" + enemy_type, 64)

# === EXEMPLO DE USO ===
# var kael = PixelArtRenderer.create_kael("imp")
# var kroug = PixelArtRenderer.create_kroug()
# var water_tile = PixelArtRenderer.create_detailed_terrain("water", 64, true)
# var grass_tile = PixelArtRenderer.create_detailed_terrain("grass", 64, true)

# // Aplicar efeitos
# PixelArtRenderer.apply_all_effects(kael_sprite, "magic")
# PixelArtRenderer.apply_grass_shader(grass_tile)
# PixelArtRenderer.apply_water_shader(water_tile)