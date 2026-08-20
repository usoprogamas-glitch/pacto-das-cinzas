class_name CharacterProgression
extends Node

signal form_changed(old_form: String, new_form: String)
signal stat_upgraded(stat: String, new_value: int)
signal ability_unlocked(ability_name: String)

var protagonist_stats: Dictionary = {
 "form": "Imp Menor",
 "fragments": 0,
 "memories": [],
 "named_souls": 0,
 "stats": {
  "hp": 80,
  "mp": 120,
  "attack": 8,
  "defense": 5,
  "magic": 10,
  "speed": 120
 },
 "abilities": ["instinto_carnica", "faisca_abissal", "salto_rapido", "toque_centelha"],
 "passives": ["instinto_carnica"]
}

var forms: Dictionary = {
 "Imp Menor": {
  "level": 1,
  "fragments_required": 0,
  "souls_required": 0,
  "scale": 0.8,
  "stat_multipliers": {"hp": 1.0, "mp": 1.0, "attack": 1.0, "defense": 1.0, "magic": 1.0, "speed": 1.2},
  "new_abilities": ["faisca_abissal", "salto_rapido", "toque_centelha"],
  "description": "Frágil, mas rápido. Coleta e sobrevivência.",
  "visual": "Corpo magro, pele carmesim, chifres rombudos, olhos amarelos"
 },
 "Nobre Abissal": {
  "level": 2,
  "fragments_required": 3,
  "souls_required": 10,
  "scale": 2.1,
  "stat_multipliers": {"hp": 5.6, "mp": 5.0, "attack": 3.0, "defense": 7.0, "magic": 4.0, "speed": 1.05},
  "new_abilities": ["chamas_submundo", "aura_submissao", "comando_monstros"],
  "description": "Liderança. Comanda monstros nomeados.",
  "visual": "Pele cinza-ardósia, runas azuis, chifres obsidiana, asas negras"
 },
 "Arquidemônio": {
  "level": 3,
  "fragments_required": 7,
  "souls_required": 100,
  "scale": 3.2,
  "stat_multipliers": {"hp": 12.0, "mp": 10.0, "attack": 8.0, "defense": 15.0, "magic": 10.0, "speed": 0.8},
  "new_abilities": ["fenda_espacial", "medo_em_massa", "exercito_sombrias"],
  "description": "Presença aterrorizante. Destruição em massa.",
  "visual": "Levita, asas grandiosas, aura de escuridão"
 },
 "Avatar Primordial": {
  "level": 4,
  "fragments_required": 12,
  "souls_required": 1000,
  "scale": 4.5,
  "stat_multipliers": {"hp": 30.0, "mp": 25.0, "attack": 20.0, "defense": 30.0, "magic": 25.0, "speed": 1.5},
  "new_abilities": ["alteracao_realidade", "juizo_divino", "pacto_eterno"],
  "description": "Deus restaurado. Equilíbrio entre compaixão e disciplina.",
  "visual": "Forma humana-demoníaca, asas de éter, olhos de fogo"
 }
}

var apostle_progression: Dictionary = {
 "kroug": {
  "name": "Kroug",
  "title": "O Escudo",
  "forms": [
   {"name": "Goblin da Lama", "level": 1, "stats": {"hp": 80, "attack": 10, "defense": 15}},
   {"name": "Hobgoblin de Ferro", "level": 3, "stats": {"hp": 120, "attack": 18, "defense": 25}},
   {"name": "Ogro de Guerra", "level": 6, "stats": {"hp": 200, "attack": 30, "defense": 40}},
   {"name": "Rei Ogro de Fogo", "level": 10, "stats": {"hp": 350, "attack": 45, "defense": 60}}
  ],
  "current_form": 0,
  "faith": 0
 },
 "lira": {
  "name": "Lira",
  "title": "A Sacerdotisa",
  "forms": [
   {"name": "Muda Mágica", "level": 1, "stats": {"hp": 50, "magic": 15, "defense": 8}},
   {"name": "Dryade Jovem", "level": 3, "stats": {"hp": 80, "magic": 25, "defense": 15}},
   {"name": "Ent Primordial", "level": 6, "stats": {"hp": 140, "magic": 40, "defense": 25}},
   {"name": "Rainha dos Bosques", "level": 10, "stats": {"hp": 250, "magic": 60, "defense": 40}}
  ],
  "current_form": 0,
  "faith": 0
 },
 "thalkor": {
  "name": "Thal'kor",
  "title": "A Lâmina Cega",
  "forms": [
   {"name": "Anjo Caído", "level": 1, "stats": {"hp": 60, "attack": 25, "speed": 18}},
   {"name": "Seraphim Ferido", "level": 3, "stats": {"hp": 90, "attack": 35, "speed": 20}},
   {"name": "Cavaleiro Negro", "level": 6, "stats": {"hp": 130, "attack": 50, "speed": 22}},
   {"name": "Serafim das Sombras", "level": 10, "stats": {"hp": 200, "attack": 70, "speed": 25}}
  ],
  "current_form": 0,
  "faith": 0
 }
}

func _ready() -> void:
 pass

func add_fragment() -> void:
 protagonist_stats.fragments += 1
 check_form_evolution()

func check_form_evolution() -> void:
 var current_form = protagonist_stats.form
 var next_form = get_next_form(current_form)

 if next_form != "" and protagonist_stats.fragments >= forms[next_form].fragments_required:
  evolve_form(next_form)

func get_next_form(current: String) -> String:
 match current:
  "Imp Menor": return "Nobre Abissal"
  "Nobre Abissal": return "Arquidemônio"
  "Arquidemônio": return "Avatar Primordial"
  _: return ""

func evolve_form(new_form: String) -> void:
 var old_form = protagonist_stats.form
 protagonist_stats.form = new_form

 # Aplicar novos stats
 var form_data = forms[new_form]
 for stat in form_data.stat_multipliers:
  if protagonist_stats.stats.has(stat):
   var base = get_base_stat(stat)
   protagonist_stats.stats.stat[stat] = int(base * form_data.stat_multipliers[stat])

 # Desbloquear habilidades
 for ability in form_data.new_abilities:
  if ability not in protagonist_stats.abilities:
   protagonist_stats.abilities.append(ability)
   ability_unlocked.emit(ability)

 form_changed.emit(old_form, new_form)

func get_base_stat(stat: String) -> int:
 match stat:
  "hp": return 50
  "mp": return 20
  "attack": return 8
  "defense": return 5
  "magic": return 3
  "speed": return 12
 return 0

func add_apostle_faith(apostle_id: String, amount: int) -> void:
 if apostle_progression.has(apostle_id):
  apostle_progression[apostle_id].faith += amount
  check_apostle_evolution(apostle_id)

func check_apostle_evolution(apostle_id: String) -> void:
 var apostle = apostle_progression[apostle_id]
 var current_form_index = apostle.current_form

 if current_form_index < apostle.forms.size() - 1:
  var next_form = apostle.forms[current_form_index + 1]
  if apostle.faith >= get_faith_required(next_form.level):
   apostle.current_form = current_form_index + 1

func get_faith_required(level: int) -> int:
 return level * 10

func get_apostle_stats(apostle_id: String) -> Dictionary:
 if apostle_progression.has(apostle_id):
  var apostle = apostle_progression[apostle_id]
  return apostle.forms[apostle.current_form].stats
 return {}

func get_apostle_form(apostle_id: String) -> String:
 if apostle_progression.has(apostle_id):
  var apostle = apostle_progression[apostle_id]
  return apostle.forms[apostle.current_form].name
 return ""

func get_protagonist_stats() -> Dictionary:
 return protagonist_stats.stats.duplicate()

func get_protagonist_abilities() -> Array:
 return protagonist_stats.abilities.duplicate()

func get_form_info(form_name: String) -> Dictionary:
 return forms.get(form_name, {})
