class_name SeaOfStarsStyle
extends RefCounted

# Referências visuais do Sea of Stars:
# - Pixel art HD (32x32 ou 64x64)
# - Paleta de cores rica e vibrante
# - Iluminação dinâmica (dia/noite)
# - Animações fluidas e expressivas
# - Efeitos de partículas
# - Visual limpo e bem definido

# === PALETA DE CORES SEA OF STARS ===
static var palette: Dictionary = {
 # Personagens jogáveis
 "player_primary": "#4A6FA5",      # Azul profundo
 "player_secondary": "#7EB5D6",    # Azul claro
 "player_accent": "#FFD93D",       # Dourado
 "player_highlight": "#FFFFFF",    # Branco

 # Inimigos
 "enemy_primary": "#8B4513",       # Marrom escuro
 "enemy_secondary": "#CD853F",     # Marrom claro
 "enemy_accent": "#FF4444",        # Vermelho
 "enemy_highlight": "#FFAA00",     # Laranja

 # Terrenos
 "grass_light": "#5B8C3E",
 "grass_dark": "#3D6B2E",
 "dirt_light": "#8B7355",
 "dirt_dark": "#6B5340",
 "stone_light": "#7A7A8A",
 "stone_dark": "#5A5A6A",
 "water_light": "#4A9BD9",
 "water_dark": "#2A7BB9",

 # UI
 "ui_background": "#1A1A2E",
 "ui_panel": "#16213E",
 "ui_accent": "#FFD93D",
 "ui_text": "#FFFFFF",
 "ui_text_dim": "#AAAAAA",
 "ui_hp_bar": "#4CAF50",
 "ui_hp_lost": "#FF5252",
 "ui_mp_bar": "#2196F3",
 "ui_xp_bar": "#FFD93D",

 # Efeitos
 "effect_fire": "#FF6B35",
 "effect_water": "#00BCD4",
 "effect_earth": "#8BC34A",
 "effect_air": "#E0F7FA",
 "effect_shadow": "#9C27B0",
 "effect_light": "#FFEB3B",
 "effect_heal": "#76FF03",
 "effect_damage": "#FF1744"
}

# === FRAME DATA (60 FPS) ===
static var frame_data: Dictionary = {
 # Animações de personagens
 "idle": {
  "frames": 4,
  "speed": 8,  # FPS
  "loop": true
 },
 "walk": {
  "frames": 8,
  "speed": 12,
  "loop": true
 },
 "attack_melee": {
  "frames": 6,
  "speed": 18,
  "startup": 2,
  "active": 2,
  "recovery": 2
 },
 "attack_ranged": {
  "frames": 8,
  "speed": 15,
  "startup": 3,
  "active": 2,
  "recovery": 3
 },
 "cast_magic": {
  "frames": 10,
  "speed": 12,
  "startup": 4,
  "active": 3,
  "recovery": 3
 },
 "hurt": {
  "frames": 4,
  "speed": 20,
  "loop": false
 },
 "death": {
  "frames": 8,
  "speed": 10,
  "loop": false
 }
}

# === TIMED HIT WINDOWS ===
static var timed_hit: Dictionary = {
 "perfect": {
  "window": 0.1,  # 100ms
  "bonus": 1.5,   # 50% mais dano
  "color": "#FFD93D"
 },
 "great": {
  "window": 0.2,  # 200ms
  "bonus": 1.25,  # 25% mais dano
  "color": "#4CAF50"
 },
 "good": {
  "window": 0.3,  # 300ms
  "bonus": 1.1,   # 10% mais dano
  "color": "#2196F3"
 },
 "miss": {
  "window": 0.0,
  "bonus": 0.5,   # 50% menos dano
  "color": "#FF5252"
 }
}

# === PARÂMETROS DE ILUMINAÇÃO ===
static var lighting: Dictionary = {
 "ambient_day": Color(1.0, 1.0, 0.95),
 "ambient_night": Color(0.4, 0.4, 0.6),
 "shadow_strength": 0.3,
 "highlight_strength": 0.2,
 "rim_light_intensity": 0.4
}

# === CONFIGURAÇÕES DE PIXEL ART ===
static var pixel_art: Dictionary = {
 "tile_size": 32,
 "character_size": 32,
 "sprite_scale": 1.0,
 "outline_width": 1,
 "outline_color": "#000000",
 "dithering": false,
 "anti_aliasing": false
}

# === EFEITOS VISUAIS ===
static var effects: Dictionary = {
 "hit_spark": {
  "particles": 8,
  "lifetime": 0.3,
  "color": "#FFFFFF",
  "size": 4
 },
 "magic_cast": {
  "particles": 16,
  "lifetime": 0.5,
  "color": "#FFD93D",
  "size": 6,
  "trail": true
 },
 "heal": {
  "particles": 12,
  "lifetime": 0.8,
  "color": "#76FF03",
  "size": 8,
  "rise": true
 },
 "level_up": {
  "particles": 32,
  "lifetime": 1.0,
  "color": "#FFD93D",
  "size": 10,
  "burst": true
 }
}

static func get_character_colors(is_player: bool) -> Dictionary:
 if is_player:
  return {
   "primary": palette.player_primary,
   "secondary": palette.player_secondary,
   "accent": palette.player_accent,
   "highlight": palette.player_highlight
  }
 else:
  return {
   "primary": palette.enemy_primary,
   "secondary": palette.enemy_secondary,
   "accent": palette.enemy_accent,
   "highlight": palette.enemy_highlight
  }

static func get_element_color(element: String) -> Color:
 match element:
  "fire": return Color(palette.effect_fire)
  "water": return Color(palette.effect_water)
  "earth": return Color(palette.effect_earth)
  "air": return Color(palette.effect_air)
  "shadow": return Color(palette.effect_shadow)
  "light": return Color(palette.effect_light)
  "heal": return Color(palette.effect_heal)
  _: return Color.WHITE

static func calculate_timed_hit_bonus(timing: float) -> Dictionary:
 if timing <= timed_hit.perfect.window:
  return {"grade": "PERFECT", "bonus": timed_hit.perfect.bonus, "color": timed_hit.perfect.color}
 elif timing <= timed_hit.great.window:
  return {"grade": "GREAT", "bonus": timed_hit.great.bonus, "color": timed_hit.great.color}
 elif timing <= timed_hit.good.window:
  return {"grade": "GOOD", "bonus": timed_hit.good.bonus, "color": timed_hit.good.color}
 else:
  return {"grade": "MISS", "bonus": timed_hit.miss.bonus, "color": timed_hit.miss.color}
