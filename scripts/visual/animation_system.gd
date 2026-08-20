class_name AnimationSystem
extends Node

# Sistema de Animação Frame-a-Frame estilo Sea of Stars
# - Spritesheets organizados por ação
# - Interpolação suave entre frames
# - Eventos de animação (hitboxes, partículas, sons)
# - Blending entre animações
# - Cancelamento de animações

enum AnimationState {
 IDLE,
 WALK,
 RUN,
 ATTACK_LIGHT,
 ATTACK_HEAVY,
 ATTACK_AERIAL,
 CAST,
 HIT,
 DEATH,
 VICTORY,
 DEFEAT,
 INTERACT,
 CLIMB,
 SWIM
}

enum AnimationPriority {
 LOW = 0,      # Idle, walk
 MEDIUM = 1,   # Run, interact
 HIGH = 2,     # Attack, cast
 CRITICAL = 3  # Hit, death, stun
}

class AnimationData:
 var frames: Array[Texture2D] = []
 var frame_duration: float = 0.1
 var loop: bool = true
 var priority: int = 0
 var events: Dictionary = {}  # frame_idx -> event_data
 var hitboxes: Dictionary = {}  # frame_idx -> hitbox_data
 var root_motion: Dictionary = {}  # frame_idx -> velocity

var current_animation: String = "idle"
var current_frame: int = 0
var frame_timer: float = 0.0
var is_playing: bool = false
var animation_queue: Array[String] = []
var blend_time: float = 0.1

var sprite: Sprite2D
var animations: Dictionary = {}
var current_anim_data: AnimationData
var frame_timer: float = 0.0
var current_frame: int = 0
var is_playing: bool = false
var current_priority: int = 0
var blend_timer: float = 0.0
var blend_from: AnimationData
var blend_to: AnimationData
var blend_progress: float = 0.0

signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)
signal animation_event(event_name: String, data: Dictionary)
signal hitbox_activated(hitbox_data: Dictionary)
signal animation_changed(old_anim: String, new_anim: String)

func _ready() -> void:
 pass

func setup(sprite_node: Sprite2D) -> void:
 sprite = sprite_node
 build_animations()

func build_animations() -> void:
 # === KAEL (IMP MENOR) ===
 animations["kael_imp_idle"] = create_anim_data("kael_imp", "idle", 6, 0.12, true, AnimationPriority.LOW)
 animations["kael_imp_walk"] = create_anim_data("kael_imp", "walk", 8, 0.08, true, AnimationPriority.MEDIUM)
 animations["kael_imp_run"] = create_anim_data("kael_imp", "run", 8, 0.06, true, AnimationPriority.MEDIUM)
 animations["kael_imp_attack_light"] = create_attack_anim("kael_imp", "attack_light", 6, 0.05, [
  {"frame": 2, "type": "hitbox", "data": {"damage": 15, "knockback": 200, "angle": -45}},
  {"frame": 3, "type": "sound", "data": {"sound": "swing_light"}},
  {"frame": 4, "type": "particle", "data": {"effect": "slash", "color": "#FF6B35"}}
 ], AnimationPriority.HIGH)
 animations["kael_imp_attack_heavy"] = create_attack_anim("kael_imp", "attack_heavy", 10, 0.06, [
  {"frame": 3, "type": "hitbox", "data": {"damage": 35, "knockback": 400, "angle": -30, "stun": 0.5}},
  {"frame": 4, "type": "sound", "data": {"sound": "swing_heavy"}},
  {"frame": 5, "type": "particle", "data": {"effect": "impact_heavy", "color": "#FF6B35"}},
  {"frame": 6, "type": "screen_shake", "data": {"intensity": 8, "duration": 0.2}}
 ], AnimationPriority.HIGH)
 animations["kael_imp_cast"] = create_cast_anim("kael_imp", "cast", 10, 0.08, [
  {"frame": 2, "type": "particle", "data": {"effect": "magic_charge", "color": "#00FF88"}},
  {"frame": 5, "type": "sound", "data": {"sound": "magic_charge"}},
  {"frame": 8, "type": "hitbox", "data": {"damage": 40, "radius": 120, "element": "shadow"}}
 ], AnimationPriority.HIGH)
 animations["kael_imp_hit"] = create_hit_anim("kael_imp", "hit", 4, 0.05, [
  {"frame": 1, "type": "flash", "data": {"color": "#FF5252", "duration": 0.1}}
 ], AnimationPriority.CRITICAL)
 animations["kael_imp_death"] = create_death_anim("kael_imp", "death", 12, 0.07, [
  {"frame": 3, "type": "particle", "data": {"effect": "death_dissolve", "color": "#00FF88"}},
  {"frame": 6, "type": "sound", "data": {"sound": "death_imp"}},
  {"frame": 10, "type": "screen_shake", "data": {"intensity": 10, "duration": 0.5}}
 ], AnimationPriority.CRITICAL)
 animations["kael_imp_victory"] = create_victory_anim("kael_imp", "victory", 16, 0.08, true)

 # === KAEL NOBRE ABISSAL ===
 animations["kael_noble_idle"] = create_anim_data("kael_noble", "idle", 6, 0.15, true, AnimationPriority.LOW)
 animations["kael_noble_walk"] = create_anim_data("kael_noble", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["kael_noble_run"] = create_anim_data("kael_noble", "run", 8, 0.07, true, AnimationPriority.MEDIUM)
 animations["kael_noble_attack"] = create_attack_anim("kael_noble", "attack", 8, 0.06, [
  {"frame": 2, "type": "hitbox", "data": {"damage": 30, "knockback": 300, "angle": -45}},
  {"frame": 3, "type": "particle", "data": {"effect": "slash_dark", "color": "#00BFFF"}},
  {"frame": 4, "type": "sound", "data": {"sound": "slash_dark"}}
 ], AnimationPriority.HIGH)
 animations["kael_noble_cast"] = create_cast_anim("kael_noble", "cast", 12, 0.08, [
  {"frame": 3, "type": "particle", "data": {"effect": "dark_charge", "color": "#00BFFF"}},
  {"frame": 6, "type": "hitbox", "data": {"damage": 50, "radius": 150, "element": "shadow"}},
  {"frame": 10, "type": "screen_shake", "data": {"intensity": 6, "duration": 0.3}}
 ], AnimationPriority.HIGH)
 animations["kael_noble_dark_aura"] = create_aura_anim("kael_noble", "dark_aura", 8, 0.1, true)

 # === KAEL ARQUIDEMÔNIO ===
 animations["kael_arch_idle"] = create_anim_data("kael_arch", "idle", 4, 0.2, true, AnimationPriority.LOW)
 animations["kael_arch_hover"] = create_anim_data("kael_arch", "hover", 6, 0.12, true, AnimationPriority.MEDIUM)
 animations["kael_arch_attack"] = create_attack_anim("kael_arch", "attack", 8, 0.05, [
  {"frame": 1, "type": "hitbox", "data": {"damage": 50, "radius": 200, "knockback": 500}},
  {"frame": 2, "type": "particle", "data": {"effect": "void_explosion", "color": "#FF4444"}},
  {"frame": 2, "type": "screen_shake", "data": {"intensity": 12, "duration": 0.4}}
 ], AnimationPriority.HIGH)
 animations["kael_arch_void_strike"] = create_attack_anim("kael_arch", "void_strike", 12, 0.05, [
  {"frame": 3, "type": "hitbox", "data": {"damage": 80, "radius": 300, "void": true}},
  {"frame": 4, "type": "screen_shake", "data": {"intensity": 20, "duration": 0.8}},
  {"frame": 5, "type": "particle", "data": {"effect": "void_explosion", "color": "#8B008B"}}
 ], AnimationPriority.HIGH)
 animations["kael_arch_void_form"] = create_anim_data("kael_arch", "void_form", 8, 0.1, true, AnimationPriority.HIGH)

 # === KAEL AVATAR PRIMORDIAL ===
 animations["kael_avatar_idle"] = create_anim_data("kael_avatar", "idle", 4, 0.25, true, AnimationPriority.LOW)
 animations["kael_avatar_walk"] = create_anim_data("kael_avatar", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["kael_avatar_primordial_wrath"] = create_attack_anim("kael_avatar", "primordial_wrath", 20, 0.05, [
  {"frame": 5, "type": "hitbox", "data": {"damage": 200, "radius": 500, "reality_break": true}},
  {"frame": 10, "type": "screen_shake", "data": {"intensity": 30, "duration": 1.5}},
  {"frame": 10, "type": "particle", "data": {"effect": "reality_break", "color": "#FFD700"}},
  {"frame": 15, "type": "sound", "data": {"sound": "reality_break"}}
 ], AnimationPriority.CRITICAL)
 animations["kael_avatar_reality_warp"] = create_cast_anim("kael_avatar", "reality_warp", 15, 0.06, [
  {"frame": 5, "type": "hitbox", "data": {"damage": 100, "radius": 400, "reality_break": true}},
  {"frame": 10, "type": "particle", "data": {"effect": "reality_warp", "color": "#FFD700"}}
 ], AnimationPriority.CRITICAL)

 # === KROUG ===
 animations["kroug_idle"] = create_anim_data("kroug", "idle", 6, 0.15, true, AnimationPriority.LOW)
 animations["kroug_walk"] = create_anim_data("kroug", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["kroug_run"] = create_anim_data("kroug", "run", 8, 0.08, true, AnimationPriority.MEDIUM)
 animations["kroug_attack"] = create_attack_anim("kroug", "attack", 8, 0.06, [
  {"frame": 3, "type": "hitbox", "data": {"damage": 25, "knockback": 400, "stun": 0.3}},
  {"frame": 4, "type": "sound", "data": {"sound": "heavy_impact"}},
  {"frame": 4, "type": "particle", "data": {"effect": "earth_shock", "color": "#8B4513"}},
  {"frame": 4, "type": "screen_shake", "data": {"intensity": 8, "duration": 0.3}}
 ], AnimationPriority.HIGH)
 animations["kroug_war_cry"] = create_cast_anim("kroug", "war_cry", 12, 0.08, [
  {"frame": 3, "type": "particle", "data": {"effect": "war_cry", "color": "#FF4500"}},
  {"frame": 6, "type": "buff", "data": {"allies_atk": 1.3, "allies_def": 1.2, "duration": 10}},
  {"frame": 8, "type": "sound", "data": {"sound": "war_cry"}}
 ], AnimationPriority.HIGH)
 animations["kroug_shield_bash"] = create_attack_anim("kroug", "shield_bash", 8, 0.06, [
  {"frame": 2, "type": "hitbox", "data": {"damage": 20, "knockback": 500, "stun": 0.5}},
  {"frame": 3, "type": "sound", "data": {"sound": "shield_bash"}},
  {"frame": 3, "type": "particle", "data": {"effect": "shield_impact", "color": "#FF8800"}}
 ], AnimationPriority.HIGH)
 animations["kroug_hit"] = create_hit_anim("kroug", "hit", 4, 0.06, AnimationPriority.CRITICAL)
 animations["kroug_death"] = create_death_anim("kroug", "death", 14, 0.08, AnimationPriority.CRITICAL)

 # === LIRA ===
 animations["lira_idle"] = create_anim_data("lira", "idle", 6, 0.18, true, AnimationPriority.LOW)
 animations["lira_walk"] = create_anim_data("lira", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["lira_heal"] = create_cast_anim("lira", "heal", 10, 0.08, [
  {"frame": 3, "type": "particle", "data": {"effect": "heal_wave", "color": "#76FF03"}},
  {"frame": 5, "type": "heal", "data": {"amount": 50, "radius": 150}},
  {"frame": 7, "type": "sound", "data": {"sound": "heal_cast"}}
 ], AnimationPriority.HIGH)
 animations["lira_nature_wrath"] = create_attack_anim("lira", "nature_wrath", 14, 0.06, [
  {"frame": 5, "type": "hitbox", "data": {"damage": 40, "radius": 200, "root": 2.0}},
  {"frame": 8, "type": "particle", "data": {"effect": "nature_explosion", "color": "#2E8B57"}},
  {"frame": 10, "type": "screen_shake", "data": {"intensity": 8, "duration": 0.5}}
 ], AnimationPriority.HIGH)
 animations["lira_ent_form"] = create_anim_data("lira", "ent_form", 8, 0.15, true, AnimationPriority.HIGH)

 # === THAL'KOR ===
 animations["thalkor_idle"] = create_anim_data("thalkor", "idle", 4, 0.2, true, AnimationPriority.LOW)
 animations["thalkor_walk"] = create_anim_data("thalkor", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["thalkor_fly"] = create_anim_data("thalkor", "fly", 8, 0.08, true, AnimationPriority.MEDIUM)
 animations["thalkor_attack"] = create_attack_anim("thalkor", "attack", 6, 0.05, [
  {"frame": 2, "type": "hitbox", "data": {"damage": 35, "bleed": 5, "duration": 5}},
  {"frame": 3, "type": "sound", "data": {"sound": "blade_slash"}},
  {"frame": 3, "type": "particle", "data": {"effect": "blade_trail", "color": "#8B008B"}}
 ], AnimationPriority.HIGH)
 animations["thalkor_blind_strike"] = create_attack_anim("thalkor", "blind_strike", 10, 0.05, [
  {"frame": 3, "type": "hitbox", "data": {"damage": 50, "blind": 3.0, "silence": 2.0}},
  {"frame": 4, "type": "particle", "data": {"effect": "blind_flash", "color": "#FFFFFF"}},
  {"frame": 4, "type": "sound", "data": {"sound": "blind_strike"}}
 ], AnimationPriority.HIGH)
 animations["thalkor_shadow_step"] = create_anim_data("thalkor", "shadow_step", 6, 0.08, true, AnimationPriority.HIGH)
 animations["thalkor_hit"] = create_hit_anim("thalkor", "hit", 3, 0.05, AnimationPriority.CRITICAL)
 animations["thalkor_death"] = create_death_anim("thalkor", "death", 12, 0.07, AnimationPriority.CRITICAL)

 # === INIMIGOS ===
 # Mercenário
 animations["mercenario_idle"] = create_anim_data("mercenario", "idle", 4, 0.2, true, AnimationPriority.LOW)
 animations["mercenario_walk"] = create_anim_data("mercenario", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["mercenario_attack"] = create_attack_anim("mercenario", "attack", 6, 0.07, [
  {"frame": 2, "type": "hitbox", "data": {"damage": 15, "knockback": 150}},
  {"frame": 3, "type": "sound", "data": {"sound": "sword_swing"}}
 ], AnimationPriority.HIGH)
 animations["mercenario_hit"] = create_hit_anim("mercenario", "hit", 3, 0.05)
 animations["mercenario_death"] = create_death_anim("mercenario", "death", 8, 0.07)

 # Caçador
 animations["cacador_idle"] = create_anim_data("cacador", "idle", 4, 0.2, true, AnimationPriority.LOW)
 animations["cacador_walk"] = create_anim_data("cacador", "walk", 8, 0.1, true, AnimationPriority.MEDIUM)
 animations["cacador_shoot"] = create_attack_anim("cacador", "shoot", 8, 0.07, [
  {"frame": 3, "type": "projectile", "data": {"damage": 20, "speed": 500, "type": "arrow"}},
  {"frame": 4, "type": "sound", "data": {"sound": "bow_shoot"}}
 ], AnimationPriority.HIGH)

 # Inquisidor
 animations["inquisidor_idle"] = create_anim_data("inquisidor", "idle", 4, 0.2, true, AnimationPriority.LOW)
 animations["inquisidor_walk"] = create_anim_data("inquisidor", "walk", 6, 0.12, true, AnimationPriority.MEDIUM)
 animations["inquisidor_cast"] = create_cast_anim("inquisidor", "cast", 12, 0.08, [
  {"frame": 4, "type": "particle", "data": {"effect": "anti_magic", "color": "#9370DB"}},
  {"frame": 8, "type": "hitbox", "data": {"damage": 30, "radius": 180, "anti_magic": 3.0}},
  {"frame": 10, "type": "sound", "data": {"sound": "anti_magic"}}
 ], AnimationPriority.HIGH)

 # Paladino
 animations["paladino_idle"] = create_anim_data("paladino", "idle", 4, 0.2, true, AnimationPriority.LOW)
 animations["paladino_walk"] = create_anim_data("paladino", "walk", 6, 0.12, true, AnimationPriority.MEDIUM)
 animations["paladino_attack"] = create_attack_anim("paladino", "attack", 8, 0.07, [
  {"frame": 3, "type": "hitbox", "data": {"damage": 35, "knockback": 300, "holy": true}},
  {"frame": 4, "type": "particle", "data": {"effect": "holy_strike", "color": "#FFD700"}},
  {"frame": 4, "type": "sound", "data": {"sound": "holy_strike"}}
 ], AnimationPriority.HIGH)
 animations["paladino_shield"] = create_anim_data("paladino", "shield", 6, 0.1, true, AnimationPriority.HIGH)

 # Santo Cardeal
 animations["cardeal_idle"] = create_anim_data("cardeal", "idle", 4, 0.25, true, AnimationPriority.LOW)
 animations["cardeal_attack"] = create_attack_anim("cardeal", "attack", 12, 0.06, [
  {"frame": 4, "type": "hitbox", "data": {"damage": 60, "radius": 200, "holy": true, "stun": 1.0}},
  {"frame": 6, "type": "particle", "data": {"effect": "divine_wrath", "color": "#FFFFAA"}},
  {"frame": 8, "type": "screen_shake", "data": {"intensity": 12, "duration": 0.6}}
 ], AnimationPriority.CRITICAL)
 animations["cardeal_holy_nova"] = create_cast_anim("cardeal", "holy_nova", 16, 0.06, [
  {"frame": 6, "type": "hitbox", "data": {"damage": 80, "radius": 300, "holy": true, "purify": true}},
  {"frame": 10, "type": "particle", "data": {"effect": "holy_nova", "color": "#FFFFAA"}},
  {"frame": 12, "type": "screen_shake", "data": {"intensity": 15, "duration": 1.0}}
 ], AnimationPriority.CRITICAL)

 # Aurius (Boss Final)
 animations["aurius_idle"] = create_anim_data("aurius", "idle", 4, 0.3, true, AnimationPriority.LOW)
 animations["aurius_phase1_attack"] = create_attack_anim("aurius", "phase1_attack", 16, 0.06, [
  {"frame": 4, "type": "hitbox", "data": {"damage": 80, "radius": 200, "holy": true}},
  {"frame": 8, "type": "particle", "data": {"effect": "divine_slash", "color": "#FFFFAA"}},
  {"frame": 8, "type": "screen_shake", "data": {"intensity": 15, "duration": 0.5}}
 ], AnimationPriority.CRITICAL)
 animations["aurius_phase2_cast"] = create_cast_anim("aurius", "phase2_cast", 20, 0.05, [
  {"frame": 8, "type": "particle", "data": {"effect": "divine_judgment", "color": "#FFFFAA"}},
  {"frame": 12, "type": "hitbox", "data": {"damage": 100, "radius": 400, "holy": true, "judgment": true}},
  {"frame": 15, "type": "screen_shake", "data": {"intensity": 25, "duration": 1.5}}
 ], AnimationPriority.CRITICAL)
 animations["aurius_final_form"] = create_anim_data("aurius", "final_form", 8, 0.1, true, AnimationPriority.CRITICAL)
 animations["aurius_death"] = create_death_anim("aurius", "death", 30, 0.1, AnimationPriority.CRITICAL)

# === MESTRE ===
animations["master_idle"] = create_anim_data("master", "idle", 4, 0.2, true, AnimationPriority.LOW)
animations["master_teach"] = create_anim_data("master", "teach", 12, 0.08, true, AnimationPriority.LOW)
animations["master_combat"] = create_attack_anim("master", "combat", 16, 0.05, [
  {"frame": 4, "type": "hitbox", "data": {"damage": 100, "radius": 300, "true_damage": true}},
  {"frame": 8, "type": "screen_shake", "data": {"intensity": 20, "duration": 0.8}}
 ], AnimationPriority.CRITICAL)

func create_anim_data(character: String, action: String, frames: int, duration: float, loop: bool, priority: int) -> Dictionary:
 var frames = []
 for i in range(frames):
  frames.append("res://assets/sprites/%s/%s_%03d.png" % [character, action, i])
 
 return {
  "name": "%s_%s" % [character, action],
  "character": character,
  "action": action,
  "frames": frames,
  "frame_duration": 1.0 / frames if frames > 0 else 0.1,
  "loop": loop,
  "priority": priority,
  "events": {},
  "hitboxes": {},
  "root_motion": {}
 }

func create_attack_anim(character: String, name: String, frames: int, frame_dur: float, events: Array, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, false, priority)
 anim.frame_duration = 1.0 / frames
 
 # Adicionar eventos
 for event in events:
  var frame = event.frame
  if not anim.events.has(frame):
   anim.events[frame] = []
  anim.events[frame].append(event)
 
 # Hitbox padrão no frame de impacto
 if not anim.hitboxes.has(frames / 2):
  anim.hitboxes[frames / 2] = {
   "damage": 10,
   "knockback": 100,
   "angle": 0,
   "radius": 32
 }
 
 return anim

func create_cast_anim(character: String, name: String, frames: int, frame_dur: float, events: Array, priority: int) -> Dictionary:
 var anim = create_attack_anim(character, name, frames, 1.0/frames, events, priority)
 anim.frame_duration = 1.0 / frames
 return anim

func create_cast_anim(character: String, name: String, frames: int, frame_dur: float, events: Array, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, false, priority)
 
 for event in events:
  var frame = event.frame
  if not anim.events.has(frame):
   anim.events[frame] = []
  anim.events[frame].append(event)
 
 return anim

func create_hit_anim(character: String, name: String, frames: int, frame_dur: float, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, false, priority)
 anim.hitboxes[1] = {
  "damage": 0,
  "knockback": 200,
  "invulnerability": 0.5,
  "flash_color": Color("#FF5252")
 }
 return anim

func create_death_anim(character: String, name: String, frames: int, frame_dur: float, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, false, priority)
 
 anim.events[frames - 3] = [{"type": "particle", "data": {"effect": "death_dissolve"}}]
 anim.events[frames - 1] = [
  {"type": "sound", "data": {"sound": "death"}},
  {"type": "queue_free", "data": {}}
 ]
 
 return anim

func create_victory_anim(character: String, name: String, frames: int, frame_dur: float, loop: bool) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, loop, AnimationPriority.LOW)
 anim.events[frames / 2] = [{"type": "cheer", "data": {}}]
 return anim

func create_aura_anim(character: String, name: String, frames: int, frame_dur: float, loop: bool, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, loop, priority)
 anim.events[0] = [{"type": "aura_start", "data": {}}]
 return anim

func create_victory_anim(character: String, name: String, frames: int, frame_dur: float, loop: bool) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, loop, AnimationPriority.LOW)
 anim.events[frames - 1] = [{"type": "victory_pose", "data": {}}]
 return anim

func create_aura_anim(character: String, name: String, frames: int, frame_dur: float, loop: bool, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, loop, priority)
 anim.events[0] = [{"type": "aura_start", "data": {}}]
 return anim

func create_death_anim(character: String, name: String, frames: int, frame_dur: float, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, false, priority)
 
 anim.events[frames - 3] = [{"type": "particle", "data": {"effect": "death_dissolve"}}]
 anim.events[frames - 1] = [
  {"type": "sound", "data": {"sound": "death"}},
  {"type": "queue_free", "data": {}}
 ]
 
 return anim

func create_victory_anim(character: String, name: String, frames: int, frame_dur: float, loop: bool) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, loop, AnimationPriority.LOW)
 anim.events[frames - 1] = [{"type": "cheer", "data": {}}]
 return anim

func create_aura_anim(character: String, name: String, frames: int, frame_dur: float, loop: bool, priority: int) -> Dictionary:
 var anim = create_anim_data(character, name, frames, 1.0/frames, loop, priority)
 anim.events[0] = [{"type": "aura_start", "data": {}}]
 return anim