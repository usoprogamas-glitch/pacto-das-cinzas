class_name SOSMotionLoader
extends RefCounted

## Carrega sprites extraídos do SoS (uso pessoal/estudo, NÃO commitados —
## ver .gitignore) e monta motion_sets no formato que o UnitAnimator consome:
## {"idle": [Texture2D], "walk": [Texture2D]}.
## Estrutura esperada: res://assets/sos/<Personagem>/
##   <Personagem>_Idle_D<dir>_F<frame>.png
##   <Personagem>_Walk_D<dir>_F<frame>.png
## Direções SoS: D1=Sul, D3=Leste, D5=Norte (piloto usa 1/3/5).

const DIR_NAMES := {1: "d1", 2: "d2", 3: "d3", 4: "d4", 5: "d5"}
const WALK_FPS := 8.0
const IDLE_FPS := 3.0


## Retorna motion_sets se a pasta do personagem existir, senão {}.
static func build_motion_sets(character: String, facing_dir: int = 1) -> Dictionary:
	var dir_key: String = DIR_NAMES.get(facing_dir, "d3")
	var folder := "res://assets/sos/%s" % character
	if not DirAccess.dir_exists_absolute(folder):
		return {}
	var idle := []
	var walk := []
	for i in range(12):
		var idle_path := "%s/%s_Idle_%s_F%02d.png" % [folder, character, dir_key, i]
		if ResourceLoader.exists(idle_path):
			idle.append(load(idle_path))
		var walk_path := "%s/%s_Walk_%s_F%02d.png" % [folder, character, dir_key, i]
		if ResourceLoader.exists(walk_path):
			walk.append(load(walk_path))
	var sets := {}
	if not idle.is_empty():
		sets["idle"] = idle
	if not walk.is_empty():
		sets["walk"] = walk
	return sets


## Lista personagens disponíveis em res://assets/sos/.
static func available_characters() -> Array:
	var chars := []
	if DirAccess.dir_exists_absolute("res://assets/sos"):
		for dir_name in DirAccess.get_directories_at("res://assets/sos"):
			chars.append(dir_name)
	return chars
