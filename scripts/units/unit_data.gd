class_name UnitData
extends Resource

@export var unit_name: String = "Unit"
@export var is_player: bool = true
@export var unit_class: String = "warrior"

@export_group("Base Stats")
@export var max_hp: int = 100
@export var attack: int = 15
@export var defense: int = 10
@export var magic: int = 0
@export var speed: int = 10
@export var move_range: int = 3
@export var attack_range: int = 1

@export_group("Battle Stats")
@export var current_hp: int = 100
@export var current_mp: int = 50
@export var max_mp: int = 50
@export var soul_ether_value: int = 10
@export var start_ether: int = 0  ## Cargas de Éter iniciais (GDD v2 §3.3, máx. 3)
@export var spell: String = "fire_bolt"  ## Feitiço padrão do caster (GDD v2 §3.3; lido pela EnemyAI.caster_ai)

@export_group("Visual")
@export var color: Color = Color.WHITE
@export var sprite_frame: int = 0
