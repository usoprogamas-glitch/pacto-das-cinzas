extends RefCounted

## Stub mínimo que implementa o contrato exigido pelo TurnOrderManager.
## Usado pelos testes GUT — não faz parte da lógica do jogo.

var speed: int = 0
var player_side: bool = true
var alive: bool = true


func get_speed() -> int:
	return speed


func is_player_side() -> bool:
	return player_side


func is_alive() -> bool:
	return alive
