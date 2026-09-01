class_name TavernMinigame
extends RefCounted

## Minigame de Taberna — "Guerra de Runas" (GDD v2 §7.3)
##
## Jogo de cartas/feitiços jogado entre personagens na taberna.
## Dois jogadores alternam jogando cartas de runa para reduzir
## o HP do oponente a zero. Cada runa tem custo de éter e dano/efeito.

signal game_started(player1: String, player2: String)
signal card_played(player: String, card_id: String, damage: int)
signal turn_changed(current_player: String)
signal game_over(winner: String, loser: String)
signal bet_resolved(won: bool, payout: int)
signal exclusive_reward_earned(reward_id: String)

## --- Apostas e recompensas exclusivas (GDD v2 §7.3, ROADMAP #12) ---
## O protagonista aposta ouro contra o rival da taberna. Vitória paga
## PAYOUT_MULTIPLIER x a aposta; derrota perde a aposta. Sequência de vitórias
## destrava recompensas exclusivas (data-driven em REWARD_TIERS).
const PAYOUT_MULTIPLIER := 2

## Recompensas exclusivas da Guerra de Runas por sequência de vitórias.
const REWARD_TIERS: Dictionary = {
 1: {"id": "amuleto_runico", "name": "Amuleto Rúnico", "description": "Talismã de osso gravado com a primeira vitória."},
 2: {"id": "colar_de_ossos", "name": "Colar de Ossos", "description": "Troféu dos fiéis da taberna — dois rivais caídos."},
 3: {"id": "coroa_da_guerra_de_runas", "name": "Coroa da Guerra de Runas", "description": "Insignia suprema: ninguém mais ousa apostar contra você."},
}

## --- Runas disponíveis ---
const RUNES: Dictionary = {
 "chamas": {
  "name": "Chamas",
  "description": "Dano direto ao oponente",
  "ether_cost": 1,
  "damage": 8,
  "effect": "none",
 },
 "escudo": {
  "name": "Escudo",
  "description": "Bloqueia próximo dano recebido",
  "ether_cost": 1,
  "damage": 0,
  "effect": "shield",
  "shield_amount": 10,
 },
 "drenar": {
  "name": "Drenar",
  "description": "Drena HP e restaura éter",
  "ether_cost": 2,
  "damage": 5,
  "effect": "drain",
  "ether_gain": 1,
 },
 "raio": {
  "name": "Raio",
  "description": "Alto dano, alto custo",
  "ether_cost": 3,
  "damage": 18,
  "effect": "none",
 },
 "gelo": {
  "name": "Gelo",
  "description": "Dano e congela (pula próxima vez)",
  "ether_cost": 2,
  "damage": 6,
  "effect": "freeze",
  "freeze_duration": 1,
 },
 "curandeira": {
  "name": "Curandeira",
  "description": "Cura o próprio HP",
  "ether_cost": 1,
  "damage": 0,
  "effect": "heal",
  "heal_amount": 10,
 },
 "tempestade": {
  "name": "Tempestade",
  "description": "Dano em área (ignora escudo)",
  "ether_cost": 2,
  "damage": 7,
  "effect": "pierce_shield",
 },
 "sacrificio": {
  "name": "Sacrifício",
  "description": "Dano alto mas perde HP próprio",
  "ether_cost": 0,
  "damage": 12,
  "effect": "self_damage",
  "self_damage": 5,
 },
}

## --- Configuração do jogo ---
const GAME_CONFIG: Dictionary = {
 "starting_hp": 50,
 "starting_ether": 3,
 "max_ether": 5,
 "ether_per_turn": 1,
 "max_hand_size": 4,
 "draw_per_turn": 1,
}

## --- Estado do jogo ---
var _players: Dictionary = {}  ## {player_id: {hp, ether, max_ether, shield, frozen, hand}}
var _turn: String = ""  ## player_id do jogador atual
var _turn_count: int = 0
var _game_active: bool = false
var _winner: String = ""
var _deck_p1: Array = []
var _deck_p2: Array = []
var _bet: int = 0  ## aposta atual em ouro (0 = jogo casual)
var _last_payout: int = 0  ## ouro ganho na última partida (0 se derrota/casual)
var _win_streak: int = 0  ## sequência de vitórias destrava recompensas
var _rewards_earned: Array = []  ## ids de recompensas exclusivas já obtidas


## --- Inicialização ---

## Iniciar novo jogo. bet = ouro apostado (0 = casual, sem payout).
func start_game(player1: String, player2: String, bet: int = 0) -> void:
 _bet = maxi(0, bet)
 _players[player1] = {
  "hp": GAME_CONFIG.starting_hp,
  "ether": GAME_CONFIG.starting_ether,
  "max_ether": GAME_CONFIG.max_ether,
  "shield": 0,
  "frozen": 0,
  "hand": [],
 }
 _players[player2] = {
  "hp": GAME_CONFIG.starting_hp,
  "ether": GAME_CONFIG.starting_ether,
  "max_ether": GAME_CONFIG.max_ether,
  "shield": 0,
  "frozen": 0,
  "hand": [],
 }

 ## Criar decks e distribuir mãos iniciais
 _deck_p1 = _build_deck()
 _deck_p2 = _build_deck()
 _draw_initial_hands(player1, player2)

 _turn = player1
 _turn_count = 1
 _game_active = true
 _winner = ""
 game_started.emit(player1, player2)
 turn_changed.emit(_turn)


func _build_deck() -> Array:
 var deck = []
 ## 2 de cada runa básica
 for rune_id in RUNES:
  deck.append(rune_id)
  deck.append(rune_id)
 deck.shuffle()
 return deck


func _draw_initial_hands(p1: String, p2: String) -> void:
 for i in range(GAME_CONFIG.max_hand_size):
  _draw_card(p1, _deck_p1)
  _draw_card(p2, _deck_p2)


func _draw_card(player_id: String, deck: Array) -> void:
 if deck.is_empty():
  deck.append_array(_build_deck())  ## Reembaralha
 var card = deck.pop_back()
 if _players[player_id].hand.size() < GAME_CONFIG.max_hand_size:
  _players[player_id].hand.append(card)


## --- Turno ---

## Obter jogador atual.
func get_current_turn() -> String:
 return _turn


## Verificar se pode jogar uma runa.
func can_play_rune(player_id: String, rune_id: String) -> bool:
 if not _game_active:
  return false
 if player_id != _turn:
  return false
 if not _players.has(player_id):
  return false
 if not RUNES.has(rune_id):
  return false
 if _players[player_id].frozen > 0:
  return false
 var player = _players[player_id]
 if player.ether < RUNES[rune_id].ether_cost:
  return false
 if not rune_id in player.hand:
  return false
 return true


## Jogar uma runa.
func play_rune(player_id: String, rune_id: String) -> Dictionary:
 if not can_play_rune(player_id, rune_id):
  return {}

 var rune = RUNES[rune_id]
 var player = _players[player_id]
 var opponent_id = _get_opponent(player_id)
 var opponent = _players[opponent_id]

 ## Consumir éter
 player.ether -= rune.ether_cost

 ## Remover carta da mão
 var idx = player.hand.find(rune_id)
 if idx != -1:
  player.hand.remove_at(idx)

 ## Aplicar dano base
 var total_damage = rune.damage

 ## Auto-dano (Sacrifício)
 if rune.effect == "self_damage":
  player.hp -= rune.self_damage

 ## Efeito de escudo
 if rune.effect == "shield":
  player.shield += rune.shield_amount

 ## Efeito de cura
 if rune.effect == "heal":
  var heal = rune.heal_amount
  player.hp = mini(player.hp + heal, GAME_CONFIG.starting_hp)

 ## Efeito de drenar
 if rune.effect == "drain":
  player.ether = mini(player.ether + rune.ether_gain, player.max_ether)

 ## Aplicar dano ao oponente
 var actual_damage = total_damage
 if opponent.shield > 0 and rune.effect != "pierce_shield":
  if opponent.shield >= actual_damage:
   opponent.shield -= actual_damage
   actual_damage = 0
  else:
   actual_damage -= opponent.shield
   opponent.shield = 0

 if actual_damage > 0:
  opponent.hp -= actual_damage

 ## Efeito de congelar
 if rune.effect == "freeze":
  opponent.frozen = rune.freeze_duration

 ## Verificar game over
 var damage_done = rune.damage
 card_played.emit(player_id, rune_id, damage_done)

 if opponent.hp <= 0:
  _end_game(player_id, opponent_id)
  return {"damage": damage_done, "effect": rune.effect, "winner": player_id}

 _advance_turn()
 return {"damage": damage_done, "effect": rune.effect}


## Encerra a partida e resolve aposta + sequência de recompensas.
## player1 é sempre o lado do protagonista (apostador).
func _end_game(winner: String, loser: String) -> void:
 _game_active = false
 _winner = winner
 var protagonist_won: bool = winner == _players.keys()[0]
 var payout := 0
 if protagonist_won:
  _win_streak += 1
  if _bet > 0:
   payout = _bet * PAYOUT_MULTIPLIER
 else:
  _win_streak = 0
 _last_payout = payout
 bet_resolved.emit(protagonist_won, payout)
 var reward_id: String = _check_reward_tier()
 game_over.emit(winner, loser)
 if reward_id != "":
  exclusive_reward_earned.emit(reward_id)


## Recompensa exclusiva do novo streak (só se ainda não foi obtida).
func _check_reward_tier() -> String:
 if not REWARD_TIERS.has(_win_streak):
  return ""
 var reward: Dictionary = REWARD_TIERS[_win_streak]
 if reward["id"] in _rewards_earned:
  return ""
 _rewards_earned.append(reward["id"])
 return reward["id"]


func _advance_turn() -> void:
 var opponent_id = _get_opponent(_turn)

 ## Oponente congelado perde o turno
 if _players[opponent_id].frozen > 0:
  _players[opponent_id].frozen -= 1
  _turn_count += 1
  turn_changed.emit(_turn)
  return

 ## Trocar turno
 _turn = opponent_id
 _turn_count += 1

 ## Ganhar éter no início do turno
 _players[_turn].ether = mini(
  _players[_turn].ether + GAME_CONFIG.ether_per_turn,
  _players[_turn].max_ether
 )

 ## Comprar carta
 _draw_card(_turn, _deck_p1 if _turn == _get_opponent(opponent_id) else _deck_p2)

 turn_changed.emit(_turn)


func _get_opponent(player_id: String) -> String:
 for pid in _players:
  if pid != player_id:
   return pid
 return ""


## --- Getters ---

func get_player_state(player_id: String) -> Dictionary:
 return _players.get(player_id, {})

func get_player_hp(player_id: String) -> int:
 return _players.get(player_id, {}).get("hp", 0)

func get_player_ether(player_id: String) -> int:
 return _players.get(player_id, {}).get("ether", 0)

func get_player_hand(player_id: String) -> Array:
 return _players.get(player_id, {}).get("hand", [])

func get_player_shield(player_id: String) -> int:
 return _players.get(player_id, {}).get("shield", 0)

## Ajusta HP direto (testes e replay/debug da mesa).
func set_player_hp(player_id: String, hp: int) -> void:
 if _players.has(player_id):
  _players[player_id].hp = hp

func is_game_active() -> bool:
 return _game_active

func get_winner() -> String:
 return _winner

func get_turn_count() -> int:
 return _turn_count

func get_all_runes() -> Dictionary:
 return RUNES

func get_bet() -> int:
 return _bet

func get_win_streak() -> int:
 return _win_streak

func get_rewards_earned() -> Array:
 return _rewards_earned.duplicate()

func get_reward_tiers() -> Dictionary:
 return REWARD_TIERS

func get_last_payout() -> int:
 return _last_payout
