extends Node2D

## Arena de batalha no molde Sea of Stars (decisão 2026-08-31, opção 3):
## sem grid tático. Overlay IN-PLACE sobre a exploração (GDD §6.2), turnos por
## agilidade (TurnOrderManager), menu Atacar/Magia/Fugir + Timed Hit/Block.
## Lógica no ArenaCombat (puro, headless-testável); esta cena só apresenta.

const ArenaCombatLib := preload("res://scripts/arena_combat.gd")
const MotionLib := preload("res://scripts/sprite_motion_library.gd")
const EnemyDatabaseLib := preload("res://scripts/enemy_database.gd")

signal battle_ended(victory: bool, rewards: Dictionary)
signal battle_fled()

var combat  # ArenaCombat (núcleo puro)
var combatants: Array = []  # Unit (contrato: get_speed/is_player_side/is_alive)
var enemies_meta: Array = []  # [{type, soul_ether}] para recompensas
var turn_queue: Array = []
var turn_index: int = 0
var current_actor = null

# Timed hit / block (mesma mecânica do timed_combat_system, GDD §3.1)
var _timed_hit_active := false
var _timed_hit_start := 0.0
var _pending_target = null
var _pending_is_magic := false
var _block_window_open := false
var _block_start := 0.0
var _block_reduction := 0.0

# UI
var action_menu: VBoxContainer
var turn_label: Label
var log_label: Label
var result_panel: Control  # result screen dedicada (AUDIT 7d)
var result_title: Label
var result_rewards: Label
var result_continue: Button
var _result_shown := false
var _pending_victory := false
var _pending_rewards := {}
var _hp_labels: Dictionary = {}  # unit -> Label
var _animators: Dictionary = {}  # instance_id -> UnitAnimator
var _current_enemy_type: String = ""  # tipo do inimigo sendo posicionado (SoS) (P0-2: key por instância)
var _home_positions: Dictionary = {}  # instance_id -> Vector2 (destino da entrada)
var combo_system  # ComboSystem (GDD §3.3): CP no HUD da arena
var balance_system  # BalanceSystem (GDD §3.3): barra Éter/Fúria no HUD
var _combo_label: Label
var _balance_bar: ProgressBar
var _balance_legend: Label
var _boss_bar: ProgressBar
var _boss_bar_label: Label
var _boss_panel: PanelContainer
var turn_panel: PanelContainer
var _entrance_tweens: Array = []
var combat_frozen := false  # testes: congela o loop de turnos (IA não age)
var _wave_specs: Array = []  # ondas data-driven (MapDatabase.waves)
var _wave_index := 0
var _charge_specs: Dictionary = {}  # instance_id -> enemy_spell do EnemyDatabase


func _ready() -> void:
 combat = ArenaCombatLib.new()
 _build_arena()
 _setup_from_campaign()
 _entrance_walk()
 if not combat_frozen:
  _start_round()


# --- Setup ---

func _setup_from_campaign() -> void:
 var map_id: int = GameManager.game_data.get("current_map", 0) if GameManager else 0
 var map: Dictionary = MapDatabase.get_map(map_id)
 var stage: Dictionary = GameManager.campaign_system.get_current_stage() if GameManager and GameManager.campaign_system else {}

 # Ondas escaladas (GDD §1 Ato III, decisão ROADMAP #7): mapa declara
 # data-driven. Onda 1 = spawn inicial (abaixo); 2..N reinjetam no _check_end.
 var wave_specs: Array = map.get("waves", [])
 if wave_specs.size() > 0:
  _wave_specs = wave_specs
  _wave_index = 1

 # Balance (#16): stats do Kael derivam do level REAL do ProgressionSystem.
 # Baseline level 1 = números históricos (compatível com testes/estágio 0).
 # Crescimento: hp +14/lv, atk +2/lv, def +1/lv, spd fixo, ether (mp) +5/lv.
 # Elixires permanentes (attack_percent) entram via _recalc_party_atk.
 var kael_lv := 1
 var kael_hp := 80
 var kael_atk := 12
 var kael_def := 8
 var kael_mp := 50
 if GameManager and GameManager.progression_system:
  kael_lv = GameManager.progression_system.get_current_level()
  kael_hp = 80 + 14 * (kael_lv - 1)
  kael_atk = 12 + 2 * (kael_lv - 1)
  kael_def = 8 + 1 * (kael_lv - 1)
  kael_mp = 50 + 5 * (kael_lv - 1)
 if GameManager:
  # Elixires da cozinha (§7.2): bônus PERMANENTES vale na arena também.
  var eb: Dictionary = GameManager.game_data.get("elixir_bonuses", {})
  if eb.has("max_hp"):
   kael_hp += int(eb["max_hp"])
  if eb.has("max_ether"):
   kael_mp += int(eb["max_ether"])
  if eb.has("attack_percent"):
   kael_atk = int(round(float(kael_atk) * (1.0 + float(eb["attack_percent"]) / 100.0)))
 var kael := _make_combatant("Kael", true, kael_hp, kael_atk, kael_def, 11, kael_mp)
 combatants = [kael]
 _arena_position(kael, Vector2(430, 430), Color(0.2, 0.8, 0.3), "kael")

 if GameManager and GameManager.game_data.get("starting_ally") == "kroug":
  # Kroug cresce junto (60% do ganho do Kael): tanque da dupla.
  var kroug_hp := 120 + int(8 * (kael_lv - 1))
  var kroug_atk := 10 + int(1.5 * (kael_lv - 1))
  var kroug := _make_combatant("Kroug", true, kroug_hp, kroug_atk, 15, 8, 20)
  combatants.append(kroug)
  _arena_position(kroug, Vector2(330, 500), Color(0.8, 0.3, 0.1), "kroug")

 # Inimigos: boss_enemy do estágio sobrepõe o pool do mapa (ROADMAP #8).
 # Com ondas declaradas, o spawn inicial segue a composição da onda 1.
 var scale_spawn := 1.0
 var pool: Array
 var count: int
 if _wave_specs.size() > 0:
  var w1: Dictionary = _wave_specs[0]
  pool = w1.get("enemies", ["mercenario"])
  count = pool.size()
  scale_spawn = float(w1.get("stat_scale", 1.0))
 else:
  pool = map.get("enemies", ["mercenario"])
  count = 1 if stage.get("boss", false) else int(map.get("enemy_count", 2))
  if stage.get("boss_enemy", "") != "":
   pool = [stage["boss_enemy"]]
 var pos_x := 860.0
 for i in range(count):
  var type: String = String(pool[i % pool.size()])
  var e: Dictionary = EnemyDatabase.get_enemy(type)
  if e.is_empty():
   continue
  var foe := _make_combatant(e["name"], false,
   int(round(float(e["hp"]) * scale_spawn)), int(round(float(e["atk"]) * scale_spawn)),
   int(round(float(e["def"]) * scale_spawn)), int(round(float(e["spd"]) * scale_spawn)),
   int(e.get("mp", 30)))
  combatants.append(foe)
  if e.has("enemy_spell"):
   _charge_specs[foe.get_instance_id()] = e["enemy_spell"]
  _arena_position(foe, Vector2(pos_x, 400 + i * 130), Color(e["color"]), _sprite_key(e["name"]), type)
  pos_x += 40
  enemies_meta.append({"type": type, "soul_ether": e.get("soul_ether", 10)})

 # Barra do boss visível desde a entrada (não só após o 1º golpe).
 _update_boss_bar()


func _make_combatant(unit_name: String, is_player: bool, hp: int, atk: int, def: int, spd: int, mp: int) -> Unit:
 var u := Unit.new()
 var d := UnitData.new()
 d.unit_name = unit_name
 d.is_player = is_player
 d.max_hp = hp
 d.current_hp = hp
 d.attack = atk
 d.defense = def
 d.speed = spd
 d.max_mp = mp
 d.current_mp = mp
 u.data = d
 u.current_hp = hp
 u.current_mp = mp
 # Dummies para os @onready do Unit ($Sprite2D/$HPBar/$SelectionIndicator),
 # que exigem os nós antes de entrar na árvore. A arte real é adicionada em
 # _arena_position; o HP real é a barra flutuante dali.
 var dummy_sprite := Sprite2D.new()
 dummy_sprite.name = "Sprite2D"
 dummy_sprite.visible = false
 u.add_child(dummy_sprite)
 var dummy_hp := ProgressBar.new()
 dummy_hp.name = "HPBar"
 dummy_hp.visible = false
 u.add_child(dummy_hp)
 var dummy_sel := ColorRect.new()
 dummy_sel.name = "SelectionIndicator"
 dummy_sel.visible = false
 u.add_child(dummy_sel)
 add_child(u)
 return u


func _arena_position(u: Unit, pos: Vector2, color: Color, sprite_key: String, enemy_type: String = "") -> void:
 u.position = pos
 u.visible = true
 _home_positions[u.get_instance_id()] = pos
 _current_enemy_type = enemy_type
 var path := "res://assets/sprites/%s.png" % sprite_key
 var sprite: Sprite2D
 var motion_sets := {}
 # SoS (estudo): jogadores renderizam NarcisKingZale; inimigos usam o
 # personagem SoS mapeado pelo tipo do jogo (mercenario->StrifeMinion etc).
 var sos_char: String = ""
 var sos_dir := 3
 if not u.is_player_side() and _current_enemy_type != "":
  var enemy_sos := {
   "mercenario": "StrifeMinion", "cacador": "Owlsassin", "esqueleto": "BilePile",
   "mago": "Keymouseter", "inquisidor": "Acolyte1", "paladino": "Acolyte4",
   "orc_chefe": "BoulderDouche", "troll": "BoulderGoat",
  }
  sos_char = String(enemy_sos.get(_current_enemy_type, ""))
  sos_dir = 3  # inimigos à direita olham para o lado do jogador (D3=Oeste)
 elif u.is_player_side():
  sos_char = "NarcisKingZale"
  sos_dir = 5
 if sos_char != "":
  motion_sets = SOSMotionLoader.build_motion_sets(sos_char, sos_dir)
 if not motion_sets.is_empty():
  sprite = Sprite2D.new()
  sprite.texture = motion_sets["idle"][0]
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  sprite.scale = Vector2(2.4, 2.4)  # ~31x53 px fonte -> ~75x127 na arena
  sprite.offset = Vector2(0, -8)
 elif FileAccess.file_exists(path):
  var img := Image.new()
  if img.load(path) == OK:
   motion_sets = MotionLib.build_motion_sets(img)
   sprite = Sprite2D.new()
   # Frame 0 do idle (256px); UnitAnimator cicla a partir daqui.
   sprite.texture = motion_sets["idle"][0]
   sprite.scale = Vector2(0.09, 0.09) * (float(img.get_width()) / float(MotionLib.FRAME_SIZE))
  else:
   sprite = _fallback_sprite(color)
 else:
  sprite = _fallback_sprite(color)
 u.add_child(sprite)

 # Barra de HP flutuante (molde SoS: HP visível sobre o combatente).
 var bar := ProgressBar.new()
 bar.min_value = 0
 bar.max_value = u.data.max_hp
 bar.value = u.current_hp
 bar.position = Vector2(-30, -62)
 bar.size = Vector2(60, 8)
 bar.show_percentage = false
 # Borda escura: legibilidade sobre sprites claros (screenshot QA).
 var bar_bg := StyleBoxFlat.new()
 bar_bg.bg_color = Color(0.1, 0.1, 0.12, 0.85)
 bar_bg.set_border_width_all(1)
 bar_bg.border_color = Color(0, 0, 0, 0.9)
 bar.add_theme_stylebox_override("background", bar_bg)
 var bar_fill := StyleBoxFlat.new()
 bar_fill.bg_color = Color(0.3, 0.85, 0.35) if u.is_player_side() else Color(0.85, 0.3, 0.3)
 bar.add_theme_stylebox_override("fill", bar_fill)
 u.add_child(bar)
 u.hp_changed.connect(func(hp): bar.value = hp)

 # Animador (idle respirando; lunge/hit/death/victory nos eventos).
 var animator := UnitAnimator.new()
 u.add_child(animator)
 animator.setup(u)
 animator.set_frames(motion_sets)
 animator.play_idle()
 _animators[u.get_instance_id()] = animator


func _animator_for(u) -> UnitAnimator:
 if u == null or not _animators.has(u.get_instance_id()):
  return null
 return _animators[u.get_instance_id()]


## Entrada no molde SoS: cada grupo caminha até sua posição de arena
## (jogadores pela esquerda, inimigos pela direita).
func _entrance_walk() -> void:
 for u in combatants:
  var animator := _animator_for(u)
  var target: Vector2 = _home_positions[u.get_instance_id()]
  var from_x: float = -80.0 if u.is_player_side() else 1360.0
  u.position = Vector2(from_x, target.y)
  if animator:
   animator.current_animation = "walk"
   animator.face_direction(target.x - from_x)
   animator.set_moving(true)  # passada real (frames) durante a entrada
  var tween := create_tween()
  _entrance_tweens.append(tween)
  tween.tween_property(u, "position", target, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  if animator and animator.sprite:
   tween.parallel().tween_property(animator.sprite, "rotation", 0.08, 0.45)
   tween.tween_property(animator.sprite, "rotation", 0.0, 0.45)
  tween.finished.connect(_on_entrance_finished.bind(animator))


func _on_entrance_finished(animator) -> void:
 if animator:
  animator.current_animation = "idle"
  animator.set_moving(false)


## Mata os tweens de entrada e encaixa todos nos destinos (evita conflito de
## tween quando o primeiro golpe sai durante a caminhada).
func _finish_entrance() -> void:
 for t in _entrance_tweens:
  if t.is_valid():
   t.kill()
 _entrance_tweens.clear()
 for u in combatants:
  if _home_positions.has(u.get_instance_id()):
   u.position = _home_positions[u.get_instance_id()]
   var animator := _animator_for(u)
   if animator and animator.current_animation == "walk":
    animator.current_animation = "idle"
    animator.set_moving(false)


func _sprite_key(unit_name: String) -> String:
 var key := unit_name.to_lower()
 for pair in [["—", ""], ["'", ""], ["á", "a"], ["é", "e"], ["ê", "e"], ["â", "a"], ["ã", "a"], ["õ", "o"], ["ô", "o"], ["í", "i"], ["ú", "u"], ["ç", "c"], [" ", "_"]]:
  key = key.replace(pair[0], pair[1])
 while "__" in key:
  key = key.replace("__", "_")
 return key


func _fallback_sprite(color: Color) -> Sprite2D:
 var s := Sprite2D.new()
 var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
 img.fill(Color(0, 0, 0, 0))
 for y in range(6, 22):
  for x in range(6, 18):
   img.set_pixel(x, y, color)
 s.texture = ImageTexture.create_from_image(img)
 return s


# --- Fluxo de turnos (velocity-based, igual TurnOrderManager) ---

func _start_round() -> void:
 turn_queue = combat.build_turn_order(combatants)
 turn_index = 0
 _next_turn()


func _next_turn() -> void:
 if _check_end():
  return
 while turn_index < turn_queue.size() and not turn_queue[turn_index].is_alive():
  turn_index += 1
 if turn_index >= turn_queue.size():
  _start_round()
  return
 current_actor = turn_queue[turn_index]
 _update_turn_label()
 _face_toward_enemies(current_actor)
 if current_actor.is_player_side():
  _show_action_menu(true)
 else:
  _enemy_act()


## Todos encaram o campo do time oposto (SoS: sprites sempre de frente).
func _face_toward_enemies(actor) -> void:
 for u in combatants:
  var animator := _animator_for(u)
  if animator == null:
   continue
  var facing: float = 1.0 if u.is_player_side() else -1.0
  # Ator atual olha o alvo imediato, não só o "lado do time".
  if u == actor:
   var foes := combatants.filter(func(t): return t.is_alive() and t.is_player_side() != actor.is_player_side())
   if not foes.is_empty():
    facing = signf(foes[0].position.x - u.position.x)
  animator.face_direction(facing)


func _advance() -> void:
 turn_index += 1
 _next_turn()


func _check_end() -> bool:
 var result: String = combat.is_battle_over(combatants)
 if result == "":
  return false
 # Ondas escaladas (Ato III): vitória com onda pendente reinjeta a próxima —
 # false mantém o loop de turnos vivo (round seguinte traz os reforços).
 if result == "victory" and _wave_index < _wave_specs.size():
  _spawn_next_wave()
  return false
 _finish(result == "victory")
 return true


func _finish(victory: bool) -> void:
 if _result_shown:
  return
 _result_shown = true
 _show_action_menu(false)
 var rewards := {"soul_ether": 0, "gold": 0, "experience": 0}
 if victory:
  for m in enemies_meta:
   rewards["soul_ether"] += m["soul_ether"]
  # Economia (balance campanha): ouro e XP somam do soul_ether da luta
  # (ouro = 50%, XP = 40%). Batalha é a fonte primária de progresso;
  # puzzles/traversal pagam por cima como bônus de exploração.
  rewards["gold"] = int(rewards["soul_ether"] * 0.5)
  rewards["experience"] = int(rewards["soul_ether"] * 0.4)
  # Materiais de forja: chance por inimigo derrotado (comum 40%).
  var materials := 0
  for m in enemies_meta:
   if randf() < 0.4:
    materials += 1
  if materials > 0:
   rewards["materials"] = materials
  # Vitória: sobreviventes celebram. (Derrota não anima: is_battle_over
  # só encerra com a party inteira morta — o luto é da result screen.)
  for u in combatants:
   if u.is_player_side() and u.is_alive() and _animator_for(u):
    _animator_for(u).play_victory()
 _log("VITÓRIA!" if victory else "DERROTA...")
 _show_result_screen(victory, rewards)


# --- Result screen dedicada (molde SoS) ---
# O sinal battle_ended só dispara quando o jogador clica "Continuar" — a
# campanha avança DEPOIS que o resultado é visto.

func _show_result_screen(victory: bool, rewards: Dictionary) -> void:
 _pending_victory = victory
 _pending_rewards = rewards
 result_panel = PanelContainer.new()
 result_panel.position = Vector2(420, 230)
 result_panel.custom_minimum_size = Vector2(440, 260)
 var vbox := VBoxContainer.new()
 vbox.add_theme_constant_override("separation", 12)
 result_panel.add_child(vbox)

 result_title = Label.new()
 result_title.text = "VITÓRIA!" if victory else "DERROTA..."
 result_title.add_theme_font_size_override("font_size", 42)
 result_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if victory else Color(0.9, 0.3, 0.3))
 result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 vbox.add_child(result_title)

 result_rewards = Label.new()
 result_rewards.text = "\n".join(PackedStringArray(_result_lines(victory, rewards)))
 result_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 vbox.add_child(result_rewards)

 result_continue = Button.new()
 result_continue.text = "Continuar"
 result_continue.pressed.connect(_on_result_continue_pressed)
 vbox.add_child(result_continue)

 add_child(result_panel)
 result_panel.modulate.a = 0.0
 var tween := create_tween()
 tween.tween_property(result_panel, "modulate:a", 1.0, 0.25)


func _result_lines(victory: bool, rewards: Dictionary) -> Array:
 if not victory:
  return ["A cinza reclama outro corpo...", "Retorne pelo menu para tentar de novo."]
 var lines := []
 if int(rewards.get("soul_ether", 0)) > 0:
  lines.append("+%d Soul Éter" % int(rewards["soul_ether"]))
 if int(rewards.get("gold", 0)) > 0:
  lines.append("+%d ouro" % int(rewards["gold"]))
 if int(rewards.get("experience", 0)) > 0:
  lines.append("+%d XP" % int(rewards["experience"]))
 lines.append("O caminho segue adiante...")
 return lines


func _on_result_continue_pressed() -> void:
 if not _result_shown:
  return
 _result_shown = false
 if result_panel:
  result_panel.queue_free()
  result_panel = null
 battle_ended.emit(_pending_victory, _pending_rewards)


func result_visible() -> bool:
 return result_panel != null and is_instance_valid(result_panel) and result_panel.visible


## Reinjeta a próxima onda (2..N): inimigos com stats escalados por stat_scale,
## entrando pela mesma porta do spawn normal (factory + posição de arena).
## Contrato: _wave_index = próxima onda a reinjetar (1-based; 1 = spawn inicial).
func _spawn_next_wave() -> void:
 var wave: Dictionary = _wave_specs[_wave_index]
 _wave_index += 1
 var scale: float = float(wave.get("stat_scale", 1.0 + 0.25 * _wave_index))
 var pos_x := 900.0
 for type in wave.get("enemies", []):
  var e: Dictionary = EnemyDatabase.get_enemy(String(type))
  if e.is_empty():
   continue
  var foe := _make_combatant("%s (Onda %d)" % [e["name"], _wave_index], false,
   int(round(float(e["hp"]) * scale)), int(round(float(e["atk"]) * scale)),
   int(round(float(e["def"]) * scale)), int(round(float(e["spd"]) * scale)),
   int(e.get("mp", 30)))
  combatants.append(foe)
  if e.has("enemy_spell"):
   _charge_specs[foe.get_instance_id()] = e["enemy_spell"]
  _arena_position(foe, Vector2(pos_x, 380 + (_wave_index % 2) * 90), Color(e["color"]), _sprite_key(e["name"]), String(type))
  pos_x += 40
  enemies_meta.append({"type": String(type), "soul_ether": int(e.get("soul_ether", 10))})
 _log("ONDA %d/%d entra na arena!" % [_wave_index, _wave_specs.size()])


# --- Ações do jogador ---

func _show_action_menu(show: bool) -> void:
 action_menu.visible = show
 if show:
  _log("Vez de %s" % current_actor.data.unit_name)


func _on_attack_pressed() -> void:
 if not _can_player_act():
  return
 _show_action_menu(false)
 _pending_is_magic = false
 _begin_timed_hit()


func _on_magic_pressed() -> void:
 if not _can_player_act():
  return
 if current_actor.current_mp < ArenaCombatLib.MAGIC_COST:
  _log("MP insuficiente!")
  return
 _show_action_menu(false)
 _pending_is_magic = true
 _begin_timed_hit()


func _on_flee_pressed() -> void:
 if not _can_player_act():
  return
 _show_action_menu(false)
 if randf() < 0.5:
  _log("Fuga bem-sucedida!")
  battle_fled.emit()
 else:
  _log("A fuga falhou!")
  _advance()


func _can_player_act() -> bool:
 return current_actor != null and current_actor.is_player_side() and action_menu.visible


func _begin_timed_hit() -> void:
 # Alvo: inimigo vivo de menor HP (foca kill, espelho da IA). Canalizador
 # de feitiço tem prioridade: os locks visíveis atraem o golpe (GDD §3.2).
 var foes := combatants.filter(func(u): return u.is_alive() and not u.is_player_side())
 if foes.is_empty():
  _advance()
  return
 foes.sort_custom(func(a, b): return a.current_hp < b.current_hp)
 var charging := foes.filter(func(u): return combat.is_charging(u))
 _pending_target = charging[0] if charging.size() > 0 else foes[0]
 _show_tutorial_if_first()
 _timed_hit_active = true
 _timed_hit_start = Time.get_ticks_msec() / 1000.0
 _log("TIMED HIT! Clique no impacto!")
 await get_tree().create_timer(ArenaCombatLib.TIMED_HIT_WINDOW).timeout
 if _timed_hit_active:
  _resolve_action(1.0, "MISS")


func _input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  if _timed_hit_active:
   var elapsed := (Time.get_ticks_msec() / 1000.0) - _timed_hit_start
   var grade = combat.timed_combat.resolve_timing(elapsed)
   _timed_hit_active = false
   _resolve_action(grade.multiplier, grade.grade)
  elif _block_window_open:
   var elapsed := (Time.get_ticks_msec() / 1000.0) - _block_start
   var result = combat.timed_combat.resolve_block_timing(elapsed)
   _block_reduction = combat.timed_combat.get_block_reduction(result)
   _block_window_open = false
   _log("BLOCK %s!" % result.grade)


func _resolve_action(multiplier: float, grade: String) -> void:
 if _pending_target == null or not _pending_target.is_alive():
  _advance()
  return
 var attacker_anim := _animator_for(current_actor)
 if attacker_anim:
  if _pending_is_magic:
   await attacker_anim.play_magic_cast()
  else:
   await attacker_anim.play_attack(_pending_target)
 var damage: int
 if _pending_is_magic:
  var cast: Dictionary = combat.cast_damage_spell(current_actor, _pending_target)
  if not cast.success:
   _log("MP insuficiente!")
   _advance()
   return
  damage = int(cast.damage * multiplier)
 else:
  damage = combat.calculate_damage(current_actor, _pending_target, multiplier)
 combat.apply_hit(current_actor, _pending_target, damage)
 _pending_target.hp_changed.emit(_pending_target.current_hp)
 if SoundManager:
  SoundManager.play_magic() if _pending_is_magic else SoundManager.play_hit()
 # Cast com locks (GDD §3.2): golpe no canalizador dentes o lock do canal
 # (físico = Corte, magia = Éter). Quebrar todos = spellbreak (stun + CP).
 if combat.is_charging(_pending_target):
  var atk_type := ArenaCombatLib.PLAYER_MAGIC_TYPE if _pending_is_magic else ArenaCombatLib.PLAYER_PHYSICAL_TYPE
  var lock_result: Dictionary = combat.hit_charge(_pending_target, atk_type)
  if lock_result["interrupted"]:
   _log("SPELLBREAK! Feitiço de %s interrompido — stun!" % _pending_target.data.unit_name)
   if combo_system:
    combo_system.add_cp(2)  # spellbreak paga CP como no grid (GDD §3.3)
   if SoundManager:
    SoundManager.play_lock_break()
  elif lock_result["hit"]:
   _log("Lock de %s atingido!" % _pending_target.data.unit_name)
   if SoundManager:
    SoundManager.play_lock_hit()
 # HUD: feedback de CP/Éter-Fúria e barra do boss.
 if current_actor.is_player_side():
  _award_hit_feedback(grade)
 else:
  _update_boss_bar()
 _spawn_damage_number(_pending_target.position + Vector2(0, -70), damage, grade)
 _log("%s → %s: %d de dano (%s)" % [current_actor.data.unit_name, _pending_target.data.unit_name, damage, grade])
 grade_last_hit = grade
 await _play_aftermath(_pending_target)
 _pending_target = null
 _advance()


func _play_aftermath(target) -> void:
 var target_anim := _animator_for(target)
 if target_anim == null:
  return
 if target.is_alive():
  await target_anim.play_hit()
  if grade_last_hit != "MISS":
   # Knockback sutil (SoS): recua na direção oposta ao atacante e volta.
   var push: float = signf(target.position.x - current_actor.position.x) * 12.0
   var home: Vector2 = _home_positions[target.get_instance_id()]
   var kb := create_tween()
   kb.tween_property(target, "position:x", home.x + push, 0.08)
   kb.tween_property(target, "position:x", home.x, 0.22)
  if grade_last_hit == "PERFECT":
   _shake_camera(5.0)  # PERFECT: shake médio
 else:
  await target_anim.play_death()
  _shake_camera(8.0)  # morte: shake forte
  _flash_screen(Color(1.0, 0.9, 0.8, 0.25))
 # Fúria (GDD §3.3): morte de inimigo pela mão do jogador = execução.
 if not target.is_alive() and target.is_player_side() == false:
  if current_actor != null and current_actor.is_player_side() and balance_system:
   balance_system.perform_fury_action("execute")
 _update_boss_bar()


var grade_last_hit: String = ""

## Screen shake curto no root da arena (game feel, molde SoS).
func _shake_camera(strength: float) -> void:
 var original := position
 var tween := create_tween()
 for i in range(4):
  var offset := Vector2(rng_shake.randf_range(-strength, strength), rng_shake.randf_range(-strength, strength))
  tween.tween_property(self, "position", original + offset, 0.04)
 tween.tween_property(self, "position", original, 0.05)

var rng_shake := RandomNumberGenerator.new()

## Flash de tela sobre tudo (impacto de morte/crítico).
func _flash_screen(color: Color) -> void:
 var flash := ColorRect.new()
 flash.color = color
 flash.size = Vector2(1280, 720)
 flash.z_index = 100
 flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(flash)
 var tween := create_tween()
 tween.tween_property(flash, "color:a", 0.0, 0.18)
 tween.tween_callback(flash.queue_free)


# --- IA inimiga ---

func _enemy_act() -> void:
 if _check_end():
  return
 var players := combatants.filter(func(u): return u.is_alive() and u.is_player_side())
 var target = combat.choose_enemy_target(players)
 if target == null:
  return
 if combat.tick_stun(current_actor):
  _log("%s está atordoado! (spellbreak)" % current_actor.data.unit_name)
  _advance()
  return
 # Já canalizando: tick do contador. Feitiço sai ao zerar (estado limpo
 # no tick — captura antes para saber nome/dano do feitiço lançado).
 var charge: Dictionary = combat.get_charge(current_actor)
 var tick: String = combat.tick_charge(current_actor)
 if tick == "casting":
  _log("%s lança %s!" % [current_actor.data.unit_name, charge.get("spell_name", "Feitiço")])
  var damage: int = int(charge.get("damage", 0))
  combat.apply_hit(current_actor, target, damage)
  target.hp_changed.emit(target.current_hp)
  _log("%s sofreu %d de dano" % [target.data.unit_name, damage])
  await _play_aftermath(target)
  if not _check_end():
   _advance()
  return
 elif tick == "charging":
  var locks_left: int = 0
  for lock in charge.get("locks", []):
   if lock["remaining"] > 0:
    locks_left += 1
  _log("%s canaliza %s — quebre os locks! (%d restantes)" % [current_actor.data.unit_name, charge.get("spell_name", "Feitiço"), locks_left])
  _advance()
  return
 # Não canaliza: caster com feitiço declarado e MP inicia o canal (GDD §3.2).
 var spec: Dictionary = _charge_specs.get(current_actor.get_instance_id(), {})
 if not spec.is_empty() and current_actor.current_mp >= ArenaCombatLib.MAGIC_COST:
  current_actor.current_mp -= ArenaCombatLib.MAGIC_COST
  combat.start_charge(current_actor, spec)
  _log("%s começa a canalizar %s! Ataque com o tipo certo!" % [current_actor.data.unit_name, spec.get("name", "Feitiço")])
  _show_tutorial_if_first("enemy_spell")
  _show_tutorial_if_first("lock")
  _advance()
  return
 # Janela de defesa reativa (timed block) durante o golpe inimigo.
 var actor_anim := _animator_for(current_actor)
 if actor_anim:
  await actor_anim.play_attack(target)
 _block_window_open = true
 _block_start = Time.get_ticks_msec() / 1000.0
 _block_reduction = 0.0
 _log("%s ataca! Clique para bloquear!" % current_actor.data.unit_name)
 _show_tutorial_if_first("block")
 await get_tree().create_timer(ArenaCombatLib.TIMED_BLOCK_WINDOW).timeout
 _block_window_open = false
 var damage: int = combat.calculate_damage(current_actor, target)
 damage = int(damage * (1.0 - _block_reduction))
 combat.apply_hit(current_actor, target, damage)
 target.hp_changed.emit(target.current_hp)
 _log("%s sofreu %d de dano" % [target.data.unit_name, damage])
 await _play_aftermath(target)
 if not _check_end():
  _advance()


# --- UI (overlay in-place, sem .tscn) ---

func _build_arena() -> void:
 var dim := ColorRect.new()
 dim.color = Color(0.02, 0.02, 0.04, 0.55)
 dim.size = Vector2(1280, 720)
 add_child(dim)

 var floor_rect := ColorRect.new()
 floor_rect.color = Color(0.13, 0.11, 0.16, 0.9)
 floor_rect.position = Vector2(140, 280)
 floor_rect.size = Vector2(1000, 380)
 add_child(floor_rect)

 # Palco (molde SoS): elipses de "chão" sob cada grupo em vez do vazio.
 for g in [
  {"x": 430.0, "y": 470.0, "w": 320.0, "h": 180.0, "c": Color(0.2, 0.17, 0.25)},
  {"x": 880.0, "y": 470.0, "w": 360.0, "h": 200.0, "c": Color(0.17, 0.13, 0.22)},
 ]:
  var grad := Gradient.new()
  grad.set_color(0, Color(g["c"].r, g["c"].g, g["c"].b, 0.9))
  grad.set_color(1, Color(0, 0, 0, 0))
  var gtex := GradientTexture2D.new()
  gtex.gradient = grad
  gtex.fill = GradientTexture2D.FILL_RADIAL
  gtex.fill_from = Vector2(0.5, 0.5)
  gtex.fill_to = Vector2(0.5, 0.0)
  gtex.width = 128
  gtex.height = 72
  var ground := Sprite2D.new()
  ground.texture = gtex
  ground.position = Vector2(g["x"], g["y"])
  ground.scale = Vector2(g["w"] / 128.0, g["h"] / 72.0)
  add_child(ground)

 # Brasas subindo (lore das Cinzas): partículas laranja lentas com fade.
 var embers := CPUParticles2D.new()
 embers.amount = 14
 embers.lifetime = 4.0
 embers.preprocess = 4.0
 embers.position = Vector2(640, 620)
 embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
 embers.emission_rect_extents = Vector2(600, 30)
 embers.direction = Vector2(0, -1)
 embers.spread = 12.0
 embers.gravity = Vector2(0, -12)
 embers.initial_velocity_min = 6.0
 embers.initial_velocity_max = 18.0
 embers.scale_amount_min = 1.2
 embers.scale_amount_max = 2.6
 embers.color = Color(1.0, 0.55, 0.2, 0.45)
 add_child(embers)

 turn_label = Label.new()
 turn_label.position = Vector2(24, 16)
 turn_label.add_theme_font_size_override("font_size", 22)
 # Painel de fundo: legibilidade sobre qualquer cenário.
 turn_panel = PanelContainer.new()
 var turn_style := StyleBoxFlat.new()
 turn_style.bg_color = Color(0.06, 0.06, 0.1, 0.72)
 turn_style.set_corner_radius_all(6)
 turn_style.set_content_margin_all(8)
 turn_style.border_color = Color(0.5, 0.45, 0.3, 0.6)
 turn_style.set_border_width_all(1)
 turn_panel.add_theme_stylebox_override("panel", turn_style)
 turn_panel.add_child(turn_label)
 turn_panel.position = Vector2(16, 10)
 add_child(turn_panel)

 log_label = Label.new()
 log_label.position = Vector2(20, 668)
 log_label.add_theme_font_size_override("font_size", 18)
 # Sombra de texto no log (contraste sobre sprites claros).
 log_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
 log_label.add_theme_constant_override("shadow_offset_x", 1)
 log_label.add_theme_constant_override("shadow_offset_y", 1)
 add_child(log_label)

 action_menu = VBoxContainer.new()
 action_menu.position = Vector2(40, 320)
 action_menu.add_theme_constant_override("separation", 12)
 add_child(action_menu)

 var atk_btn := Button.new()
 atk_btn.text = "Atacar"
 atk_btn.pressed.connect(_on_attack_pressed)
 action_menu.add_child(atk_btn)

 var magic_btn := Button.new()
 magic_btn.text = "Magia (%d MP)" % ArenaCombatLib.MAGIC_COST
 magic_btn.pressed.connect(_on_magic_pressed)
 action_menu.add_child(magic_btn)

 var flee_btn := Button.new()
 flee_btn.text = "Fugir"
 flee_btn.pressed.connect(_on_flee_pressed)
 action_menu.add_child(flee_btn)

 action_menu.visible = false

 _build_combat_hud()


# --- HUD de combate (Combo Points + Éter/Fúria + Boss HP) ---

func _build_combat_hud() -> void:
 combo_system = load("res://scripts/combo_system.gd").new()
 balance_system = load("res://scripts/balance_system.gd").new()
 combo_system.cp_changed.connect(func(_c, _m): _update_cp_pips())
 balance_system.ether_changed.connect(func(_v): _update_balance_bar())
 balance_system.fury_changed.connect(func(_v): _update_balance_bar())

 # Painel esquerdo (CP + Éter/Fúria) num único quadro estilizado.
 var hud_panel := PanelContainer.new()
 var hud_style := StyleBoxFlat.new()
 hud_style.bg_color = Color(0.06, 0.06, 0.1, 0.72)
 hud_style.set_corner_radius_all(6)
 hud_style.set_content_margin_all(10)
 hud_style.border_color = Color(0.5, 0.45, 0.3, 0.6)
 hud_style.set_border_width_all(1)
 hud_panel.add_theme_stylebox_override("panel", hud_style)
 hud_panel.position = Vector2(16, 66)
 var hud_vbox := VBoxContainer.new()
 hud_vbox.add_theme_constant_override("separation", 4)
 hud_panel.add_child(hud_vbox)
 add_child(hud_panel)

 _combo_label = Label.new()
 _combo_label.add_theme_font_size_override("font_size", 16)
 hud_vbox.add_child(_combo_label)
 _update_cp_pips()

 _balance_bar = ProgressBar.new()
 _balance_bar.custom_minimum_size = Vector2(160, 14)
 _balance_bar.max_value = 100
 _balance_bar.show_percentage = false
 # Fúria atrás (vermelho), Éter preenche da esquerda (azul): leitura bipolar.
 var bg := StyleBoxFlat.new()
 bg.bg_color = Color(0.5, 0.15, 0.15)
 _balance_bar.add_theme_stylebox_override("background", bg)
 var fill := StyleBoxFlat.new()
 fill.bg_color = Color(0.25, 0.45, 0.85)
 _balance_bar.add_theme_stylebox_override("fill", fill)
 hud_vbox.add_child(_balance_bar)
 _balance_legend = Label.new()
 _balance_legend.add_theme_font_size_override("font_size", 12)
 _balance_legend.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
 _balance_legend.text = "ÉTER / FÚRIA"
 hud_vbox.add_child(_balance_legend)

 # Painel do boss (barra + nome) no topo centro.
 _boss_panel = PanelContainer.new()
 var boss_style := StyleBoxFlat.new()
 boss_style.bg_color = Color(0.06, 0.06, 0.1, 0.72)
 boss_style.set_corner_radius_all(6)
 boss_style.set_content_margin_all(8)
 boss_style.border_color = Color(0.8, 0.3, 0.3, 0.7)
 boss_style.set_border_width_all(1)
 _boss_panel.add_theme_stylebox_override("panel", boss_style)
 var boss_vbox := VBoxContainer.new()
 boss_vbox.add_theme_constant_override("separation", 3)
 _boss_panel.add_child(boss_vbox)
 _boss_panel.position = Vector2(420, 12)
 _boss_panel.visible = false
 add_child(_boss_panel)

 _boss_bar = ProgressBar.new()
 _boss_bar.custom_minimum_size = Vector2(440, 16)
 _boss_bar.max_value = 1
 _boss_bar.value = 1
 _boss_bar.show_percentage = false
 var boss_fill := StyleBoxFlat.new()
 boss_fill.bg_color = Color(0.85, 0.2, 0.2)
 _boss_bar.add_theme_stylebox_override("fill", boss_fill)
 boss_vbox.add_child(_boss_bar)
 _boss_bar_label = Label.new()
 _boss_bar_label.add_theme_font_size_override("font_size", 13)
 _boss_bar_label.visible = false
 boss_vbox.add_child(_boss_bar_label)


func _update_cp_pips() -> void:
 if combo_system == null or _combo_label == null:
  return
 var current: int = combo_system.get_cp()
 var pips := ""
 for i in range(3):
  pips += "◆" if i < current else "◇"
 _combo_label.text = "CP %s" % pips
 _combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2) if current > 0 else Color(0.6, 0.6, 0.6))


func _update_balance_bar() -> void:
 if balance_system == null or _balance_bar == null:
  return
 # Barra bipolar: Éter empurra para a direita sobre a Fúria de fundo.
 _balance_bar.value = balance_system.get_ether()
 _balance_bar.tooltip_text = "Éter %d / Fúria %d" % [balance_system.get_ether(), balance_system.get_fury()]


func _update_boss_bar() -> void:
 var boss = null
 for u in combatants:
  if u.is_alive() and not u.is_player_side() and _is_boss_unit(u):
   boss = u
   break
 if boss == null:
  _boss_panel.visible = false
  _boss_bar_label.visible = false
  return
 _boss_bar.max_value = boss.data.max_hp
 _boss_bar.value = boss.current_hp
 _boss_panel.visible = true
 _boss_bar_label.visible = true
 _boss_bar_label.text = "%s — HP %d/%d" % [boss.data.unit_name, boss.current_hp, boss.data.max_hp]


func _is_boss_unit(u) -> bool:
 for meta in enemies_meta:
  var foe: Dictionary = EnemyDatabaseLib.get_enemy(String(meta["type"]))
  if not foe.is_empty() and foe.get("ai_type", "") == "boss" and u.data.unit_name == foe["name"]:
   return true
 return false


## Tutorial contextual (2 primeiras lutas): dicas acionáveis no momento de
## uso, mostradas 1x por chave (flag persistida em game_data["tutorials"]).
func _show_tutorial_if_first(key: String = "timed_hit") -> void:
 if GameManager == null or GameManager.game_data.get("tutorials", {}).get(key, false):
  return
 GameManager.game_data.get_or_add("tutorials", {})[key] = true
 var tips := {
  "timed_hit": "TUTORIAL: clique no ALVO quando a barra carregar para acertar (PERFECT = mais dano + CP)!",
  "block": "TUTORIAL: quando um inimigo atacar, CLIQUE rápido para bloquear parte do dano!",
  "lock": "TUTORIAL: inimigo canalizando? ATAQUE-o com o tipo certo (físico=Corte, magia=Éter) para quebrar os locks!",
  "enemy_spell": "TUTORIAL: o inimigo vai lançar um feitiço — quebre os locks com o tipo certo do seu ataque!",
 }
 if tips.has(key):
  _log(tips[key])
  if SoundManager:
   SoundManager.play_select()


func _spawn_damage_number(pos: Vector2, damage: int, grade: String) -> void: ## Número de dano flutuante: sobe e some (feedback direto, molde SoS).
 var label := Label.new()
 label.text = str(damage)
 label.add_theme_font_size_override("font_size", 26 if grade == "PERFECT" else 20)
 match grade:
  "PERFECT":
   label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
  "MISS":
   label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
  _:
   label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
 label.z_index = 50
 label.position = pos
 add_child(label)
 var tween := create_tween()
 tween.tween_property(label, "position:y", pos.y - 46.0, 0.6)
 tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.25)
 tween.tween_callback(label.queue_free)


## Feedback de combate (GDD §3.3): PERFECT ganha CP + buff_ally (Éter);
## demais graus, buff_ally leve. Mortes de inimigo por mão do jogador
## alimentam a Fúria (execute). Boss na mira atualiza a barra.
func _award_hit_feedback(grade: String) -> void:
 if combo_system == null or balance_system == null:
  return
 if grade == "PERFECT":
  combo_system.add_cp(1)
  balance_system.perform_ether_action("buff_ally")
 elif grade != "MISS":
  balance_system.perform_ether_action("buff_ally")
 _update_boss_bar()


func _update_turn_label() -> void:
 turn_label.text = "Agindo: %s (HP %d/%d)" % [
  current_actor.data.unit_name, current_actor.current_hp, current_actor.data.max_hp]


func _log(msg: String) -> void:
 log_label.text = msg
