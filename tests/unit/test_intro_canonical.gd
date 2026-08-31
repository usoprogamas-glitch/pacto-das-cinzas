extends "res://addons/gut/test.gd"

## Regressão: a intro é HISTÓRIA, não escolha (pedido do usuário — "ele é uma
## história, não tem essas opções"). O 1º Pacto de Alma é narrado e canônico:
## Kroug nasce sempre. Valida que não há slides de escolha e que o payload do
## intro_completed carrega first_pact com consequence (consumido pelo GameManager).

func make_story() -> Node:
	var story = load("res://scripts/ui/intro_story.gd").new()
	story._build_ui_if_missing()
	story.text_label = story.get_node("VBoxContainer/TextLabel")
	story.choice_container = story.get_node("VBoxContainer/ChoiceContainer")
	story.kaelen_portrait = story.get_node("VBoxContainer/KaelenPortrait")
	story.page_counter = story.get_node("VBoxContainer/PageCounter")
	story.controls_hint = story.get_node("VBoxContainer/ControlsHint")
	story.setup_story()
	return story


func test_no_choice_slides_in_story():
	var story = make_story()
	for step in story.story_text:
		assert_eq(step.get("choices", []).size(), 0, "nenhum slide deve ter escolhas: '%s'" % step.text.substr(0, 30))


func test_story_narrates_first_pact_and_kroug():
	var story = make_story()
	var full_text := ""
	for step in story.story_text:
		full_text += step.text + " "
	assert_true(full_text.contains("Kroug"), "a história narra o nascimento de Kroug")
	assert_true(full_text.contains("Pacto"), "a história narra o 1º Pacto de Alma")


func test_all_slides_advance_with_input_only():
	# Do primeiro ao último slide só com input; nenhum slide bloqueia com botões.
	var story = make_story()
	story.show_current_step()
	var total = story.story_text.size()
	for i in range(total - 1):
		var ev = InputEventAction.new()
		ev.action = "intro_next"
		ev.pressed = true
		story._input(ev)
		assert_eq(story.current_step, i + 1, "input avança do slide %d para %d" % [i, i + 1])
	assert_false(story.choice_container.visible, "container de escolhas nunca fica visível")


func test_final_choices_carry_canonical_first_pact():
	# Payload canônico independentemente de pular ou assistir.
	var story = make_story()
	var choices = story._build_final_choices()
	assert_true(choices.has("first_pact_choice"), "payload carrega a escolha canônica")
	assert_eq(choices["first_pact_choice"].consequence, "first_pact", "consequence consumida pelo GameManager")


func test_skip_intro_yields_same_canonical_payload():
	var story = make_story()
	story.skip_intro()
	assert_true(story.player_choices.has("skipped"), "skip marcado")
	assert_true(story.player_choices.has("first_pact_choice"), "pular a intro mantém o pacto canônico")
	assert_eq(story.player_choices["first_pact_choice"].consequence, "first_pact")
