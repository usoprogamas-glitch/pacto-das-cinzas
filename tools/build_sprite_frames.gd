@tool
# =============================================================
# build_sprite_frames.gd — "O Pacto das Cinzas"
# =============================================================
# Gera recursos SpriteFrames (.tres) a partir de sprites extraídos
# do Sea of Stars, usando a convenção de nomes:
#
#     Personagem_Acao_Direcao_Frame.png
#     ex: FeralQueenValere_Walk_D3_F05.png
#         -> personagem: FeralQueenValere | ação: Walk | direção: D3 | frame: 05
#
# COMO USAR (no editor Godot):
#   1. Coloque os sprites em  res://assets/sprites/<Personagem>/*.png
#   2. Abra este script no editor (guia Script)
#   3. Arquivo > Executar  (Ctrl+Shift+X)
#   4. Os .tres aparecem em  res://assets/animations/<Personagem>.tres
#
# Re-executável a qualquer momento (sobrescreve os .tres gerados).
# =============================================================
extends EditorScript

# FPS por ação (prefixo em minúsculas). Ações fora da lista usam DEFAULT_FPS.
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
# Ações em loop (contêm "idle" ou "walk" => loop automático)
const PASTA_SPRITES := "res://assets/sprites"
const PASTA_SAIDA := "res://assets/animations"

# Regex de nome: captura prefixo, direção e frame
var _re := RegEx.new()


func _run() -> void:
	_re.compile("^(?<prefix>.+)_D(?<dir>\\d+)_F(?<frame>\\d+)$")

	var raiz := DirAccess.open(PASTA_SPRITES)
	if raiz == null:
		printerr("[build_sprite_frames] Pasta nao encontrada: %s (crie e coloque os sprites la)" % PASTA_SPRITES)
		return

	var gerados := 0
	raiz.list_dir_begin()
	var pasta_personagem := raiz.get_next()
	while pasta_personagem != "":
		if raiz.current_is_dir() and not pasta_personagem.begins_with("."):
			if _processar_personagem(pasta_personagem):
				gerados += 1
		pasta_personagem = raiz.get_next()
	raiz.list_dir_end()

	print("[build_sprite_frames] Concluido: %d personagem(ns) processado(s). Saida: %s" % [gerados, PASTA_SAIDA])


func _processar_personagem(personagem: String) -> bool:
	var pasta := PASTA_SPRITES + "/" + personagem
	var dir := DirAccess.open(pasta)
	if dir == null:
		return false

	# agrupa: prefixo -> {chave_anim -> {frame:int -> caminho}}
	var grupos := {}
	var sem_convencao: Array[String] = []

	dir.list_dir_begin()
	var arquivo := dir.get_next()
	while arquivo != "":
		if not dir.current_is_dir() and arquivo.to_lower().ends_with(".png"):
			var nome := arquivo.get_basename()
			var m := _re.search(nome)
			if m == null:
				sem_convencao.append(arquivo)
			else:
				var prefixo := m.get_string("prefix")
				var direcao := m.get_string("dir")
				var frame := int(m.get_string("frame"))
				var acao := _acao_de(personagem, prefixo)
				var anim := "%s_d%s" % [acao.to_lower(), direcao]
				if not grupos.has(prefixo):
					grupos[prefixo] = {}
				if not grupos[prefixo].has(anim):
					grupos[prefixo][anim] = {}
				grupos[prefixo][anim][frame] = pasta + "/" + arquivo
		arquivo = dir.get_next()
	dir.list_dir_end()

	if grupos.is_empty():
		if sem_convencao.size() > 0:
			print("[aviso] %s: %d arquivo(s) fora da convensao _D#_F## (ignorados)" % [personagem, sem_convencao.size()])
		return false

	for prefixo in grupos.keys():
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for anim in grupos[prefixo].keys():
			var acao := String(anim).split("_d")[0]
			var fps: float = FPS_POR_ACAO.get(acao, DEFAULT_FPS)
			var loop := acao.contains("idle") or acao.contains("walk")
			frames.add_animation(anim)
			frames.set_animation_speed(anim, fps)
			frames.set_animation_loop(anim, loop)
			var nums := grupos[prefixo][anim].keys()
			nums.sort()
			for n in nums:
				var tex: Texture2D = load(grupos[prefixo][anim][n])
				if tex != null:
					frames.add_frame(anim, tex)

		var nome_recurso := prefixo.replace(" ", "_")
		var caminho := "%s/%s.tres" % [PASTA_SAIDA, nome_recurso]
		DirAccess.make_dir_recursive_absolute(PASTA_SAIDA)
		var erro := ResourceSaver.save(frames, caminho)
		if erro == OK:
			var total := 0
			for anim in grupos[prefixo].keys():
				total += grupos[prefixo][anim].size()
			print("  [ok] %s -> %s (%d animacoes, %d frames)" % [prefixo, caminho, grupos[prefixo].size(), total])
		else:
			printerr("  [erro] %s: codigo %d" % [caminho, erro])

	return true


# Extrai a ação do prefixo removendo o nome do personagem:
# "FeralQueenValere_Walk_D3_F05" -> prefixo "FeralQueenValere_Walk" -> acao "Walk"
func _acao_de(personagem: String, prefixo: String) -> String:
	var p := prefixo
	if p.begins_with(personagem + "_"):
		p = p.substr(personagem.length() + 1)
	return p
