class_name ScreenEffects
extends CanvasLayer

# Sistema de efeitos de tela - QUALIDADE SEA OF STARS
# - Screen shake avançado (direcional, rotacional, trauma)
# - Slow motion contextual
# - Flash de tela com cores
# - Vinheta dinâmica
# - Transições avançadas (fade, iris, slide, dissolve)
# - Chromatic aberration
# - Vignette dinâmica
# - Letterbox cinematográfico

var camera: Camera2D
var is_shaking: bool = false
var is_slow_motion: bool = false
var vignette_node: ColorRect
var chromatic_aberration_node: ColorRect

func _ready() -> void:
 layer = 200
 create_chromatic_aberration()

func create_chromatic_aberration() -> void:
 chromatic_aberration_node = ColorRect.new()
 chromatic_aberration_node.color = Color(1, 1, 1, 1)
 chromatic_aberration_node.anchors_preset = 15
 chromatic_aberration_node.anchor_right = 1.0
 chromatic_aberration_node.anchor_bottom = 1.0
 chromatic_aberration_node.grow_horizontal = 2
 chromatic_aberration_node.grow_vertical = 2
 chromatic_aberration_node.z_index = 997
 chromatic_aberration_node.visible = false
 add_child(chromatic_aberration_node)

func setup_camera(cam: Camera2D) -> void:
 camera = cam

# === SCREEN SHAKE AVANÇADO ===

var shake_trauma: float = 0.0
var shake_decay: float = 2.0

func add_trauma(amount: float) -> void:
 shake_trauma = min(shake_trauma + amount, 1.0)

func shake(intensity: float = 5.0, duration: float = 0.2, directional: Vector2 = Vector2(0, 0), rotational: float = 0.0) -> void:
 if not camera or is_shaking:
  return

 is_shaking = true
 add_trauma(intensity / 10.0)

 var original_position = camera.position
 var original_rotation = camera.rotation
 var elapsed = 0.0

 while elapsed < duration:
  var progress = elapsed / duration
  var current_intensity = intensity * (1.0 - progress) # Decay
  
  # Shake posicional
  var offset = Vector2.ZERO
  if intensity > 0:
   offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * current_intensity
   if directional.length() > 0:
    offset += directional.normalized() * current_intensity * 0.5
  
  # Shake rotacional
  var rotation_offset = 0.0
  if rotational > 0:
   rotation_offset = randf_range(-1, 1) * rotational * current_intensity * 0.01
  
  camera.position = original_position + offset
  camera.rotation = original_rotation + rotation_offset

  await get_tree().create_timer(0.016).timeout
  elapsed += 0.016

 camera.position = original_position
 camera.rotation = original_rotation
 is_shaking = false

func shake_trauma_based(amount: float, duration: float = 0.5) -> void:
 add_trauma(amount)
 shake(amount * 10.0, duration)

func shake_light() -> void:
 await shake(3.0, 0.15)

func shake_medium() -> void:
 await shake(6.0, 0.25)

func shake_heavy() -> void:
 await shake(10.0, 0.35)

func shake_critical() -> void:
 await shake(15.0, 0.5, false)

func shake_directional(direction: Vector2, intensity: float = 8.0, duration: float = 0.3) -> void:
 await shake(intensity, duration, direction.normalized())

func shake_rotational(amount: float = 0.1, duration: float = 0.2) -> void:
 await shake(0.0, duration, Vector2.ZERO, amount)

# === TRAUMA SYSTEM (contínuo) ===

func _process(delta: float) -> void:
 if shake_trauma > 0:
  shake_trauma = max(shake_trauma - shake_decay * delta, 0.0)
  
  if shake_trauma > 0.01 and camera:
   var intensity = shake_trauma * shake_trauma * 15.0
   var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
   camera.position = camera.position + offset

# === SLOW MOTION ===

var is_slow_motion: bool = false

func slow_motion(scale: float = 0.25, duration: float = 0.5, ease_in: float = 0.1, ease_out: float = 0.2) -> void:
 if is_slow_motion:
  return

 is_slow_motion = true
 
 # Ease in
 var tween = create_tween()
 tween.tween_property(Engine, "time_scale", scale, ease_in).set_trans(Tween.TRANS_QUAD)
 await tween.finished
 
 await get_tree().create_timer(duration * scale).timeout
 
 # Ease out
 tween = create_tween()
 tween.tween_property(Engine, "time_scale", 1.0, ease_out).set_trans(Tween.TRANS_QUAD)
 await tween.finished
 
 is_slow_motion = false

func hit_pause(duration: float = 0.08) -> void:
 slow_motion(0.1, duration, 0.02, 0.05)

func hit_pause_heavy(duration: float = 0.15) -> void:
 slow_motion(0.05, duration, 0.05, 0.1)

func pause_game(duration: float = 0.1) -> void:
 get_tree().paused = true
 await get_tree().create_timer(duration).timeout
 get_tree().paused = false

# === FLASH DE TELA ===

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1, curve: float = 1.0) -> void:
 var flash = ColorRect.new()
 flash.color = color
 flash.anchors_preset = 15
 flash.anchor_right = 1.0
 flash.anchor_bottom = 1.0
 flash.grow_horizontal = 2
 flash.grow_vertical = 2
 flash.z_index = 999
 flash.modulate.a = 0.0

 add_child(flash)

 var tween = create_tween()
 tween.tween_property(flash, "modulate:a", 1.0, duration * 0.3).set_trans(Tween.TRANS_QUAD)
 tween.tween_property(flash, "modulate:a", 0.0, duration * 0.7).set_trans(Tween.TRANS_QUAD)
 tween.tween_callback(flash.queue_free)

func flash_white(intensity: float = 1.0, duration: float = 0.1) -> void:
 await flash_screen(Color(1, 1, 1, intensity), duration)

func flash_red(intensity: float = 1.0, duration: float = 0.15) -> void:
 await flash_screen(Color(1, 0, 0, intensity), duration)

func flash_gold(intensity: float = 1.0, duration: float = 0.15) -> void:
 await flash_screen(Color(1, 0.85, 0, intensity), duration)

func flash_blue(intensity: float = 1.0, duration: float = 0.2) -> void:
 await flash_screen(Color(0, 0.5, 1, intensity), duration)

func flash_elemental(element: String, intensity: float = 1.0) -> void:
 var colors = {
  "fire": Color(1, 0.3, 0.1),
  "water": Color(0, 0.6, 1),
  "earth": Color(0.4, 0.8, 0.2),
  "air": Color(0.9, 0.95, 1),
  "shadow": Color(0.6, 0.1, 0.8),
  "light": Color(1, 0.95, 0.2),
  "ice": Color(0.5, 0.8, 1),
  "lightning": Color(1, 0.9, 0.1),
  "blood": Color(0.7, 0.1, 0.1),
  "heal": Color(0.4, 1, 0.2)
 }
 
 var color = { "fire": Color(1, 0.3, 0.1), "water": Color(0, 0.6, 1), "earth": Color(0.4, 0.8, 0.2), 
               "air": Color(0.9, 0.95, 1), "shadow": Color(0.6, 0.1, 0.8), "light": Color(1, 0.95, 0.2),
               "ice": Color(0.5, 0.8, 1), "lightning": Color(1, 0.9, 0.1), "blood": Color(0.7, 0.1, 0.1),
               "heal": Color(0.4, 1, 0.2) }.get(element, Color.WHITE)
  
 await flash_screen(Color(color.r, color.g, color.b, intensity), 0.15)

# === CHROMATIC ABERRATION ===

func enable_chromatic_aberration(intensity: float = 0.02, duration: float = 0.5) -> void:
 if not chromatic_aberration_node:
  create_chromatic_aberration()
  
 chromatic_aberration_node.visible = true
 chromatic_aberration_node.material = ShaderMaterial.new()
 
 var shader = Shader.new()
 shader.code = """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 0.1) = 0.02;
uniform float time : hint_range(0.0, 100.0) = 0.0;

void fragment() {
 vec4 tex_color = texture(TEXTURE, UV);
 vec2 pixel_size = SCREEN_PIXEL_SIZE;
 
 float r = texture(TEXTURE, UV + vec2(intensity * sin(time * 2.0), 0.0)).r;
 float g = tex_color.g;
 float b = texture(TEXTURE, UV - vec2(intensity * sin(time * 3.0), 0.0)).b;
 
 COLOR = vec4(r, g, b, tex_color.a);
 }
 """
 
 var shader_mat = ShaderMaterial.new()
 shader_mat.shader = shader
 chromatic_aberration_node.material = shader_mat
 chromatic_aberration_node.visible = true

 var tween = create_tween()
 tween.tween_property(chromatic_aberration_node.material, "shader_parameter/intensity", 0.0, duration).set_trans(Tween.TRANS_QUAD)
 tween.tween_callback(func(): chromatic_aberration_node.visible = false)

func create_chromatic_aberration() -> void:
 chromatic_aberration_node = ColorRect.new()
 chromatic_aberration_node.color = Color(1, 1, 1, 1)
 chromatic_aberration_node.anchors_preset = 15
 chromatic_aberration_node.anchor_right = 1.0
 chromatic_aberration_node.anchor_bottom = 1.0
 chromatic_aberration_node.grow_horizontal = 2
 chromatic_aberration_node.grow_vertical = 2
 chromatic_aberration_node.z_index = 997
 chromatic_aberration_node.visible = false
 add_child(chromatic_aberration_node)

# === VIGNETTE DINÂMICA ===

var vignette_node: ColorRect

func add_vignette(intensity: float = 0.3, animated: bool = false) -> void:
 if vignette_node:
  remove_vignette()
  
 vignette_node = ColorRect.new()
 vignette_node.color = Color(0, 0, 0, intensity)
 vignette_node.anchors_preset = 15
 vignette_node.anchor_right = 1.0
 vignette_node.anchor_bottom = 1.0
 vignette_node.grow_horizontal = 2
 vignette_node.grow_vertical = 2
 vignette_node.z_index = 998

 if animated:
  var shader = Shader.new()
  shader.code = """
shader_type canvas_item;
uniform float intensity = 0.3;
uniform float time = 0.0;
void fragment() {
 float dist = distance(UV, vec2(0.5));
 float vignette = 1.0 - smoothstep(0.3, 0.8, dist);
 vignette += sin(time * 2.0) * 0.02;
 COLOR = vec4(0.0, 0.0, 0.0, vignette * intensity);
}
  """
  
  var shader_mat = ShaderMaterial.new()
  shader_mat.shader = shader
  vignette_node.material = shader_mat

 add_child(vignette_node)

func remove_vignette(animated: bool = true) -> void:
 if vignette_node:
  if animated:
   var tween = create_tween()
   tween.tween_property(vignette_node, "modulate:a", 0.0, 0.5)
   tween.tween_callback(func(): vignette_node.queue_free(); vignette_node = null)
  else:
   vignette_node.queue_free()
   vignette_node = null

func pulse_vignette(intensity: float = 0.4, speed: float = 1.0) -> void:
 if not vignette_node:
  add_vignette(intensity, true)
  return
  
 var tween = create_tween()
 tween.set_loops()
 tween.tween_property(vignette_node, "modulate:a", intensity, 1.0 / speed)
 tween.tween_property(vignette_node, "modulate:a", intensity * 0.5, 1.0 / speed)

# === CINEMATIC LETTERBOX ===

var letterbox_top: ColorRect
var letterbox_bottom: ColorRect

func add_letterbox(ratio: float = 2.35, duration: float = 0.5) -> void:
 var bar_height = (1.0 - 1.0 / ratio) * 360 / 2.0
 
 letterbox_top = ColorRect.new()
 letterbox_top.color = Color.BLACK
 letterbox_top.anchors_preset = 10
 letterbox_top.anchor_right = 1.0
 letterbox_top.anchor_bottom = 0.5
 letterbox_top.offset_bottom = -bar_height
 letterbox_top.grow_horizontal = 2
 letterbox_top.z_index = 996
 letterbox_top.position.y = -bar_height
 add_child(letterbox_top)

 letterbox_bottom = ColorRect.new()
 letterbox_bottom.color = Color.BLACK
 letterbox_bottom.anchors_preset = 12
 letterbox_bottom.anchor_right = 1.0
 letterbox_bottom.anchor_top = 0.5
 letterbox_bottom.offset_top = bar_height
 letterbox_bottom.grow_horizontal = 2
 letterbox_bottom.z_index = 996
 add_child(letterbox_bottom)

 var tween = create_tween()
 tween.tween_property(letterbox_top, "position:y", 0, duration).set_trans(Tween.TRANS_QUAD)
 tween.parallel().tween_property(letterbox_bottom, "position:y", 720 - bar_height, duration).set_trans(Tween.TRANS_QUAD)

func remove_letterbox(duration: float = 0.5) -> void:
 if letterbox_top and letterbox_bottom:
  var bar_height = letterbox_top.rect_size.y
  
  var tween = create_tween()
  tween.tween_property(letterbox_top, "position:y", -bar_height, duration).set_trans(Tween.TRANS_QUAD)
  tween.parallel().tween_property(letterbox_bottom, "position:y", 720 + bar_height, duration).set_trans(Tween.TRANS_QUAD)
  tween.tween_callback(func(): 
   letterbox_top.queue_free()
   letterbox_bottom.queue_free()
   letterbox_top = null
   letterbox_bottom = null
  )

# === TRANSIÇÕES AVANÇADAS ===

func dissolve_transition(scene_path: String, duration: float = 1.0) -> void:
 var mask = ColorRect.new()
 mask.color = Color.BLACK
 mask.anchors_preset = 15
 mask.anchor_right = 1.0
 mask.anchor_bottom = 1.0
 mask.grow_horizontal = 2
 mask.grow_vertical = 2
 mask.z_index = 999
 mask.modulate.a = 0.0

 var shader = Shader.new()
 shader.code = """
shader_type canvas_item;

uniform float progress = 0.0;
uniform float softness = 0.1;

void fragment() {
 float d = distance(UV, vec2(0.5));
 float mask = smoothstep(progress - softness, progress + softness, d);
 COLOR = vec4(0.0, 0.0, 0.0, mask);
}
 """
 
 var mat = ShaderMaterial.new()
 mask.material = ShaderMaterial.new()
 mask.material.shader = Shader.new()
 mask.material.shader.code = shader.code
 mask.material.set_shader_parameter("progress", 0.0)
 mask.material.set_shader_parameter("softness", 0.15)

 add_child(mask)

 var tween = create_tween()
 tween.tween_property(mask.material, "shader_parameter/progress", 1.0, duration / 2)
 await tween.finished

 get_tree().change_scene_to_file(scene_path)

 var tween2 = create_tween()
 tween2.tween_property(mask.material, "shader_parameter/progress", 0.0, duration / 2)
 tween2.tween_callback(mask.queue_free)

func iris_transition(scene_path: String, center: Vector2 = Vector2(640, 360), duration: float = 0.8) -> void:
 var mask = ColorRect.new()
 mask.color = Color.BLACK
 mask.anchors_preset = 15
 mask.anchor_right = 1.0
 mask.anchor_bottom = 1.0
 mask.grow_horizontal = 2
 mask.grow_vertical = 2
 mask.z_index = 999
 mask.modulate.a = 1.0

 var shader = Shader.new()
 shader.code = """
shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.0;

void fragment() {
 float dist = distance(UV, center);
 float mask = smoothstep(radius - 0.02, radius + 0.02, dist);
 COLOR = vec4(0.0, 0.0, 0.0, mask);
}
 """
 
 var mat = ShaderMaterial.new()
 mat.shader = Shader.new()
 mat.shader.code = shader.code
 mat.set_shader_parameter("center", center / Vector2(1280, 720))
 mat.set_shader_parameter("radius", 0.0)
 mask.material = mat
 mask.z_index = 999
 add_child(mask)

 var tween = create_tween()
 tween.tween_property(mat, "shader_parameter/radius", 1.5, duration / 2)
 await tween.finished

 get_tree().change_scene_to_file(scene_path)

 var tween2 = create_tween()
 tween2.tween_property(mat, "shader_parameter/radius", 0.0, duration / 2)
 tween2.tween_callback(mask.queue_free)

# === LIMPAR ===

func clear_all_effects() -> void:
 for child in get_children():
  if child is ColorRect:
   child.queue_free()

 Engine.time_scale = 1.0
 is_shaking = false
 is_slow_motion = false
 
 if chromatic_aberration_node:
  chromatic_aberration_node.visible = false
 if vignette_node:
  vignette_node.queue_free()
  vignette_node = null

func setup_camera(cam: Camera2D) -> void:
 camera = cam

# === CINEMATIC BARS ===

var cinematic_bars: Array = []

func set_cinematic_mode(enabled: bool, ratio: float = 2.35:1, duration: float = 0.5) -> void:
 var target_height = (1.0 - 1.0 / ratio) * 360 / 2.0
 
 if enabled:
  if not cinematic_bars.size():
   var top = ColorRect.new()
   top.color = Color.BLACK
   top.anchors_preset = 10
   top.anchor_right = 1.0
   top.anchor_bottom = 0.5
   top.offset_bottom = -360
   top.grow_horizontal = 2
   top.z_index = 995
   add_child(top)
   
   var bottom = ColorRect.new()
   bottom.color = Color.BLACK
   bottom.anchors_preset = 12
   bottom.anchor_right = 1.0
   bottom.anchor_top = 0.5
   bottom.offset_top = 360
   bottom.grow_horizontal = 2
   bottom.z_index = 995
   add_child(bottom)
   
   cinematic_bars = [top, bottom]
   
   var tween = create_tween()
   tween.tween_property(top, "offset_bottom", -360 * 0.5, duration).set_trans(Tween.TRANS_QUAD)
   tween.parallel().tween_property(bottom, "offset_top", 360 * 0.5, duration).set_trans(Tween.TRANS_QUAD)
 else:
  if cinematic_bars.size() == 2:
   var bar_height = cinematic_bars[0].rect_size.y
   
   var tween = create_tween()
   tween.tween_property(cinematic_bars[0], "offset_bottom", -360, duration).set_trans(Tween.TRANS_QUAD)
   tween.parallel().tween_property(cinematic_bars[1], "offset_top", 360, duration).set_trans(Tween.TRANS_QUAD)
   tween.tween_callback(func(): 
    cinematic_bars[0].queue_free()
    cinematic_bars[1].queue_free()
    cinematic_bars.clear()
   )