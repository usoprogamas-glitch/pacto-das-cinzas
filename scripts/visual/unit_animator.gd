class_name UnitAnimator
extends Node

# Sistema de animaÃ§Ã£o para unidades
# - Idle (respiraÃ§Ã£o)
# - Walk (movimento)
# - Attack (golpe)
# - Hit (dano)
# - Death (morte)
# - Cast (magia)

var unit: Node2D
var sprite: Sprite2D
var current_animation: String = "idle"
var animation_speed: float = 1.0

func _ready() -> void:
 pass

func setup(unit_ref: Node2D) -> void:
 unit = unit_ref
 sprite = _find_sprite(unit_ref)

func _find_sprite(unit_ref: Node2D) -> Sprite2D:
 # O sprite Ã© adicionado via add_child sem nome explÃ­cito â†’ Godot nomeia
 # "@Sprite2D@N" e has_node("Sprite2D") NUNCA casava (idle/hit/cast mortos).
 if unit_ref == null:
  return null
 if unit_ref is Sprite2D:
  return unit_ref
 if unit_ref.has_node("Sprite2D"):
  return unit_ref.get_node("Sprite2D") as Sprite2D
 for child in unit_ref.get_children():
  if child is Sprite2D:
   return child
 return null

func play_idle() -> void:
 current_animation = "idle"
 if not sprite:
  return

 # RespiraÃ§Ã£o sutil: squash & stretch RELATIVO Ã  escala real do sprite.
 # Sprites HD normalizados chegam com scale ~0.03 (1024px â†’ 32px): animar
 # para escala absoluta 1.0/1.02 os explodia em tela.
 var base_scale := sprite.scale
 var tween = create_tween()
 tween.set_loops()
 tween.tween_property(sprite, "scale", base_scale * Vector2(1.0, 1.06), 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
 tween.tween_property(sprite, "scale", base_scale, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func play_walk(target_position: Vector2) -> void:
 current_animation = "walk"
 if not unit:
  return

 # AnimaÃ§Ã£o de caminhada
 var tween = create_tween()
 var distance = unit.position.distance_to(target_position)
 var duration = distance / 200.0 # Velocidade de movimento

 # Passos
 var steps = int(distance / 16)
 for i in range(steps):
  var offset = Vector2(0, sin(i * PI) * 3)
  tween.tween_property(unit, "position", unit.position + offset, duration / steps)

 await tween.finished

func play_attack(target: Node2D) -> void:
 current_animation = "attack"
 if not unit or not target:
  return

 # AnimaÃ§Ã£o de ataque
 var original_position = unit.position
 var attack_direction = (target.position - unit.position).normalized()
 var attack_position = unit.position + attack_direction * 20

 var tween = create_tween()

 # AvanÃ§o rÃ¡pido
 tween.tween_property(unit, "position", attack_position, 0.1).set_ease(Tween.EASE_OUT)

 # Pausa no impacto
 tween.tween_interval(0.05)

 # Retorno
 tween.tween_property(unit, "position", original_position, 0.15).set_ease(Tween.EASE_IN_OUT)

 await tween.finished

func play_magic_cast() -> void:
 current_animation = "cast"
 if not sprite:
  return

 # AnimaÃ§Ã£o de conjuraÃ§Ã£o
 var tween = create_tween()

 # Levantar
 tween.tween_property(sprite, "position:y", sprite.position.y - 5, 0.2)

 # Brilhar
 tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 2.0), 0.3)

 # Flash
 tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

 # Descer
 tween.tween_property(sprite, "position:y", sprite.position.y + 5, 0.2)

 await tween.finished

func play_hit() -> void:
 current_animation = "hit"
 if not sprite:
  return

 # AnimaÃ§Ã£o de dano
 var original_position = sprite.position
 var original_modulate = sprite.modulate

 var tween = create_tween()

 # Flash vermelho
 tween.tween_property(sprite, "modulate", Color(2, 0.5, 0.5), 0.05)

 # Knockback
 var knockback = Vector2(randf_range(-5, 5), randf_range(-3, 3))
 tween.tween_property(sprite, "position", original_position + knockback, 0.05)

 # Retorno
 tween.tween_property(sprite, "position", original_position, 0.1)
 tween.tween_property(sprite, "modulate", original_modulate, 0.1)

 await tween.finished

func play_death() -> void:
 current_animation = "death"
 if not sprite:
  return

 # AnimaÃ§Ã£o de morte
 var base_scale := sprite.scale
 var tween = create_tween()

 # Encolher
 tween.tween_property(sprite, "scale", base_scale * Vector2(0.5, 0.5), 0.2)

 # Desaparecer
 tween.tween_property(sprite, "modulate:a", 0.0, 0.3)

 # Espinhar
 tween.tween_property(sprite, "rotation", deg_to_rad(90), 0.3)

 await tween.finished

func play_evolution() -> void:
 current_animation = "evolution"
 if not sprite:
  return

 # AnimaÃ§Ã£o de evoluÃ§Ã£o (relativa Ã  escala base â€” ver play_idle)
 var base_scale := sprite.scale
 var tween = create_tween()

 # Crescer
 tween.tween_property(sprite, "scale", base_scale * Vector2(1.5, 1.5), 0.3)

 # Brilhar
 tween.tween_property(sprite, "modulate", Color(2, 2, 2), 0.3)

 # Flash
 tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 2), 0.2)

 # Normalizar
 tween.tween_property(sprite, "scale", base_scale, 0.3)
 tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

 await tween.finished

func play_victory() -> void:
 current_animation = "victory"
 if not sprite:
  return

 # AnimaÃ§Ã£o de vitÃ³ria
 var tween = create_tween()
 tween.set_loops(3)

 # Pular
 tween.tween_property(sprite, "position:y", sprite.position.y - 10, 0.15)
 tween.tween_property(sprite, "position:y", sprite.position.y, 0.15)

 await tween.finished

func play_defeat() -> void:
 current_animation = "defeat"
 if not sprite:
  return

 # AnimaÃ§Ã£o de derrota
 var tween = create_tween()

 # Encher
 tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5), 0.5)

 # Balancear
 tween.tween_property(sprite, "rotation", deg_to_rad(-10), 0.2)
 tween.tween_property(sprite, "rotation", deg_to_rad(10), 0.2)
 tween.tween_property(sprite, "rotation", deg_to_rad(0), 0.2)

 await tween.finished

func stop_animation() -> void:
 if unit:
  var tweens = unit.get_tree().get_processed_tweens()
  for tween in tweens:
   if tween.is_valid():
    tween.kill()

 current_animation = "idle"

func get_current_animation() -> String:
 return current_animation
