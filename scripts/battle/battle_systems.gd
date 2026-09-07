extends RefCounted
## Handlers de sistemas do battle_scene (P2 #13e — extração do god file).
## Kaelen HUD, balance/CP UI, boss bar, HUD de progressão, formas (§8), forja,
## cozinha, taverna, travessia e combo. Acessa a cena dona via `battle`.

var battle: Node2D


func _on_tutorial_message(message: String, position: Vector2) -> void:
 # Mostrar mensagem do tutorial
 var label = Label.new()
 label.text = message
 label.position = position - Vector2(200, 20)
 label.z_index = 150
 label.add_theme_font_size_override("font_size", 16)
 label.add_theme_color_override("font_color", Color.WHITE)
 label.add_theme_color_override("font_shadow_color", Color("#000000"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.custom_minimum_size = Vector2(400, 0)

 battle.ui_layer.add_child(label)

 # Auto-remover após 3 segundos
 await battle.get_tree().create_timer(3.0).timeout
 if is_instance_valid(label):
  label.queue_free()

# === Sinal handlers para sistemas avançados ===

func _on_combo_activated(combo_name: String, description: String) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 300), "COMBO: " + combo_name)
 battle.combat_feedback.show_status_effect(Vector2(640, 340), description)
 battle.combat_feedback.shake_medium()
 SoundManager.play_hit()
 update_combo_ui()

## §3.2-3.3 Quebra de lock gera CP (2 por lock, GDD via resolve_spellbreak).
func _on_lock_broken(_enemy, _lock: Dictionary) -> void:
 battle.combo_system.earn_from_lock_break()
 update_combo_ui()
 battle.combat_feedback.show_status_effect(Vector2(640, 300), "LOCK QUEBRADO (+2 CP)")

## §3.2 Cast inimigo anunciado: locks visíveis + aviso de conjuração.
func _on_enemy_cast_started(enemy, spell_name: String, _locks: Array, _turns: int) -> void:
 if enemy is Node2D and enemy.is_inside_tree():
  battle.combat_feedback.show_status_effect(enemy.global_position + Vector2(0, -40), "CONJURANDO: " + spell_name)
 else:
  battle.combat_feedback.show_status_effect(Vector2(640, 200), "PERIGO: " + spell_name + " se preparando!")
 battle.combat_feedback.shake_light()

## §3.2 Spellbreak: todos os locks quebrados → inimigo atordoado.
func _on_enemy_spellbreak(_enemy) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 200), "SPELLBREAK! INIMIGO ATORDOADO!")
 battle.combat_feedback.shake_medium()

## §3.4 Kaelen System — handlers de sinais
func _on_kaelen_target_analyzed(target_name: String, data: Dictionary) -> void:
 if not battle.kaelen_hud_panel:
  return
 # HUD começa oculto (§3.4 morto) — revela na 1ª análise de um inimigo.
 if not battle.kaelen_hud_panel.visible:
  battle.kaelen_hud_panel.visible = true

 # Vetor Biológico
 var bio = data.get("biological", {})
 var weaknesses_text: Array = []
 for w in bio.get("weaknesses", []):
  weaknesses_text.append("%s (+%d%%)" % [w["type"], w["bonus_percent"]])
 battle.kaelen_bio_weaknesses.text = "Fraquezas: " + (", ".join(weaknesses_text) if weaknesses_text else "—")
 battle.kaelen_bio_fatigue.text = "Fadiga: " + battle.kaelen_system.get_fatigue_name(bio.get("fatigue", 0))
 battle.kaelen_bio_armor.text = "Armadura: %d" % bio.get("armor", 0)

 # Vetor Psicológico
 var psycho = data.get("psychological", {})
 battle.kaelen_psy_morale.text = "Moral: " + battle.kaelen_system.get_morale_name(psycho.get("morale", 1))
 battle.kaelen_psy_flee.text = "Fuga: %.0f%%" % (psycho.get("flee_chance", 0.0) * 100)

 # Vetor Tático
 var tac = data.get("tactical", {})
 battle.kaelen_tac_locks.text = "Locks: " + ("Sim" if tac.get("has_locks", false) else "Não")
 battle.kaelen_tac_threat.text = "Ameaça: " + tac.get("threat_level", "BAIXA")
 battle.kaelen_tac_range.text = "Alcance: %d" % tac.get("attack_range", 1)

func _on_kaelen_suggestion_generated(suggestion: Dictionary) -> void:
 if not battle.kaelen_hud_panel:
  return
 var suggestions: Array = suggestion.get("suggestions", [])
 var texts: Array = []
 for s in suggestions:
  texts.append("%s: %s (urgência: %s)" % [s["lock_type"], s["suggestion"], s["urgency"]])
 battle.kaelen_suggestions_label.text = "SUGESTÕES: " + ("\n".join(texts) if texts else "—")

func _on_balance_mode_changed(new_mode: String) -> void:
 var color: Color
 match new_mode:
  "ETHER": color = Color(0.3, 0.7, 1.0)
  "FURY": color = Color(1.0, 0.3, 0.2)
  "SYMBIOSIS": color = Color(0.8, 0.5, 1.0)
  _: color = Color.WHITE
 battle.combat_feedback.show_status_effect(Vector2(640, 50), new_mode)
 update_balance_ui()

func _on_boss_defeated(boss_name: String) -> void:
 battle.can_interact = false
 await battle.screen_effects.flash_white()
 battle.combat_feedback.show_status_effect(Vector2(640, 360), boss_name + " DERROTADO!")
 await battle.get_tree().create_timer(2.0).timeout
 battle.show_victory_screen()

func _on_boss_spell_charging(_boss_name: String, spell_name: String, _turns_left: int) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 200), "PERIGO: " + spell_name + " se preparando!")
 battle.combat_feedback.shake_light()

# === Handlers sistemas §6-7 ===

func _on_traversal_completed(traversal_type: String) -> void:
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "TRAVESSIA: " + traversal_type)
  if battle.progression_system:
    battle.progression_system.add_memory(10)
    battle.progression_system.add_experience(25)
  _collect_traversal_loot()
  _update_progression_hud()

## §7.2 Coleta de ingredientes: a travessia é a exploração do mundo.
## Drop ponderado por raridade (common 60% / uncommon 30% / rare 10%).
func _collect_traversal_loot() -> void:
  var roll: float = randf() * 100.0
  var target_rarity: String = "common"
  if roll >= 90.0:
    target_rarity = "rare"
  elif roll >= 60.0:
    target_rarity = "uncommon"
  var pool: Array[String] = []
  for ing_id: String in battle.cooking_system.INGREDIENTS:
    if battle.cooking_system.INGREDIENTS[ing_id]["rarity"] == target_rarity:
      pool.append(ing_id)
  if pool.is_empty():
    return
  var picked: String = pool[randi() % pool.size()]
  battle.cooking_system.collect_ingredient(picked, 1)
  battle.combat_feedback.show_status_effect(Vector2(640, 340), "ENCONTROU: " + battle.cooking_system.INGREDIENTS[picked]["name"])

func _on_camp_rest_completed(healed_units: Array) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 300), "ACAMPAMENTO: %d unidades restauradas" % healed_units.size())
 if battle.progression_system:
  battle.progression_system.add_experience(15)
  battle.progression_system.add_memory(5)
 _update_progression_hud()

func _on_bond_level_changed(apostle_name: String, new_level: int) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 300), "VÍNCULO: " + apostle_name + " nível " + str(new_level))

func _on_recipe_crafted(recipe_name: String, bonuses: Dictionary) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 300), "RECEITA: " + recipe_name)
 if battle.progression_system:
  battle.progression_system.add_experience(20)
  battle.progression_system.add_memory(10)
 _apply_cooked_heal(bonuses)
 _update_progression_hud()

func _apply_cooked_heal(bonuses: Dictionary) -> void:
 # §7.2: hp/mp de receita curam imediatamente as units jogador (não mexe em max)
 var heal_hp: int = bonuses.get("hp", 0)
 var heal_mp: int = bonuses.get("mp", 0)
 if heal_hp <= 0 and heal_mp <= 0:
  return
 for unit: Unit in BattleManager.player_units:
  if not unit.data or not unit.data.is_player:
   continue
  if heal_hp > 0:
   unit.heal(heal_hp)
  if heal_mp > 0:
   unit.current_mp = mini(unit.data.max_mp, unit.current_mp + heal_mp)
 if heal_hp > 0 or heal_mp > 0:
  battle.combat_feedback.show_status_effect(Vector2(640, 340), "RECUPEROU +%d HP / +%d MP" % [heal_hp, heal_mp])

func _cooking_attack_multiplier() -> float:
 # Buff de cozinha §7.2: cada ponto de "attack" soma 10% ao dano do atacante.
 # Sem buffs ativos retorna 1.0 (neutro). ponytail: 10%/ponto é flat;
 # calibrar na tabela de receitas se precisar de curva.
 if not battle.cooking_system:
  return 1.0
 var attack_bonus: int = battle.cooking_system.get_total_bonuses().get("attack", 0)
 return 1.0 + attack_bonus * 0.1


func _cooking_defense_bonus() -> int:
 # Buff de cozinha §7.2: "defense" soma à defesa do alvo (reduz dano recebido).
 if not battle.cooking_system:
  return 0
 return battle.cooking_system.get_total_bonuses().get("defense", 0)

func _on_tavern_game_over(winner: String, loser: String) -> void:
 battle.combat_feedback.show_status_effect(Vector2(640, 300), "TABERNA: " + winner + " vence!")
 if battle.progression_system:
  battle.progression_system.add_named_soul()
 _update_progression_hud()

# === Funções de atualização de UI ===

func update_combo_ui() -> void:
 if not battle.combo_label:
  return
 var cp = battle.combo_system.get_cp()
 battle.combo_label.text = "CP: %d/3" % cp
 for i in range(3):
  if i < cp:
   battle.combo_dots[i].color = Color(1.0, 0.8, 0.2)  # Dourado quando ativo
  else:
   battle.combo_dots[i].color = Color(0.3, 0.3, 0.3)  # Cinza quando vazio

func update_balance_ui() -> void:
 if not battle.balance_bar or not battle.balance_label:
  return
 var ether: int = battle.balance_system.get_ether()
 var fury: int = battle.balance_system.get_fury()
 var mode: String = battle.balance_system.get_current_mode()

 # Barra bipolar: equilíbrio (ether == fury) no centro 50; Éter puxa p/ esquerda,
 # Fúria p/ direita. Escala 0..100 (MAX_VALUE).
 battle.balance_bar.value = 50 + (ether - fury) / 2

 # Label do modo (get_current_mode retorna String)
 match mode:
  "NEUTRAL": battle.balance_label.text = "Neutro"
  "ETHER": battle.balance_label.text = "Modo Éter"
  "FURY": battle.balance_label.text = "Modo Fúria"
  "SYMBIOSIS": battle.balance_label.text = "SIMBIOSE!"

 # Cor da barra baseada no modo
 var bar_fill = StyleBoxFlat.new()
 match mode:
  "ETHER": bar_fill.bg_color = Color(0.3, 0.7, 1.0)  # Azul para Éter
  "FURY": bar_fill.bg_color = Color(1.0, 0.3, 0.2)  # Vermelho para Fúria
  "SYMBIOSIS": bar_fill.bg_color = Color(0.8, 0.5, 1.0)  # Roxo para Simbiose
  _: bar_fill.bg_color = Color(0.5, 0.5, 0.5)  # Cinza para Neutro
 battle.balance_bar.add_theme_stylebox_override("fill", bar_fill)

func show_boss_hp(boss_name: String, hp: int, max_hp: int) -> void:
 if battle.boss_panel:
  battle.boss_panel.visible = true
  battle.boss_name_label.text = boss_name
  battle.boss_hp_bar.max_value = max_hp
  battle.boss_hp_bar.value = hp

func hide_boss_hp() -> void:
 if battle.boss_panel:
  battle.boss_panel.visible = false

# === HUD de Progressão §6-8 ===

## Feedback visual + stat application quando a forma do protagonista evolui.
## Conectado a CharacterProgression.form_changed (§8 / ROADMAP #6).
func _on_protagonist_form_changed(old_form: String, new_form: String) -> void:
 # Flash do FormLabel + status effect para o jogador notar a evolução no mundo.
 if battle.progression_hud:
  var form_label := battle.progression_hud.find_child("FormLabel", true, false) as Label
  if form_label:
   form_label.text = "FORMA: " + new_form
   form_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
   form_label.modulate = Color(3, 3, 2)
 if battle.combat_feedback:
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "EVOLUÇÃO: " + old_form + " → " + new_form)
 _update_progression_hud()
 _apply_protagonist_form_stats(new_form)

## Aplica os multiplicadores de stats da forma nova na unit viva do Kael.
func _apply_protagonist_form_stats(new_form: String) -> void:
 if not GameManager or not GameManager.character_progression:
  return
 var form_data: Dictionary = GameManager.character_progression.get_form_info(new_form)
 if form_data.is_empty():
  return
 for unit: Unit in BattleManager.player_units:
  if not unit.data or not unit.data.is_player:
   continue
  if unit.data.unit_name != "Kael":
   continue
  var stats := GameManager.character_progression.get_protagonist_stats()
  if unit.data.current_hp > 0:
   var hp_ratio := float(unit.data.current_hp) / float(unit.data.max_hp)
   unit.data.max_hp = stats.get("hp", unit.data.max_hp)
   unit.data.current_hp = int(unit.data.max_hp * hp_ratio)
   unit.data.attack = stats.get("attack", unit.data.attack)
   unit.data.defense = stats.get("defense", unit.data.defense)
   unit.data.magic = stats.get("magic", unit.data.magic)
   unit.data.speed = stats.get("speed", unit.data.speed)
   # P0-3: a evolução é VISÍVEL — sprite da unit vira a png da forma nova.
   _swap_protagonist_sprite(unit, new_form)

## Troca a textura do sprite da unit para a png da forma nova (§8 / P0-3).
## Reusa o NÓ do sprite (animator mantém a referência); png ausente → mantém atual.
func _swap_protagonist_sprite(unit: Unit, new_form: String) -> void:
 var new_sprite = battle._load_hd_sprite("res://assets/sprites/" + battle._sprite_key(new_form) + ".png")
 if new_sprite == null:
  return
 var old_sprite := _find_unit_sprite(unit)
 if old_sprite == null:
  new_sprite.free()
  return
 old_sprite.texture = new_sprite.texture
 old_sprite.scale = new_sprite.scale
 battle._normalize_sprite_to_tile(old_sprite)  # 1024px cru → célula de 32px
 new_sprite.free()

## Primeiro Sprite2D filho da unit (nome automático "@Sprite2D@N" impede path fixo).
func _find_unit_sprite(unit: Unit) -> Sprite2D:
 if unit == null:
  return null
 if unit.has_node("Sprite2D"):
  return unit.get_node("Sprite2D") as Sprite2D
 for child in unit.get_children():
  if child is Sprite2D:
   return child as Sprite2D
 return null

func _update_progression_hud() -> void:
 if not battle.progression_hud or not battle.progression_system:
  return
 var summary: Dictionary = battle.progression_system.get_progress_summary()

 # Labels ficam em HBox aninhados; find_child por nome evita path frágil
 var act_label = battle.progression_hud.find_child("ActLabel", true, false) as Label
 var mem_label = battle.progression_hud.find_child("MemLabel", true, false) as Label
 var soul_label = battle.progression_hud.find_child("SoulLabel", true, false) as Label
 var xp_label = battle.progression_hud.find_child("XPLabel", true, false) as Label
 var form_label = battle.progression_hud.find_child("FormLabel", true, false) as Label

 if act_label:
  act_label.text = "ATO %d" % summary.get("current_act", 1)
 if mem_label:
  mem_label.text = "MEM %d%%" % summary.get("memory_percent", 0)
 if soul_label:
  soul_label.text = "ALMAS %d" % summary.get("named_souls", 0)
 if xp_label:
  xp_label.text = "XP %d" % summary.get("total_xp", 0)
 if form_label:
  form_label.text = "FORMA: %s" % summary.get("protagonist_form", "???")

# === Painel de Ações §6-7 ===
# Excita os sinais já conectados em setup_systems(), ligando o runtime ao
# feedback visual (toast + HUD de progressão) dos sistemas Traversal/Camp/
# Cooking/Tavern.

func _on_forge_pressed() -> void:
 # Forja (§7, AUDIT P1 #12): painel de seleção — jogador escolhe o item;
 # disponibilidade vem das flags da vila (Fornalha/Forja do Rei Ogro).
 if battle._forge_panel != null and is_instance_valid(battle._forge_panel):
  battle._forge_panel.visible = not battle._forge_panel.visible
  return
 battle._build_forge_panel()
 battle._forge_panel.visible = true


func _sync_equipment():
 var equipment = battle.EquipmentSystemLib.new()
 equipment.set_unlocked_features(GameManager.building_system.unlocked_features if GameManager else {})
 var res: Dictionary = GameManager.building_system.resources if GameManager else {}
 equipment.set_resources({"materials": res.get("materials", 0), "gold": res.get("gold", 0), "soul_ether": res.get("soul_ether", 0)})
 return equipment


func _on_forge_item_pressed(equipment_id: String) -> void:
 var equipment = _sync_equipment()
 var check: Dictionary = equipment.can_craft(equipment_id)
 if not check.can:
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "FORJA: " + check.reason)
  return
 var item: Dictionary = equipment.get_equipment(equipment_id)
 for resource: String in item["cost"]:
  GameManager.building_system.spend_resources({resource: item["cost"][resource]})
 var result: Dictionary = equipment.craft(equipment_id)
 if result.ok:
  GameManager.apply_equipment_bonuses(result.bonuses, equipment_id, item["slot"])
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "FORJA: %s equipado!" % item["name"])
  if SoundManager:
   SoundManager.play_forge()
  if GameManager.has_method("save_game"):
   GameManager.save_game()  # bônus permanente + inventário da vila no save
 # Atualiza a painel (custos/estado mudaram).
 battle._forge_panel.queue_free()
 battle._forge_panel = null
 battle._build_forge_panel()
 battle._forge_panel.visible = true


# --- Handlers de excitação (disparam métodos que emitem sinais §6-7) ---

func _on_camp_pressed() -> void:
 if battle._camp_used:
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "ACAMPA: já usado nesta batalha")
  return
 battle._camp_used = true
 var party: Array = BattleManager.player_units
 battle.campfire_system.rest_at_campfire("central", party)


func _on_cook_pressed() -> void:
 if battle._cook_used:
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "COZINHA: já usado nesta batalha")
  return
 battle._cook_used = true
 # Painel de seleção (mesmo padrão da Forja): jogador escolhe prato ou
 # elixir. Elixires (§7.2) viram bônus PERMANENTES no GameManager.
 if battle._cook_panel != null and is_instance_valid(battle._cook_panel):
  battle._cook_panel.visible = not battle._cook_panel.visible
  return
 battle._build_cook_panel()
 battle._cook_panel.visible = true


func _on_cook_item_pressed(recipe_id: String, is_food: bool) -> void:
 if not battle.cooking_system.can_craft(recipe_id):
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "COZINHA: sem ingredientes")
  return
 var bonuses: Dictionary = battle.cooking_system.craft(recipe_id)
 if bonuses.is_empty():
  return
 if is_food:
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "COZINHA: %s preparado!" % battle.cooking_system.get_all_recipes()[recipe_id]["name"])
 else:
  GameManager.apply_elixir_bonuses(bonuses)
  battle.combat_feedback.show_status_effect(Vector2(640, 300), "ELIXIR: bônus permanente aplicado!")
  if SoundManager:
   SoundManager.play_heal()
  if GameManager.has_method("save_game"):
   GameManager.save_game()  # bônus permanente no save
 # Atualiza o painel (ingredientes mudaram).
 battle._cook_panel.queue_free()
 battle._cook_panel = null
 battle._build_cook_panel()
 battle._cook_panel.visible = true


func _on_tavern_pressed() -> void:
 if battle._tavern_running:
  return
 # Aposta (ROADMAP #12): 10 ouro de entrada, pago no início; vitória paga 2x.
 # Sem ouro suficiente, a mesa joga casual (aposta 0).
 var bet = battle.TAVERN_BET if GameManager.game_data.gold >= battle.TAVERN_BET else 0
 if bet > 0:
  GameManager.add_gold(-bet)
 battle.tavern_minigame.start_game("Jogador", "IA", bet)
 battle.tavern_minigame.bet_resolved.connect(_on_tavern_bet_resolved)
 battle.tavern_minigame.exclusive_reward_earned.connect(_on_tavern_exclusive_reward)
 battle._tavern_running = true
 _run_tavern_until_end()


func _on_tavern_bet_resolved(won: bool, payout: int) -> void:
 if payout > 0:
  GameManager.add_gold(payout)
 if SoundManager:
  SoundManager.play_bet_win() if won else SoundManager.play_bet_lose()
 var msg := "TABERNA: você venceu! +%d ouro" % payout if won else "TABERNA: derrota... aposta perdida."
 battle.combat_feedback.show_status_effect(Vector2(640, 300), msg)


func _on_tavern_exclusive_reward(reward_id: String) -> void:
 var tiers: Dictionary = battle.tavern_minigame.get_reward_tiers()
 for tier in tiers.values():
  if tier["id"] == reward_id:
   battle.combat_feedback.show_status_effect(Vector2(640, 200), "RECOMPENSA: " + tier["name"])
   if battle.progression_system:
    battle.progression_system.add_named_soul()
   return


func _run_tavern_until_end() -> void:
 # ponytail: autobattler demo — ambos os lados jogam a primeira runa jogável
 # automaticamente. Stall (ninguém pode jogar) encerra no battle._tavern_turn_limit.
 # _advance_turn só roda via play_rune(), então o turno avança quando há jogo.
 var turns := 0
 while battle.tavern_minigame.is_game_active() and turns < battle._tavern_turn_limit:
  var current = battle.tavern_minigame.get_current_turn()
  var rune := _pick_tavern_rune(current)
  if not rune.is_empty():
   battle.tavern_minigame.play_rune(current, rune)
  await battle.get_tree().create_timer(0.25).timeout
  turns += 1
 battle._tavern_running = false


func _pick_tavern_rune(player_id: String) -> String:
 if not battle.tavern_minigame.is_game_active():
  return ""
 for rune_id: String in battle.tavern_minigame.get_player_hand(player_id):
  if battle.tavern_minigame.can_play_rune(player_id, rune_id):
   return rune_id
 return ""


func _on_traverse_pressed() -> void:
  battle.traversal_system.setup(true, 100)
  var result: Dictionary = battle.traversal_system.start_traversal("dash")
  if not result.get("can", false):
    battle.traversal_system.regen_stamina(100)
    battle.traversal_system.start_traversal("dash")
  # Dash é instantâneo: finaliza na hora para emitir traversal_completed
  # (que alimenta memory + XP no handler).
  battle.traversal_system.end_traversal()


func _on_combo_pressed() -> void:
  if not _try_use_combo():
    battle.combat_feedback.show_status_effect(Vector2(640, 300), "COMBO: sem CP ou sem participantes")


## §3.3 Ativa a primeira combo disponível (CP suficiente + participantes no campo).
func _try_use_combo() -> bool:
  var participants: Array[String] = []
  for unit: Unit in BattleManager.player_units:
    if unit.data and unit.data.is_player:
      participants.append(unit.data.unit_name)
  for combo: Dictionary in battle.combo_system.get_available_combos(participants):
    if battle.combo_system.activate_combo(combo, participants):
      return true
  return false
