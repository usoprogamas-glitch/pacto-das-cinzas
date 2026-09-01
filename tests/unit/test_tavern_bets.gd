extends "res://addons/gut/test.gd"

## Apostas + recompensas exclusivas da Taberna (GDD v2 §7.3, ROADMAP #12):
## aposta em ouro paga 2x na vitória e some na derrota; sequência de vitórias
## destrava recompensas exclusivas data-driven (REWARD_TIERS).

var tavern: TavernMinigame


func before_each() -> void:
	tavern = TavernMinigame.new()


func after_each() -> void:
	tavern = null


func _win_signals() -> Dictionary:
	var out := {"resolved": 0, "won": false, "payout": -1, "rewards": []}
	tavern.bet_resolved.connect(func(won, payout):
		out["resolved"] += 1
		out["won"] = won
		out["payout"] = payout)
	tavern.exclusive_reward_earned.connect(func(id): out["rewards"].append(id))
	return out


func test_game_without_bet_pays_nothing():
	tavern.start_game("Jogador", "IA")
	var out := _win_signals()
	tavern._end_game("Jogador", "IA")
	assert_eq(out["resolved"], 1, "sinal de aposta emitido mesmo casual")
	assert_false(out["won"] == true and out["payout"] > 0, "sem aposta não há payout")
	assert_eq(tavern.get_last_payout(), 0, "payout zero em jogo casual")


func test_win_pays_double_bet():
	tavern.start_game("Jogador", "IA", 25)
	assert_eq(tavern.get_bet(), 25, "aposta registrada")
	var out := _win_signals()
	tavern._end_game("Jogador", "IA")
	assert_true(out["won"], "vitória do apostador")
	assert_eq(out["payout"], 50, "payout 2x a aposta")
	assert_eq(tavern.get_last_payout(), 50)


func test_loses_bet_on_defeat():
	tavern.start_game("Jogador", "IA", 25)
	var out := _win_signals()
	tavern._end_game("IA", "Jogador")
	assert_false(out["won"], "derrota do apostador")
	assert_eq(out["payout"], 0, "payout zero na derrota")
	assert_eq(tavern.get_win_streak(), 0, "streak zerado na derrota")


func test_negative_bet_clamps_to_zero():
	tavern.start_game("Jogador", "IA", -30)
	assert_eq(tavern.get_bet(), 0, "aposta negativa vira casual")


func test_play_rune_win_resolves_bet():
	# Caminho real de vitória: HP do oponente em 1 + carta de dano na mão.
	tavern.start_game("Jogador", "IA", 10)
	var out := _win_signals()
	tavern.set_player_hp("IA", 1)
	var played := false
	for rune_id: String in tavern.get_player_hand("Jogador"):
		if RUNE_CASTABLE.call(tavern, "Jogador", rune_id):
			tavern.play_rune("Jogador", rune_id)
			played = true
			break
	assert_true(played, "carta jogável na mão inicial")
	assert_eq(out["resolved"], 1, "bet_resolved exatamente uma vez via play_rune")
	assert_eq(tavern.get_win_streak(), 1, "streak conta a vitória real")


var RUNE_CASTABLE := func(t, player_id, rune_id): return t.can_play_rune(player_id, rune_id)


func test_streak_unlocks_exclusive_rewards():
	tavern.start_game("Jogador", "IA", 0)
	var out := _win_signals()
	tavern._end_game("Jogador", "IA")
	tavern.start_game("Jogador", "IA", 0)
	tavern._end_game("Jogador", "IA")
	tavern.start_game("Jogador", "IA", 0)
	tavern._end_game("Jogador", "IA")
	assert_eq(tavern.get_win_streak(), 3, "três vitórias em sequência")
	assert_eq(out["rewards"].size(), 3, "uma recompensa por degrau de streak")
	assert_eq(tavern.get_rewards_earned(), ["amuleto_runico", "colar_de_ossos", "coroa_da_guerra_de_runas"], "recompensas na ordem dos tiers")


func test_rewards_do_not_repeat():
	tavern.start_game("Jogador", "IA", 0)
	var out := _win_signals()
	tavern._end_game("Jogador", "IA")
	tavern.start_game("Jogador", "IA", 0)
	tavern._end_game("IA", "Jogador")  # quebra a sequência
	tavern.start_game("Jogador", "IA", 0)
	tavern._end_game("Jogador", "IA")  # streak volta a 1 → tier já obtido
	assert_eq(out["rewards"].size(), 1, "tier repetido não reemite")
	assert_eq(tavern.get_rewards_earned().size(), 1, "recompensa única registrada")


func test_reward_tiers_data_driven():
	var tiers: Dictionary = tavern.get_reward_tiers()
	assert_true(tiers.has(1) and tiers.has(2) and tiers.has(3), "tiers 1..3 declarados")
	var ids := []
	for tier in tiers.values():
		assert_true(tier.has("id") and tier.has("name"), "tier com id e nome")
		assert_false(tier["id"] in ids, "id único")
		ids.append(tier["id"])
