extends "res://addons/gut/test.gd"
## Testes da cena de intro (intro_story.tscn) — arte e mão amiga de UI.
## Não existia teste da main scene: instanciar viva no GUT roda o _ready, que
## auto-avança as 13 telas até complete_intro() (que troca a cena via SceneManager)
## e desestabilizaria a run. Aqui instanciamos SEM entrar na árvore (_ready não
## roda) e validamos estrutura + assets — sem side effects.

var _packed: PackedScene = load("res://scenes/intro_story.tscn")
var _inst: Node


func after_each() -> void:
	if _inst:
		_inst.free()
		_inst = null


func _open() -> Node:
	# fora da árvore → _ready não roda (sem tween/auto-advance)
	_inst = _packed.instantiate()
	return _inst


# === A cena carrega e tem os nós de UI ===

func test_scene_loads():
	assert_not_null(_packed, "intro_story.tscn deve carregar (é a main scene)")


func test_text_label_present_and_legible():
	var node = _open()
	var label = node.get_node("VBoxContainer/TextLabel") as Label
	assert_not_null(label, "TextLabel deve existir no .tscn")
	assert_eq(label.get_theme_font_size("font_size"), 22, "fonte 22 (texto narrado legível)")
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "autowrap do texto")


func test_controls_hint_visible():
	var node = _open()
	var hint = node.get_node("VBoxContainer/ControlsHint") as Label
	assert_not_null(hint, "ControlsHint (dica de controles) deve existir")
	assert_true(hint.text.contains("A"), "dica menciona a tecla A: '%s'" % hint.text)
	assert_true(hint.text.contains("pular"), "dica menciona pular: '%s'" % hint.text)


func test_page_counter_present():
	var node = _open()
	var counter = node.get_node("VBoxContainer/PageCounter") as Label
	assert_not_null(counter, "PageCounter deve existir no .tscn")


# === Retrato do Kaelen ===

func test_kaelen_portrait_node_configured():
	var node = _open()
	var portrait = node.get_node("VBoxContainer/KaelenPortrait") as TextureRect
	assert_not_null(portrait, "KaelenPortrait deve existir no .tscn")
	assert_eq(portrait.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "expand mode preserva proporção")
	assert_eq(portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "stretch keep-aspect")


func test_kaelen_portrait_asset():
	# O path que intro_story.gd carrega nas falas do Kaelen existe.
	assert_true(FileAccess.file_exists("res://assets/portraits/kaelen.png"),
		"assets/portraits/kaelen.png deve existir (retrato do Kaelen)")
	# O .ctex importado vive em .godot/imported, que é git-ignored — só existe após
	# o editor/--import rodar uma vez. Em clone fresco/CI headless o asset real
	# existe mas o import ainda não: nesse caso não dá para carregar Texture, então
	# o teste valida o que dá (arquivo + node configurado) e aborta sem falha.
	var ctex: String = "res://.godot/imported/kaelen.png-d6550216e7052dda46f7dd7749e04afd.ctex"
	if not FileAccess.file_exists(ctex):
		return
	var tex = load("res://assets/portraits/kaelen.png")
	assert_not_null(tex, "kaelen.png deve carregar como Texture (recebeu: %s)" % tex)