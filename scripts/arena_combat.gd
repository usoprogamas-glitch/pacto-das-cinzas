class_name ArenaCombat
extends RefCounted

## Núcleo de combate arena (molde Sea of Stars — decisão 2026-08-31):
## sem grid tático. Lógica pura, headless-testável; a cena (arena_battle.gd)
## só apresenta e consome este núcleo.
##
## Contrato de unidade (duck typing, igual TurnOrderManager):
##   get_speed() -> int | is_player_side() -> bool | is_alive() -> bool
##   current_hp / max_hp / atk / def / current_mp

const TIMED_HIT_WINDOW := 0.3  ## s (TimedCombatSystem.ATTACK_WINDOW)
const TIMED_BLOCK_WINDOW := 0.2  ## s (TimedCombatSystem.BLOCK_WINDOW)
const MAGIC_COST := 10
const MAGIC_MULTIPLIER := 1.6

var timed_combat := TimedCombatSystem.new()


## Ordem de ação do round: herda o velocity-sort do TurnOrderManager (GDD §5.1).
func build_turn_order(units: Array) -> Array:
	return TurnOrderManager.build_order(units)


## Leitura de stats com duck typing: Unit (data.attack/defense) ou objeto cru
## com atk/def diretos.
func _attack_of(u) -> int:
	if u.data != null and u.data.get("attack") != null:
		return int(u.data.attack)
	return int(u.atk)


func _defense_of(u) -> int:
	if u.data != null and u.data.get("defense") != null:
		return int(u.data.defense)
	return int(u.def)


## Dano base: attack vs defense com variação ±15% (mesma curva do grid).
func calculate_damage(attacker, target, timing_multiplier: float = 1.0) -> int:
	var base := maxi(1, _attack_of(attacker) - _defense_of(target))
	var variation := randf_range(0.85, 1.15)
	return maxi(1, int(base * variation * timing_multiplier))


## Magia: ignora metade da defesa (perfura o tank), custo em MP.
func cast_damage_spell(caster, target) -> Dictionary:
	if caster.current_mp < MAGIC_COST:
		return {"success": false, "damage": 0}
	caster.current_mp -= MAGIC_COST
	var base := maxi(1, int(_attack_of(caster) * MAGIC_MULTIPLIER) - int(_defense_of(target) * 0.5))
	var variation := randf_range(0.85, 1.15)
	return {"success": true, "damage": maxi(1, int(base * variation))}


## Aplica o golpe resolvido: dano já com timed hit/block embutidos pela cena.
func apply_hit(attacker, target, damage: int) -> int:
	target.current_hp = maxi(0, target.current_hp - damage)
	return target.current_hp


## IA inimiga: alvo jogador de menor HP (foca kill), desempate aleatório.
## Só considera unidades do lado do jogador (o array pode vir sujo).
func choose_enemy_target(players: Array):
	var alive := players.filter(func(u): return u.is_alive() and u.is_player_side())
	if alive.is_empty():
		return null
	alive.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	return alive[0]


## Batalha terminou? Vantagem do jogador no desempate de checagem.
func is_battle_over(units: Array) -> String:
	var players_alive := false
	var enemies_alive := false
	for u in units:
		if u.is_alive():
			if u.is_player_side():
				players_alive = true
			else:
				enemies_alive = true
	if not players_alive:
		return "defeat"
	if not enemies_alive:
		return "victory"
	return ""
