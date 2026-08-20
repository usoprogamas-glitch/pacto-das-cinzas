class_name ScreenEffects
extends CanvasLayer

# Sistema de efeitos de tela
# - Screen shake
# - Slow motion
# - Flash de tela
# - Vinheta
# - Transição

var camera: Camera2D
var is_shaking: bool = false
var is_slow_motion: bool = false

func _ready() -> void:
 layer = 100

func setup_camera(cam: Camera2D) -> void:
 camera = cam

# === SCREEN SHAKE ===

func shake(intensity: float = 5.0, duration: float = 0.2) -> void:
 if not camera or is_shaking:
  return

 is_shaking = true
 var original_position = camera.position
 var elapsed = 0.0

 while elapsed < duration:
  var progress = elapsed / duration
  var current_intensity = intensity * (1.0 - progress) # Decay
  var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * current_intensity
  camera.position = original_position + offset

  await get_tree().create_timer(0.02).timeout
  elapsed += 0.02

 camera.position = original_position
 is_shaking = false

func shake_light() -> void:
 await shake(3.0, 0.15)

func shake_medium() -> void:
 await shake(6.0, 0.25)

func shake_heavy() -> void:
 await shake(10.0, 0.35)

# === SLOW MOTION ===

func slow_motion(scale: float = 0.3, duration: float = 0.5) -> void:
 if is_slow_motion:
  return

 is_slow_motion = true
 Engine.time_scale = scale

 await get_tree().create_timer(duration * scale).timeout

 Engine.time_scale = 1.0
 is_slow_motion = false

func pause_game(duration: float = 0.1) -> void:
 get_tree().paused = true
 await get_tree().create_timer(duration).timeout
 get_tree().paused = false

# === FLASH DE TELA ===

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1) -> void:
 var flash = ColorRect.new()
 flash.color = color
 flash.anchors_preset = 15
 flash.anchor_right = 1.0
 flash.anchor_bottom = 1.0
 flash.grow_horizontal = 2
 flash.grow_vertical = 2
 flash.z_index = 999

 add_child(flash)

 var tween = create_tween()
 tween.tween_property(flash, "modulate:a", 0.0, duration)
 tween.tween_callback(flash.queue_free)

func flash_white() -> void:
 await flash_screen(Color.WHITE, 0.1)

func flash_red() -> void:
 await flash_screen(Color(1, 0, 0, 0.5), 0.15)

func flash_blue() -> void:
 await flash_screen(Color(0, 0.5, 1, 0.3), 0.2)

# === TRANSIÇÕES ===

func fade_to_black(duration: float = 0.5) -> void:
 var fade = ColorRect.new()
 fade.color = Color.BLACK
 fade.anchors_preset = 15
 fade.anchor_right = 1.0
 fade.anchor_bottom = 1.0
 fade.grow_horizontal = 2
 fade.grow_vertical = 2
 fade.z_index = 999
 fade.modulate.a = 0.0

 add_child(fade)

 var tween = create_tween()
 tween.tween_property(fade, "modulate:a", 1.0, duration)
 await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
 var fade = ColorRect.new()
 fade.color = Color.BLACK
 fade.anchors_preset = 15
 fade.anchor_right = 1.0
 fade.anchor_bottom = 1.0
 fade.grow_horizontal = 2
 fade.grow_vertical = 2
 fade.z_index = 999
 fade.modulate.a = 1.0

 add_child(fade)

 var tween = create_tween()
 tween.tween_property(fade, "modulate:a", 0.0, duration)
 tween.tween_callback(fade.queue_free)

func fade_to_color(color: Color, duration: float = 0.5) -> void:
 var fade = ColorRect.new()
 fade.color = color
 fade.anchors_preset = 15
 fade.anchor_right = 1.0
 fade.anchor_bottom = 1.0
 fade.grow_horizontal = 2
 fade.grow_vertical = 2
 fade.z_index = 999
 fade.modulate.a = 0.0

 add_child(fade)

 var tween = create_tween()
 tween.tween_property(fade, "modulate:a", 1.0, duration)
 await tween.finished

func fade_from_color(color: Color, duration: float = 0.5) -> void:
 var fade = ColorRect.new()
 fade.color = color
 fade.anchors_preset = 15
 fade.anchor_right = 1.0
 fade.anchor_bottom = 1.0
 fade.grow_horizontal = 2
 fade.grow_vertical = 2
 fade.z_index = 999
 fade.modulate.a = 1.0

 add_child(fade)

 var tween = create_tween()
 tween.tween_property(fade, "modulate:a", 0.0, duration)
 tween.tween_callback(fade.queue_free)

# === VINHETA ===

func add_vignette(intensity: float = 0.3) -> void:
 var vignette = ColorRect.new()
 vignette.color = Color(0, 0, 0, intensity)
 vignette.anchors_preset = 15
 vignette.anchor_right = 1.0
 vignette.anchor_bottom = 1.0
 vignette.grow_horizontal = 2
 vignette.grow_vertical = 2
 vignette.z_index = 998

 add_child(vignette)

func remove_vignette() -> void:
 for child in get_children():
  if child is ColorRect and child.z_index == 998:
   child.queue_free()

# === LIMPAR ===

func clear_all_effects() -> void:
 for child in get_children():
  if child is ColorRect:
   child.queue_free()

 Engine.time_scale = 1.0
 is_shaking = false
 is_slow_motion = false
