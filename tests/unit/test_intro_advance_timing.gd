extends "res://addons/gut/test.gd"
## Regressão: O auto-advance via tween foi REMOVIDO — slides só avançam no input do
## player (A = intro_next). Este teste verifica que NÃO há mais avanço automático
## por tempo: o slide 0 permanece após 4s (antes de 3.5s) e só avança via _input.

func test_no_auto_advance_timing():
	var story = load("res://scripts/intro_story.gd").new()
	add_child_autofree(story)  # _ready → setup_story + show_current_step

	# slide de narração ainda em tela após 4s (sem auto-advance)
	await wait_seconds(4.0)
	assert_eq(story.current_step, 0, "sem auto-advance, slide 0 permanece após 4s")

	# Só avança quando o player aperta A
	var ev = InputEventAction.new()
	ev.action = "intro_next"
	ev.pressed = true
	story._input(ev)
	assert_eq(story.current_step, 1, "A (intro_next) avança para o slide 1 na hora")
