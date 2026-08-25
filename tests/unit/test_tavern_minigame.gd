extends "res://addons/gut/test.gd"

## Testes GUT para TavernMinigame (Guerra de Runas, GDD v2 §7.3)


func test_start_game():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	assert_true(tm.is_game_active(), "Jogo ativo")


func test_initial_hp():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	assert_eq(tm.get_player_hp("P1"), 50, "HP inicial 50")
	assert_eq(tm.get_player_hp("P2"), 50, "HP inicial 50")


func test_initial_ether():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	assert_eq(tm.get_player_ether("P1"), 3, "Éter inicial 3")


func test_initial_hand():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	assert_eq(tm.get_player_hand("P1").size(), 4, "Mão inicial 4 cartas")
	assert_eq(tm.get_player_hand("P2").size(), 4, "Mão inicial 4 cartas")


func test_first_turn():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	assert_eq(tm.get_current_turn(), "P1", "P1 começa")


func test_can_play_rune():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	## Forçar uma runa na mão
	var hand = tm.get_player_hand("P1")
	hand.clear()
	hand.append("chamas")
	assert_true(tm.can_play_rune("P1", "chamas"), "Pode jogar chamas")


func test_cannot_play_wrong_turn():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	assert_false(tm.can_play_rune("P2", "chamas"), "P2 não pode jogar no turno de P1")


func test_cannot_play_not_in_hand():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var hand = tm.get_player_hand("P1")
	hand.clear()
	hand.append("chamas")
	assert_false(tm.can_play_rune("P1", "raio"), "Não tem raio na mão")


func test_play_chamas_deals_damage():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var hand = tm.get_player_hand("P1")
	hand.clear()
	hand.append("chamas")
	tm.play_rune("P1", "chamas")
	assert_eq(tm.get_player_hp("P2"), 42, "P2 recebe 8 de dano")


func test_play_chamas_costs_ether():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var hand = tm.get_player_hand("P1")
	hand.clear()
	hand.append("chamas")
	tm.play_rune("P1", "chamas")
	assert_eq(tm.get_player_ether("P1"), 2, "Gastou 1 éter")


func test_turn_advances_after_play():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var hand = tm.get_player_hand("P1")
	hand.clear()
	hand.append("chamas")
	tm.play_rune("P1", "chamas")
	assert_eq(tm.get_current_turn(), "P2", "Turno avança para P2")


func test_shield_blocks_damage():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	## P1 joga escudo
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("escudo")
	tm.play_rune("P1", "escudo")
	## P2 joga chamas
	var h2 = tm.get_player_hand("P2")
	h2.clear()
	h2.append("chamas")
	tm.play_rune("P2", "chamas")
	assert_eq(tm.get_player_hp("P1"), 50, "P1 não perde HP (escudo absorveu)")


func test_freeze_skips_turn():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("gelo")
	tm.play_rune("P1", "gelo")
	## P2 está congelado, turno volta para P1
	assert_eq(tm.get_current_turn(), "P1", "P2 pulou, volta pra P1")


func test_cannot_play_when_frozen():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("gelo")
	tm.play_rune("P1", "gelo")
	## P2 está congelado
	assert_false(tm.can_play_rune("P2", "chamas"), "Congelado não pode jogar")


func test_pierce_shield_ignores_shield():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	## P2 joga escudo
	var h2 = tm.get_player_hand("P2")
	h2.clear()
	h2.append("escudo")
	tm.play_rune("P2", "escudo")
	## P1 joga tempestade
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("tempestade")
	tm.play_rune("P1", "tempestade")
	assert_eq(tm.get_player_hp("P2"), 43, "Tempestade ignora escudo: 50 - 7")


func test_heal_restores_hp():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	tm.play_rune("P1", "chamas")  ## P2 = 42
	## P2 joga curandeira
	var h2 = tm.get_player_hand("P2")
	h2.clear()
	h2.append("curandeira")
	tm.play_rune("P2", "curandeira")
	assert_eq(tm.get_player_hp("P2"), 50, "P2 curou 10 (max 50)")


func test_self_damage_sacrifice():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("sacrificio")
	tm.play_rune("P1", "sacrificio")
	assert_eq(tm.get_player_hp("P1"), 45, "P1 perde 5 HP próprio")
	assert_eq(tm.get_player_hp("P2"), 38, "P2 recebe 12 de dano")


func test_game_over():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	## Forçar P2 com 1 HP
	var state = tm.get_player_state("P2")
	state.hp = 1
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	tm.play_rune("P1", "chamas")
	assert_false(tm.is_game_active(), "Jogo terminou")
	assert_eq(tm.get_winner(), "P1", "P1 venceu")


func test_cannot_play_after_game_over():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var state = tm.get_player_state("P2")
	state.hp = 1
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	tm.play_rune("P1", "chamas")
	assert_false(tm.can_play_rune("P1", "chamas"), "Jogo acabou")


func test_turn_count():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	tm.play_rune("P1", "chamas")
	assert_eq(tm.get_turn_count(), 2, "Turno 2 após 1 jogada")


func test_ether_gained_per_turn():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	tm.play_rune("P1", "chamas")  ## P1: 2 éter, turno P2: 4 éter
	assert_eq(tm.get_player_ether("P2"), 4, "P2 ganha 1 éter no turno (3+1)")


func test_game_started_signal():
	var tm = TavernMinigame.new()
	watch_signals(tm)
	tm.start_game("P1", "P2")
	assert_signal_emitted(tm, "game_started")


func test_card_played_signal():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	watch_signals(tm)
	tm.play_rune("P1", "chamas")
	assert_signal_emitted(tm, "card_played")


func test_game_over_signal():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var state = tm.get_player_state("P2")
	state.hp = 1
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("chamas")
	watch_signals(tm)
	tm.play_rune("P1", "chamas")
	assert_signal_emitted(tm, "game_over")


func test_play_invalid_rune():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var result = tm.play_rune("P1", "nao_existe")
	assert_eq(result, {}, "Runa inválida retorna vazio")


func test_drain_gains_ether():
	var tm = TavernMinigame.new()
	tm.start_game("P1", "P2")
	var h1 = tm.get_player_hand("P1")
	h1.clear()
	h1.append("drenar")
	tm.play_rune("P1", "drenar")
	assert_eq(tm.get_player_ether("P1"), 2, "Gastou 2, ganhou 1 = 2")


func test_get_all_runes():
	var tm = TavernMinigame.new()
	var runes = tm.get_all_runes()
	assert_eq(runes.size(), 8, "8 runas disponíveis")
