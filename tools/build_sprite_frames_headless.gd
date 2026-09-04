# =============================================================
# build_sprite_frames_headless.gd — "O Pacto das Cinzas"
# =============================================================
# Versão para linha de comando (sem abrir o editor):
#
#   godot --path "<projeto>" --headless --script res://tools/build_sprite_frames_headless.gd
#
# Gera os mesmos SpriteFrames .tres do EditorScript, salvando em
# res://assets/animations/<Prefixo>.tres
# =============================================================
extends SceneTree

const FPS_POR_ACAO := {
	"walk": 8.0,
	"idle": 6.0,
	"idlecombat": 6.0,
	"pantingidle": 6.0,
	"crouchedidle": 6.0,
	"busheyesidle": 6.0,
	"busheyescombatidle": 6.0,
	"attack": 14.0,
}
const DEFAULT_FPS := 10.0
const PASTA_SPRITES := "res://assets/sprites"
const PASTA_SAIDA := "res://assets/animations"

var _re := RegEx.new()


func _initialize() -> void:
	_re.compile("^(?<prefix>.+)_D(?<dir>\\d+)_F(?<frame>\\d+)$")

	var raiz := DirAccess.open(PASTA_SPRITES)
	if raiz == null:
		printerr("[build] Pasta nao encontrada: %s" % PASTA_SPRITES)
		quit(1)
		return

	var gerados := 0
	raiz.list_dir_begin()
	var pasta := raiz.get_next()
	while pasta != "":
		if raiz.current_is_dir() and not pasta.begins_with("."):
			if _processar(pasta):
				gerados += 1
		pasta = raiz.get_next()
	raiz.list_dir_end()

	print("[build] Concluido: %d conjunto(s). Saida: %s" % [gerados, PASTA_SAIDA])
	quit(0)


func _processar(personagem: String) -> bool:
	var pasta := PASTA_SPRITES + "/" + personagem
	var dir := DirAccess.open(pasta)
	if dir == null:
		return false

	var grupos := {}
	dir.list_dir_begin()
	var arquivo := dir.get_next()
	while arquivo != "":
		if not dir.current_is_dir() and arquivo.to_lower().ends_with(".png"):
			var m := _re.search(arquivo.get_basename())
			if m != null:
				var prefixo := m.get_string("prefix")
				var anim := "%s_d%s" % [_acao(personagem, prefixo).to_lower(), m.get_string("dir")]
				var frame := int(m.get_string("frame"))
				if not grupos.has(prefixo):
					grupos[prefixo] = {}
				if not grupos[prefixo].has(anim):
					grupos[prefixo][anim] = {}
				grupos[prefixo][anim][frame] = pasta + "/" + arquivo
		arquivo = dir.get_next()
	dir.list_dir_end()

	if grupos.is_empty():
		return false

	for prefixo in grupos.keys():
		var frames := SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		var total := 0
		for anim in grupos[prefixo].keys():
			var acao := String(anim).split("_d")[0]
			frames.add_animation(anim)
			frames.set_animation_speed(anim, FPS_POR_ACAO.get(acao, DEFAULT_FPS))
			frames.set_animation_loop(anim, acao.contains("idle") or acao.contains("walk"))
			var nums := grupos[prefixo][anim].keys()
			nums.sort()
			for n in nums:
				var tex: Texture2D = load(grupos[prefixo][anim][n])
				if tex != null:
					frames.add_frame(anim, tex)
					total += 1

		DirAccess.make_dir_recursive_absolute(PASTA_SAIDA)
		var caminho := "%s/%s.tres" % [PASTA_SAIDA, prefixo.replace(" ", "_")]
		var erro := ResourceSaver.save(frames, caminho)
		if erro == OK:
			print("  [ok] %s (%d animacoes, %d frames)" % [caminho, grupos[prefixo].size(), total])
		else:
			printerr("  [erro] %s: %d" % [caminho, erro])
	return true


func _acao(personagem: String, prefixo: String) -> String:
	if prefixo.begins_with(personagem + "_"):
		return prefixo.substr(personagem.length() + 1)
	return prefixo
