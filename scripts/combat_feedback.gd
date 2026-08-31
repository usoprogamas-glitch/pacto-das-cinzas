class_name CombatFeedback
extends Node2D

# Sistema de feedback visual para combate - QUALIDADE SEA OF STARS
# - Números de dano flutuantes com grades
# - Flash de dano com rim light
# - Partículas avançadas por elemento
# - Screen shake contextual
# - Slow motion em momentos chave
# - Efeitos de status visual
# - Critical hit cinemático

var is_shaking: bool = false
var is_slow_motion: bool = false

func show_damage_number_with_grade(position: Vector2, damage: int, grade: String) -> void:
 var grade_colors = {
  "PERFECT": Color("#FFD93D"),
  "GREAT": Color("#4CAF50"),
  "GOOD": Color("#2196F3"),
  "MISS": Color("#FF5252")
 }

 var label = Label.new()
 label.position = position + Vector2(randf_range(-15, 15), -30)
 label.z_index = 100
 label.text = "%s %d" % [grade, damage]
 label.add_theme_color_override("font_color", grade_colors.get(grade, Color.WHITE))
 label.add_theme_font_size_override("font_size", 22)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 80, 1.0).set_ease(Tween.EASE_OUT)
 tween.parallel().tween_property(label, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_BACK)
 tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.4)
 tween.tween_callback(label.queue_free)

func show_timed_hit_indicator(position: Vector2, grade: String) -> void:
 var grade_data = {
  "PERFECT": { "color": Color("#FFD93D"), "text": "PERFECT!", "scale": 1.8 },
  "GREAT": { "color": Color("#4CAF50"), "text": "GREAT!", "scale": 1.5 },
  "GOOD": { "color": Color("#2196F3"), "text": "GOOD!", "scale": 1.3 },
  "MISS": { "color": Color("#FF5252"), "text": "MISS...", "scale": 1.2 }
 }

 var data = grade_data.get(grade, grade_data["MISS"])
 
 var label = Label.new()
 label.position = position + Vector2(-40, -50)
 label.z_index = 100
 label.text = data.text
 label.add_theme_color_override("font_color", data.color)
 label.add_theme_font_size_override("font_size", 24)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 3)
 label.add_theme_constant_override("shadow_offset_y", 3)
 label.scale = Vector2(data.scale, data.scale)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 80, 0.8).set_ease(Tween.EASE_OUT)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.4)
 tween.tween_callback(label.queue_free)

func flash_unit(unit: Node2D, color: Color = Color.WHITE, duration: float = 0.1) -> void:
 if not unit:
  return

 var original_modulate = unit.modulate
 unit.modulate = color

 var tween = create_tween()
 tween.tween_property(unit, "modulate", original_modulate, duration).set_trans(Tween.TRANS_SINE)

func flash_unit_rim(unit: Node2D, color: Color = Color(1.0, 0.8, 0.4), duration: float = 0.15) -> void:
 if not unit:
  return

 var original = unit.modulate
 unit.modulate = color

 var tween = create_tween()
 tween.tween_property(unit, "modulate", original, duration).set_trans(Tween.TRANS_SINE)
 tween.parallel().tween_property(unit, "scale", Vector2(1.1, 1.1), duration/2).set_trans(Tween.TRANS_SINE)
 tween.tween_property(unit, "scale", Vector2(1.0, 1.0), duration/2).set_trans(Tween.TRANS_SINE)

func shake_screen(camera: Camera2D, intensity: float = 5.0, duration: float = 0.2, falloff: bool = true) -> void:
 if not camera or is_shaking:
  return

 is_shaking = true
 var original_position = camera.position
 var elapsed = 0.0

 while elapsed < duration:
  var progress = elapsed / duration
  var current_intensity = intensity * (1.0 - progress) if falloff else intensity
  var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * current_intensity
  camera.position = original_position + offset

  await get_tree().create_timer(0.016).timeout
  elapsed += 0.016

 camera.position = original_position
 is_shaking = false

func shake(intensity: float = 5.0, duration: float = 0.2, falloff: bool = true) -> void:
 # Screen shake usando a câmera atual da árvore
 var camera = get_viewport().get_camera_2d()
 if camera == null:
  return
 await shake_screen(camera, intensity, duration, falloff)

func shake_light() -> void:
 await shake(3.0, 0.15)

func shake_medium() -> void:
 await shake(6.0, 0.25)

func shake_heavy() -> void:
 await shake(10.0, 0.35)

func shake_critical() -> void:
 await shake(15.0, 0.5, false) # Sem falloff para crítico

# === SLOW MOTION ===

func slow_motion(scale: float = 0.25, duration: float = 0.4) -> void:
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

func hit_pause(duration: float = 0.08) -> void:
 slow_motion(0.1, duration)

# === PARTÍCULAS AVANÇADAS ===

func spawn_hit_particles(position: Vector2, color: Color = Color.WHITE, count: int = 12) -> void:
 for i in range(count):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = randf_range(0.2, 0.5)
  particle.position = position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
  particle.color = color
  particle.scale_amount_min = randf_range(2, 5)
  particle.scale_amount_max = randf_range(4, 8)

  var angle = randf() * TAU
  var speed = randf_range(60, 180)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.5

  particle.gravity = Vector2(0, 200)
  particle.damping_min = 0.9
  particle.damping_max = 0.95
  particle.spread = 0.5

  add_child(particle)

func spawn_critical_hit_particles(position: Vector2) -> void:
 # Partículas douradas para crítico
 for i in range(20):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = randf_range(0.5, 1.0)
  particle.position = position
  particle.color = Color("#FFD93D")
  particle.scale_amount_min = 4
  particle.scale_amount_max = 10

  var angle = (float(i) / 20.0) * TAU + randf_range(-0.2, 0.2)
  var speed = randf_range(80, 200)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.3

  particle.gravity = Vector2(0, 50)
  particle.damping_min = 0.92
  particle.damping_max = 0.97

  add_child(particle)

func spawn_elemental_particles(position: Vector2, element: String, intensity: float = 1.0) -> void:
 var colors = {
  "fire": { "main": Color("#FF6B35"), "secondary": Color("#FFD700"), "tertiary": Color("#FF4500") },
  "water": { "main": Color("#00BCD4"), "secondary": Color("#4DD0E1"), "tertiary": Color("#0097A7") },
  "earth": { "main": Color("#8BC34A"), "secondary": Color("#A5D6A7"), "tertiary": Color("#689F38") },
  "air": { "main": Color("#E0F7FA"), "secondary": Color("#B2EBF2"), "tertiary": Color("#80DEEA") },
  "shadow": { "main": Color("#9C27B0"), "secondary": Color("#BA68C8"), "tertiary": Color("#7B1FA2") },
  "light": { "main": Color("#FFEB3B"), "secondary": Color("#FFEE58"), "tertiary": Color("#FFF9C4") },
  "ice": { "main": Color("#80DEEA"), "secondary": Color("#B2EBF2"), "tertiary": Color("#00BCD4") },
  "lightning": { "main": Color("#FFD600"), "secondary": Color("#FFF176"), "tertiary": Color("#FFEA00") },
  "blood": { "main": Color("#B71C1C"), "secondary": Color("#EF5350"), "tertiary": Color("#EF9A9A") }
 }

 var palette = colors.get(element, { "main": Color.WHITE, "secondary": Color.WHITE, "tertiary": Color.WHITE })

 for i in range(int(15 * intensity)):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = randf_range(0.4, 1.0)
  particle.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
  
  var color_choice = randf()
  if color_choice < 0.5:
   particle.color = palette["main"]
  elif color_choice < 0.8:
   particle.color = palette["secondary"]
  else:
   particle.color = palette["tertiary"]
  
  particle.scale_amount_min = randf_range(2, 5)
  particle.scale_amount_max = randf_range(4, 8)

  var angle = randf() * TAU
  var speed = randf_range(40, 120)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.5

  particle.gravity = Vector2(0, randf_range(-50, 100))
  particle.damping_min = 0.9
  particle.damping_max = 0.98

  add_child(particle)

func spawn_heal_particles(position: Vector2, amount: int = 15) -> void:
 for i in range(amount):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = randf_range(0.6, 1.2)
  particle.position = position + Vector2(randf_range(-15, 15), randf_range(-10, 0))
  particle.color = Color("#76FF03")
  particle.scale_amount_min = 3
  particle.scale_amount_max = 8

  particle.direction = Vector2(randf_range(-0.3, 0.3), -1)
  particle.initial_velocity_min = 20
  particle.initial_velocity_max = 50

  particle.gravity = Vector2(0, -30)
  particle.damping_min = 0.95
  particle.damping_max = 0.99

  add_child(particle)

func spawn_level_up_effect(position: Vector2) -> void:
 for i in range(30):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = 1.2
  particle.position = position
  particle.color = Color("#FFD93D")
  particle.scale_amount_min = 4
  particle.scale_amount_max = 12

  var angle = (float(i) / 30.0) * TAU + randf_range(-0.1, 0.1)
  var speed = randf_range(100, 200)
  particle.direction = Vector2(cos(angle), sin(angle))
  particle.initial_velocity_min = speed
  particle.initial_velocity_max = speed * 1.2

  particle.gravity = Vector2(0, 50)
  particle.damping_min = 0.9
  particle.damping_max = 0.95

  add_child(particle)

  await get_tree().create_timer(0.03).timeout

func spawn_status_effect_particles(position: Vector2, effect: String) -> void:
 var colors = {
  "burning": Color("#FF6B35"),
  "frozen": Color("#00BCD4"),
  "poisoned": Color("#9C27B0"),
  "stunned": Color("#FFEB3B"),
  "healing": Color("#76FF03"),
  "shielded": Color("#4FC3F7"),
  "cursed": Color("#9C27B0"),
  "blessed": Color("#FFD93D"),
  "bleeding": Color("#B71C1C"),
  "regenerating": Color("#4CAF50")
 }

 var color = colors.get(effect.to_lower(), Color.WHITE)
 
 for i in range(12):
  var particle = CPUParticles2D.new()
  particle.emitting = true
  particle.one_shot = true
  particle.amount = 1
  particle.lifetime = randf_range(0.5, 1.0)
  particle.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
  particle.color = color
  particle.scale_amount_min = 4
  particle.scale_amount_max = 8
  
  particle.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
  particle.initial_velocity_min = 30
  particle.initial_velocity_max = 80
  
  particle.gravity = Vector2(0, -30)
  
  add_child(particle)

# === DAMAGE NUMBERS COM GRADES ===

func show_damage_number(position: Vector2, damage: int, is_critical: bool = false, is_heal: bool = false, grade: String = "") -> void:
 var label = Label.new()
 label.position = position + Vector2(randf_range(-12, 12), -20)
 label.z_index = 100

 var text = ""
 var color = Color.WHITE
 var size = 18

 if is_heal:
  text = "+%d" % damage
  color = Color("#76FF03")
  size = 20
 elif is_critical:
  text = "%d!" % damage
  color = Color("#FFD93D")
  size = 28
 elif grade != "":
  var grade_colors = {
   "PERFECT": Color("#FFD93D"),
   "GREAT": Color("#4CAF50"),
   "GOOD": Color("#2196F3"),
   "MISS": Color("#FF5252")
  }
  text = "%s %d" % [grade, damage]
  color = { "PERFECT": Color("#FFD93D"), "GREAT": Color("#4CAF50"), "GOOD": Color("#2196F3"), "MISS": Color("#FF5252") }.get(grade, Color.WHITE)
  size = 22
 else:
  text = str(damage)
  color = Color("#FF5252")
  size = 18

 label.text = text
 label.add_theme_color_override("font_color", color)
 label.add_theme_font_size_override("font_size", size)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 60, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
 tween.parallel().tween_property(label, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_ELASTIC)
 tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
 tween.tween_callback(label.queue_free)

# === STATUS EFFECTS ===

func show_status_effect(position: Vector2, effect_name: String) -> void:
 var colors = {
  "burning": Color("#FF6B35"),
  "frozen": Color("#00BCD4"),
  "poisoned": Color("#9C27B0"),
  "stunned": Color("#FFEB3B"),
  "healing": Color("#76FF03"),
  "shielded": Color("#4FC3F7"),
  "cursed": Color("#9C27B0"),
  "blessed": Color("#FFD93D"),
  "bleeding": Color("#B71C1C"),
  "regenerating": Color("#4CAF50"),
  "silenced": Color("#757575"),
  "blind": Color("#607D8B"),
  "charmed": Color("#EC407A"),
  "feared": Color("#6A1B9A")
 }

 var label = Label.new()
 label.position = position + Vector2(-30, -40)
 label.z_index = 100
 label.text = effect_name.to_upper()
 label.add_theme_color_override("font_color", colors.get(effect_name.to_lower(), Color.WHITE))
 label.add_theme_font_size_override("font_size", 12)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 1)
 label.add_theme_constant_override("shadow_offset_y", 1)

 add_child(label)

 var tween = create_tween()
 tween.tween_property(label, "position:y", position.y - 60, 0.6)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
 tween.tween_callback(label.queue_free)

# === SCREEN EFFECTS ===

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

func flash_gold() -> void:
 await flash_screen(Color(1, 0.85, 0, 0.5), 0.15)

func flash_blue() -> void:
 await flash_screen(Color(0, 0.5, 1, 0.3), 0.2)

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

# === LIMPEZA ===

func cleanup() -> void:
 for child in get_children():
  if child is CPUParticles2D or child is Label or child is ColorRect:
   child.queue_free()

 Engine.time_scale = 1.0
 is_shaking = false
 is_slow_motion = false