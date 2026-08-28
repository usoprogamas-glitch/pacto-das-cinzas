extends "res://addons/gut/test.gd"
## Controles da intro: A avança o slide, Start/ESC (e ESC) pulam a intro.
## Valida o _input com InputEventAction. O story é instanciado FORA da árvore
## (sem _ready → sem tween/auto-advance), e _input é chamado direto — sem o
## side-effect de trocar a cena (SceneManager.go_to_map_select) que quebraria a
## run do GUT.

func make_story() -> Node:
	var story = load("res://scripts/ui/intro_story.gd").new()
	script_build_story(story)
	return story


# = Popula as refs de UI como o _ready faria, sem rodar setup/auto-advance =
func script_build_story(story: Node) -> void:
	story._build_ui_if_missing()
	story.text_label = story.get_node("VBoxContainer/TextLabel")
	story.choice_container = story.get_node("VBoxContainer/ChoiceContainer")
	story.kaelen_portrait = story.get_node("VBoxContainer/KaelenPortrait")
	story.page_counter = story.get_node("VBoxContainer/PageCounter")
	story.controls_hint = story.get_node("VBoxContainer/ControlsHint")


func _press(body: Node, action_name: String) -> void:
	var ev = InputEventAction.new()
	ev.action = action_name
	ev.pressed = true
	body._input(ev)


func test_a_advances_slide_immediately():
	var story = make_story()
	# setup manual p/ ter story_text populado (sem _ready → sem auto-advance)
	story.setup_story()
	story.show_current_step()
	var step_before = story.current_step

	# A não deve esperar o tween — avança na hora
	_press(story, "intro_next")

	assert_eq(story.current_step, step_before + 1, "A avança para o próximo slide na hora")


func test_skip_action_maps_start_and_esc():
	# A action intro_skip precisa cobrir botão Start (joypad 6) E teclas (ESC/ENTER)
	var has_start = false
	var has_key = false
	for ev in InputMap.action_get_events("intro_skip"):
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_START:
			has_start = true
		if ev is InputEventKey and (ev.keycode == KEY_ESCAPE or ev.keycode == KEY_ENTER):
			has_key = true
	assert_true(has_start, "intro_skip mapeia o botão Start")
	assert_true(has_key, "intro_skip mapeia ESC/Enter")


func test_next_action_maps_a_and_pad_a():
	var has_key_a = false
	var has_pad = false
	for ev in InputMap.action_get_events("intro_next"):
		if ev is InputEventKey and ev.keycode == KEY_A:
			has_key_a = true
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_A:
			has_pad = true
	assert_true(has_key_a, "intro_next mapeia a tecla A")
	assert_true(has_pad, "intro_next mapeia o botão A do gamepad")