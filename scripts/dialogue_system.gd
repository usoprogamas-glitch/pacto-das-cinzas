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
		"portrait": "dialog-portrait-Brugaves",
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
	},
	"guia_ignis": {
		"name": "Sobrevivente",
		"portrait": "dialog-portrait-valereDLCThroes",
		"first": [
			"Ei! Você não é dessas terras... Se veio pelo Cardeal Ignis, saiba que ele AQUECE o ar antes do golpe — o chão brilha quando ele vai atacar!",
			"Ele canaliza um feitiço devastador. Quebre os selos brilhantes com golpes do tipo certo, ou vire cinza.",
			"Leve isto: provisões que achei no acampamento dele. Que a fúria esteja com você."
		],
		"repeat": [
			"Ignis observa do vulcão. O chão brilha antes do golpe dele — não esqueça."
		]
	},
	"mercador_fronteira": {
		"name": "Mercador Errante",
		"portrait": "dialog-portrait-zaleDLCThroes",
		"first": [
			"Mercador Errante a serviço de quem paga! Tenho poções roubadas da Igreja — quer ver?"
		],
		"repeat": [
			"O ouro fala mais alto que reza, amigo. O que vai levar?"
		]
	},
	"refugiado_castelo": {
		"name": "Refugiado do Castelo",
		"portrait": "dialog-portrait-valereDLCThroes",
		"first": [
			"O Cardeal de Mármore dorme dentro das paredes... Elas SE MEXEM, entende? As muralhas são o corpo dele.",
			"Ataque-o quando ele eriçar as pedras. E não confie no chão verde do salão — é ilusão de mármore."
		],
		"repeat": [
			"As muralhas sussurram à noite. Derrote-o, por favor."
		]
	},
	"eremita_floresta": {
		"name": "Eremita dos Ventos",
		"portrait": "dialog-portrait-Brugaves",
		"first": [
			"Zephyr corta o céu em cinco direções, como seus golpes. Cinco! Aprenda as cinco e você o alcança.",
			"Os ventos também trazem asas... dizem que quem liberta a Floresta dos Ventos herda o dom de voar."
		],
		"repeat": [
			"O vento sussurra o nome dele: Zephyr. Cinco direções, Kael."
		]
	},
	"pescador_lago": {
		"name": "Pescador Cego",
		"portrait": "dialog-portrait-Brugaves",
		"first": [
			"Eu pesquei nessas águas bentas por quarenta anos... até que ficaram corrosivas. Aquilo lá embaixo não é mais água.",
			"Aqua reza com um cálice. Quebre a fé dele e as águas voltam ao leito."
		],
		"repeat": [
			"As águas gemem à noite. Só o cálice importa."
		]
	},
	"nomo_sombras": {
		"name": "Gnomo das Sombras",
		"portrait": "dialog-portrait-zaleDLCThroes",
		"first": [
			"Hehe... me viu? Ninguém me vê. Mas EU vejo a Luz Negra dele, o Cardeal sem rosto.",
			"Umbra vive de silhuetas. Onde sua sombra pisar, a dele estará. Atenção às sombras, Kael."
		],
		"repeat": [
			"Sombras, Kael. Sombra contra sombra."
		]
	},
	"mensageiro_solaria": {
		"name": "Mensageiro Ferido",
		"portrait": "dialog-portrait-Brugaves",
		"first": [
			"Você... você subiu até aqui? Solaria está ADENTRO, no salão do Trono Monumental.",
			"Aurius nos enganou por eras com a luz roubada de um deus despedaçado. Termine o que os antigos começaram.",
			"Estas colunas douradas guardam o caminho. Vá. Termine."
		],
		"repeat": [
			"O trono espera. E Aurius o espera mais."
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
