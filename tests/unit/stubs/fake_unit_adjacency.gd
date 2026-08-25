extends RefCounted

## Stub mínimo que implementa o contrato do AdjacencySystem.
## Usado pelos testes GUT — não faz parte da lógica do jogo.
## 'data' aponta para ele mesmo para simular UnitData sem dependências.

var unit_name: String = ""
var is_player: bool = false
var grid_position: Vector2i = Vector2i.ZERO
var current_hp: int = 100
var max_hp: int = 100

var data = self  ## Auto-referência: data.is_player e data.unit_name funcionam
