# CARTOGRAPHY — Mapa do Codebase (consulte ANTES de grepar código)

> **Protocolo de economia de tokens**: antes de `rg`/leitura ampla, consulte este mapa
> para saber Onde está cada coisa, Quem chama Quem e Qual arquivo abrir. Atualize
> este documento ao criar módulos novos (1 linha basta). Gerado em 2026-09-07.

## Fluxo principal do jogo (cena a cena)

```
main_menu.tscn → intro_story.tscn → explore_scene.tscn (mapa do ato)
  → contato com inimigo abre ARENA in-place (arena_battle instanciado)
  → vitória → result_screen → "Continuar" → próximo estágio da campanha
  → boss do ato derrotado → act_cutscene → ... → epilogue
```

- Roteamento de cenas: `scripts/scene_manager.gd` (autoload SceneManager, `change_scene`)
- Payload da intro e bootstrap de novo jogo: `game_manager.gd:86` (`_on_intro_completed`), `:115` (`start_new_game`)
- Fonte da verdade do estágio atual: `campaign_system.gd`; sync → `game_manager.gd:287` (`sync_current_map_from_campaign`)

## Autoloads (globais — 4, ver project.godot:18)

| Autoload | Arquivo | Responsabilidade | APIs-chave |
|---|---|---|---|
| BattleManager | scripts/BattleManager.gd (490) | grid 12x12, turnos, waves, IA inimigo, dano | `attack_unit`:394, `start_battle`:109, `setup_waves`:120, `cast_magic`:251, sinais `battle_won/lost`, `unit_moved/attacked/died`, `soul_ether_gained`, `timed_block_request` |
| GameManager | scripts/game_manager.gd (324) | save, party, recursos, elixires/equip permanentes, puzzles/traversals feitos | `start_new_game`:115, `apply_elixir_bonuses`:175, `apply_equipment_bonuses`:209, `apply_victory_rewards`:260, `sync_current_map_from_campaign`:287, `save_game`:297, `game_data` dict |
| SoundManager | scripts/sound_manager.gd (453) | SFX/música procedurais (WebAudio-like) | `play_hit/select/step/heal/forge/bet_win/...`, `play_music(map)` |
| SceneManager | scripts/scene_manager.gd (33) | troca de cenas | `change_scene("main_menu"/"explore"/...)` |

## Cenas e seus scripts (scenes/*.tscn → scripts/)

| Cena | Script | Linhas | Papel |
|---|---|---|---|
| main_menu | main_menu.gd | 37 | novo jogo/continuar |
| intro_story | intro_story.gd | 205 | história canônica (sem escolhas), payload do 1º Pacto |
| explore_scene | explore_scene.gd | **1630** | mapa contínuo por bioma, NPCs/diálogo, quests, loja, forja, travessia, seamless encounter, iluminação, **caixa de diálogo SoS** |
| act_cutscene | act_cutscene.gd | 111 | corte de ato |
| epilogue | epilogue.gd | 26 | final |
| battle_scene (legado) | battle_scene.gd | 426 | batalha grid tática (FORA do caminho principal; wrappers → libs battle/*) |
| naming_ui | naming_ui.gd | 61 | nomear almas |
| battle_result_screen | battle_result_screen.gd | 54 | vitória/derrota |

## Arena (caminho principal de combate)

- **scripts/arena_battle.gd (1303)** — overlay de batalha: HUD réplica SoS (placas PV/PM `:940`, menu contextual `:770`, banner/EFEITO `:1050`, badge COMBO `:975`), timed hit/block, ondas, boss bar, iluminação de palco `:810`, vinheta `:905`
- **scripts/arena_combat.gd (143)** — núcleo puro (sem UI): turnos por agilidade, dano, IA de foco, fim de batalha
- Composição: `ArenaBattle` cria `ArenaCombat` e espelha o estado na tela

## Libs battle/* (ex-god file battle_scene, extraídas #13a–e; padrão RefCounted + `battle.`)

| Lib | Linhas | Conteúdo |
|---|---|---|
| battle/battle_spawner.gd | 343 | spawn data-driven, sprites HD, HP bars, waves |
| battle/battle_hud.gd | 462 | setup_ui, HUDs Kaelen/combo/balance/boss/progressão, forja/cozinha panels |
| battle/battle_flow.gd | 181 | turnos/fases, eventos, `_on_battle_won/lost`, progressão, naming seam |
| battle/battle_input.gd | 189 | `_input` roteado, seleção, timed hit/block, menus |
| battle/battle_systems.gd | 452 | Kaelen HUD, balance/CP UI, boss bar, formas §8, forja, cozinha, taverna, travessia, combo |

**Padrão**: wrappers na cena (`_get_flow()/_get_input()/...` lazy) preservam API de testes; libs acessam a cena via `var battle`.

## Explore_scene (o maior arquivo — mapa interno)

| Sistema | Localização (aprox) |
|---|---|
| Consts de movimento/grid | `:14-30` |
| NPC spawn/dialogue flow | `:150-260` (`_interact_npc`:215) |
| Caixa de diálogo SoS (placa + keywords) | `:113-127` consts, `_open_dialogue_box`:267, `_highlight_keywords`:128 |
| Loja do mercador | `:350-420` |
| Campfire/quest/toast | `:420-480` |
| **Iluminação SoS** (`_LIGHT_PROPS`, CanvasModulate, pools) | `:600-680` |
| `_build_map` + tiles LoRA + decor Eder | `:690-780` |
| Seamless encounter → arena | `:800-880` |
| HUD de progresso do jogador | `:1080-1110` |
| Travessia (nodes/hint) | `:1095-1200` |

## Dados e sistemas (scripts/ raiz)

| Domínio | Arquivos |
|---|---|
| Combate puro | arena_combat.gd, timed_combat_system.gd, magic_system.gd, lock_system.gd, flanking_system.gd, turn_order_manager.gd, enemy_ai.gd, terrain_effect_system.gd, adjacency_system.gd |
| Combate legado (grid) | battle_scene.gd + battle/* + grid.gd + unit.gd + unit_data.gd + unit_animator.gd |
| Sistemas §6-7 (sinais→feedback) | cooking_system, campfire_system, traversal_system, tavern_minigame, building_system, equipment_system, balance_system, combo_system, ether_system, faith_system, naming_system, lineage_system, captured_souls |
| Kaelen §3.4 | kaelen_system.gd (análise de alvos/locks), consumido por battle_systems/battle_input |
| Mundo | map_database.gd (516 — maps, props, puzzles, traversal_nodes, geradores de tiles), campaign_system.gd, character_progression.gd, quest_system.gd, seamless_encounter_system.gd, dialogue_system.gd (DIALOGUES data-driven), light_puzzle_system.gd, autotile_system.gd |
| Render/efeitos | pixel_art_renderer.gd (1003 — TERRAINS:357, canvas procedural:915, **canvas LoRA**:920), sos_motion_loader.gd, sprite_motion_library.gd, combat_feedback.gd, screen_effects.gd, sound_manager.gd |
| Meta | scene_manager.gd, settings.gd, main_menu.gd, intro_story.gd, epilogue.gd, act_cutscene.gd, game_manager.gd |

## Convenções críticas (quebrar = regressão)

1. **Indentação MISTA no repo**: `explore_scene/arena_battle/map_database/cooking/battle_scene` = 1 espaço por nível; `unit.gd/pixel_art_renderer/battle_hud/battle_systems` = tab. **Sempre conferir o arquivo alvo antes de editar** (3 quebras de parse nesta semana).
2. **Testes instanciam cenas sem `_ready`** e stubam membros com `.set()` (`grid`, `unit_container`, `ui_layer`) → handlers devem tolerar `null` (`is_instance_valid` guards).
3. **Novo class_name não entra no cache global headless** → `const Lib := preload(...)` em vez de nome global.
4. **`:=` sobre acesso dinâmico `battle.X` falha inferência** → usar `=` solto em libs.
5. **ProgressBar**: styleboxes ANTES de `size` (min-height 27px do tema clampeia).
6. **1 módulo por commit, suíte verde** (GUT: `--headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit` — 83 scripts, 735/735).
7. **QA visual**: `--rendering-driver opengl3 -s tools/qa_run.gd` (11 shots; NÃO usar `--headless`).

## Ferramentas dev (tools/)

| Tool | Uso |
|---|---|
| qa_run.gd | QA visual 12 shots (intro→epilogue, incl. diálogo 04b) |
| pose_consistency_qa.py | QA de consistência de poses LoRA (paleta/bbox/deltas por personagem) |
| portrait_zoom.py (via zoom), flood_bg_local.py, rembg_poses.py, make_chars/poses_transparent.py | pipeline de personagens LoRA (fundo/crop/poses) |
| cartographer_cli.py | gera mapas por bioma (JSON+PNG) via CartographerCore (scripts/dev/) |
| comfy_sos_batch.py / run_sos_batches.py | assets LoRA (retratos/ícones/tiles/chars/poses; skip-if-exists; modo multi-alvo) |
| comfy_props_batch3.py, remove_prop_bg2.py | props (SDXL) + flood-fill de fundo |
| sos_asset_metrics.py, sos_metadata_extract.py | análise de referência do SoS (assets/codebase) |
| atlas decode / sos tools | sprites SoS reais (7357 frames, 28 chars) |

**Arquivados** em `tools/archive/` (48 scripts one-off de debugging — referência, fora do uso).

## Testes (tests/unit/, 84 arquivos)

- Nomes autoexplicativos (`test_<dominio>.gd`). Busque primeiro aqui: a maioria dos comportamentos tem cobertura e o teste documenta o uso.
- Padrão: `extends "res://addons/gut/test.gd"`, `before_each` reseta GameManager/BattleManager.
- Quirks: "Failed to load script ... Parse error" no log headless = quirk de cache `-s` (script roda); `test_tutorial.gd` sobrescreve `wait_frames` com assinatura própria (aviso esperado).

## Onde NÃO mexer

- `scripts/battle_scene.gd` + `battle/*`: wrappers são API pública dos testes — mudar assinatura quebra ~40 testes.
- `.godot/`: cache; reconstruir com `--headless --path . --import` se corromper (não deletar seletivamente).
- `docs/AUDIT.md`: histórico de decisões (wontfix #15, direção de arte, filas).
