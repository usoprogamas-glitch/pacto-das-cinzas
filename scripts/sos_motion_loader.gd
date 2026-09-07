class_name SOSMotionLoader
extends RefCounted

## Carrega sprites decodificados do SoS (uso pessoal/estudo, NÃO commitados):
## assets/sos_clean/<Char>/<Char>_<Acao>_D<dir>_F<frame>.png (cores reais via
## paleta; ver tools/sos_decode_frames.py). D1=Sul, D2=SO, D3=Oeste, D4=Norte, D5=Leste.

const WALK_FPS := 8.0
const IDLE_FPS := 3.0


## Carrega os frames de uma ação/direção. retorna [] se não houver.
static func load_action_frames(character: String, action: String, dir: int) -> Array:
 var folder := "res://assets/sos_clean/%s" % character
 var frames := []
 for i in range(16):
  var path := "%s/%s_%s_D%d_F%02d.png" % [folder, character, action, dir, i]
  if ResourceLoader.exists(path):
   frames.append(load(path))
  elif i > 0 and frames.size() > 0:
   break  # sequência encerrou
 return frames


## Motion sets para o UnitAnimator: {"idle": [Tex], "walk": [Tex]} na direção.
static func build_motion_sets(character: String, facing_dir: int = 1) -> Dictionary:
 if not DirAccess.dir_exists_absolute("res://assets/sos_clean/%s" % character):
  return {}
 var sets := {}
 var idle := load_action_frames(character, "Idle", facing_dir)
 var walk := load_action_frames(character, "Walk", facing_dir)
 if not idle.is_empty():
  sets["idle"] = idle
 if not walk.is_empty():
  sets["walk"] = walk
 return sets


## Sets de COMBATE do SoS real (réplica da convenção <Char>_<Anim>_D<dir>_F<NN>):
## tenta nomes de ação alternativos por estágio. Vazio se o personagem não
## tiver os frames — caller cai no gerador por bandas (SpriteMotionLibrary).
static func build_combat_sets(character: String, facing_dir: int = 1) -> Dictionary:
 if not DirAccess.dir_exists_absolute("res://assets/sos_clean/%s" % character):
  return {}
 var candidates := {
  "attack": ["Attack", "Attack1", "Combat", "Slash"],
  "cast": ["Cast", "CastSpell", "Skill"],
  "hit": ["Hit", "Hurt", "Damaged"],
  "death": ["Death", "Die", "Dead"],
 }
 var sets := {}
 for anim in candidates:
  for action in candidates[anim]:
   var frames := load_action_frames(character, action, facing_dir)
   if not frames.is_empty():
    sets[anim] = frames
    break
 return sets


## Lista personagens disponíveis.
static func available_characters() -> Array:
 if DirAccess.dir_exists_absolute("res://assets/sos_clean"):
  return DirAccess.get_directories_at("res://assets/sos_clean")
 return []


## Imagem-fonte do personagem (frame idle D<dir>) para regenerar sets por bandas.
static func source_image(character: String, facing_dir: int = 1) -> Image:
 var path := "res://assets/sos_clean/%s/%s_Idle_D%d_F00.png" % [character, character, facing_dir]
 if not ResourceLoader.exists(path):
  return null
 var tex: Texture2D = load(path)
 var img: Image = tex.get_image()
 if img == null:
  return null
 if img.is_compressed():
  img.decompress()
 return img
