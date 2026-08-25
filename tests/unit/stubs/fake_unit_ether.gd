extends RefCounted

## Stub mínimo que implementa o contrato do EtherSystem.
## Usado pelos testes GUT — não faz parte da lógica do jogo.

var ether: int = 0
var alive: bool = true


func get_ether() -> int:
	return ether


func set_ether(value: int) -> void:
	ether = value


func is_alive() -> bool:
	return alive
