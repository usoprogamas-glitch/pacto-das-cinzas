class_name DialogueSystem
extends RefCounted

## Diálogos data-driven (SoS): NPC tem nome + páginas; avança com E/clique.
## Conteúdo do GDD ("O Deus Despedaçado") finalmente dentro do jogo.

signal dialogue_started(npc_id: String, npc_name: String)
signal page_changed(page_text: String, page_index: int, total_pages: int)
signal dialogue_ended(npc_id: String)

## Diálogos: primeiro acesso conta a missão; visitas seguintes, respostas curtas.
const DIALOGUES: Dictionary = {
	"brugaves_fronteira": {
		"name": "Brugaves",
		"first": [
			"Kael... você despertou. O Éter lateja em suas mãos — eu senti daqui.",
			"Nossos deuses mentiram por mil anos. A Igreja de Solaria colhe a fé como quem colhe trigo... e agora vêm colher VOCÊ.",
			"Os mercenários do Capitão Cenu cercaram a Fronteira. Derrote-os e mostre ao mundo que a chama de Kaelen ainda vive.",
			"Vá. Caminhe com W-A-S-D. Encontre os invasores. Eu sigo seus passos, como sempre segui."
		],
		"repeat": [
			"A Fronteira ainda respira graças a você. Os invasores esperam — termine o serviço.",
			"Lembre-se: no combate, o timing é tudo. Um golpe no momento perfeito vale mais que dez apressados."
		]
	},
	"brugaves_act2": {
		"name": "Brugaves",
		"first": [
			"Ignis é apenas o primeiro Cardeal. Cada um deles carrega um fragmento do trono mentiroso.",
			"Quando o fogo do vulcão esfriar, siga o vento. Zephyr fala com as tempestades — e as tempestades têm ouvidos."
		],
		"repeat": [
			"O fogo purifica, Kael. Mas é o gelo da dúvida que forja mestres."
		]
	}
}

var _npc_id: String = ""
var _pages: Array = []
var _page_index: int = 0
var _active: bool = false


## Inicia o diálogo do NPC (first se 1ª vez via flag, repeat nas demais).
func start(npc_id: String, seen_flag: bool = false) -> bool:
	if _active or not DIALOGUES.has(npc_id):
		return false
	var data: Dictionary = DIALOGUES[npc_id]
	var key := "repeat" if seen_flag else "first"
	_pages = (data.get(key, []) as Array).duplicate()
	if _pages.is_empty():
		_pages = (data.get("first", []) as Array).duplicate()
	if _pages.is_empty():
		return false
	_npc_id = npc_id
	_page_index = 0
	_active = true
	dialogue_started.emit(npc_id, String(data["name"]))
	page_changed.emit(_pages[0], 0, _pages.size())
	return true


## Avança uma página. True = ainda dialogando; False = diálogo terminou.
func advance() -> bool:
	if not _active:
		return false
	_page_index += 1
	if _page_index >= _pages.size():
		_active = false
		dialogue_ended.emit(_npc_id)
		return false
	page_changed.emit(_pages[_page_index], _page_index, _pages.size())
	return true


func is_active() -> bool:
	return _active


func get_npc_name() -> String:
	return String(DIALOGUES.get(_npc_id, {}).get("name", ""))
