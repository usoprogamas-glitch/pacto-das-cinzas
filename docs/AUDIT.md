# AUDITORIA — O Pacto das Cinzas

> Auditoria executada em 2026-08-31 (worktree pasted-text-processing).
> Base: 483/483 testes GUT ✅ | Pipeline completo jogável: intro → 4 atos → cutscenes → epílogo.
> Cada item lista: problema (verificado no código), impacto, e onde conectar.

---

## P0 — Bugs reais (quebram a experiência; fazer primeiro)

### 1. BossSystem mostra "Ignis" para TODOS os chefes 🐛 ✅ CORRIGIDO (2026-08-31)
- **Onde**: `battle_scene.gd:70` → `BOSS_CARDINAL_BY_CLASS = {"Boss": "Ignis"}`
- **Problema**: o mapeamento runtime usa a *classe* da unidade. Todo chefe tem `class: "Boss"`, então lutar contra Zephyr/Aqua/Aurius mostra painel, partes e spells de **Ignis**.
- **Fix aplicado**: `_resolve_cardinal_name(unit_name)` — Cardeais casam com a chave de CARDINALS; nomes "Aurius — *" → "Aurius"; "Santo Cardeal" (legado) → Ignis; demais → "". Bônus: `spawn_runtime_boss("Aurius")` agora roteia para `init_aurius()` (antes retornava cedo e o boss ficava sem binding). 8 testes (`test_boss_name_resolve.gd`).

### 2. `unit_animators` colide com nomes duplicados 🐛 ✅ JÁ RESOLVIDO (verificado 2026-09-01)
- **Onde**: `battle_scene.gd` — `unit_animators[unit_name] = animator`
- **Problema**: dois inimigos "Mercenário" na mesma batalha → o segundo **sobrescreve** o animator do primeiro; animações (walk/attack/death) tocam na unidade errada ou em nenhuma.
- **Estado**: código já usa chave por instância (`unit_animators[unit.get_instance_id()]`, `battle_scene.gd:26/679/1141`). Cobertura em `test_animators_by_instance.gd` (2 units de mesmo nome → 2 entradas).

### 3. Evolução de forma NÃO troca o sprite 🐛 ✅ CORRIGIDO (2026-08-31)
- **Onde**: `battle_scene.gd::_on_protagonist_form_changed` — só pisca o FormLabel.
- **Problema**: os 4 sprites de forma (`imp_menor`, `nobre_abissal`, `arquidemonio`, `avatar_primordial`) foram gerados mas **nunca aparecem** — a unit do Kael continua com o sprite da forma 1 o jogo inteiro.
- **Fix aplicado**: `_apply_protagonist_form_stats` agora chama `_swap_protagonist_sprite(unit, new_form)` — troca a textura do MESMO nó Sprite2D (animator não perde referência) + re-normaliza à célula de 32px. Png ausente → textura mantida. 6 testes (`test_form_sprite_swap.gd`).

### 4. Música não existe em runtime 🐛 ✅ CORRIGIDO (2026-08-31)
- **Onde**: `map_database.gd` define `"music": "exploration"/"battle"` por mapa — **nenhum código lê esse campo**. `SoundManager.play_sfx` é chamado (select/step/hit/death), mas zero BGM.
- **Impacto**: jogo inteiro em silêncio de fundo; campo de dados morto.
- **Fix aplicado**: `play_music()` agora define stream (procedural, mesmo padrão dos SFX) com loop infinito + cache; 2 faixas (`create_exploration_music`: drone pentatônico menor / `create_battle_music`: pulso percussivo + baixo em oitavas); `setup_battle` lê `current_map.music`. Faixa desconhecida → no-op. 8 testes (`test_bgm_data_driven.gd`).

### 5. Shaders do PixelArtRenderer não compilam 🐛 ✅ CORRIGIDO E VALIDADO (2026-08-31)
- **Onde**: `pixel_art_renderer.gd` (853 linhas) — GLSL inválido: `Range hint is for 'float' and 'int' only` (uniforms com hint em tipos errados), `Tokenizer: Unknown character #1` (caracteres não-ASCII dentro de shader code).
- **Impacto**: outline, glow, rim light, water, grass, dither — **todos mortos silenciosamente** no jogo.
- **Fix**: corrigir hints (`hint_range` só em float/int), remover/caracteres especiais dos comentários GLSL, validar cada shader.
- **Teste**: headless não compila shader — validar via script de sanity (material != null, shader.code ASCII-safe) + inspeção visual.
- **Executado**: fix em `6e918f7` (hints só em float, matriz Bayer indexada por int, comentários ASCII, CRLF normalizado via `_clean_shader`) + `test_pixel_shaders.gd` (11 testes estáticos). **Validação de compilação REAL (2026-08-31)**: `tools/probe_shaders.gd` — desenha os 6 shaders em 6 sprites por 5 frames com renderer OpenGL 3.3 real (headless usa RasterizerDummy e não compila shader): `PROBE OK`, zero linhas `SHADER ERROR`. Regressão futura: rodar o probe após qualquer mudança de shader.

### 6. Log poluído por probe de png faltante 🐛 ✅ CORRIGIDO (2026-08-31)
- **Onde**: `_load_hd_sprite` faz `img.load()` direto → Godot imprime ERROR para cada nome sem png (`fantasma`, `guerreiro`, `teia`...).
- **Impacto**: cosmético, mas mascara erros reais em produção.
- **Fix aplicado**: `FileAccess.file_exists(path)` antes do load. Suíte confirmada sem nenhum "Error opening file". 3 testes (`test_png_precheck.gd`).

---

## P1 — Conteúdo do ROADMAP (após P0)

### 7. ROADMAP #11 — Timed blocks (mitigação na defesa) 🟡 ✅ CORRIGIDO (2026-08-31)
- **Onde**: `timed_combat_system.gd` já tinha `resolve_block_timing`/`apply_block` testados, mas o fluxo de combate só usava o caminho de ataque (`battle_scene.gd::_timed_hit_*` → `BattleManager.attack_unit(timing_bonus)`).
- **Fix aplicado**: pipeline espelhado. `BattleManager` ganhou `timed_block_resolver: Callable` + sinal `timed_block_window` — ataque inimigo em alvo jogador abre a janela de 0.2s (`BLOCK_WINDOW`) antes de aplicar dano; `battle_scene` instala o resolver (`_resolve_timed_block`: indicador "TIMED BLOCK!" + aguardo do clique reativo) e o clique gradua via `resolve_block_timing` (PERFECT -50% / GREAT -30% / GOOD -10%). Redução entra no pipeline de dano depois do timing bonus; clique reativo vale no ENEMY_TURN (`_input` intercepta antes do gate `can_interact`). Sem resolver (headless/testes), dano integral — comportamento antigo preservado. 7 testes (`test_timed_block.gd`).

### 8. ROADMAP #10 — SeamlessEncounter + LightPuzzle órfãos 🟡 ✅ FEITO (2026-08-31)
- **SeamlessEncounter**: destravado no MVP SoS — `explore_scene` registra inimigos e abre encontros por proximidade (sem troca de cena).
- **LightPuzzle**: wiring concluído (2026-08-31) — `explore_scene._spawn_puzzles` lê `MapDatabase.puzzles` (data-driven), spawna espelhos de obsidiana/pedestais/relógio cósmico; E gira o objeto próximo; solução paga as recompensas declaradas (soul_ether/gold/xp) e projeta o feixe luz→espelhos→alvo. Posicionados: mapa 0 `fronteira_espelhos` (mirror_alignment, Ato I) e mapa 5 `despojos_sombras` (shadow_reveal + eclipse, Ato II). 6 testes (`test_explore_puzzles.gd`). Restante é conteúdo: mais puzzles e persistência de "resolvido" no save (opcional).

### 9. Ato III em ONDAS (decisão #7 pendente de execução) ✅ FEITO (2026-09-01)
- `waves` data-driven no mapa + reinjeção com stats escalados (commit 8653015). Arena (SoS) e grid legado.

### 10. Locks não nascem do cast inimigo ✅ FEITO (2026-09-01)
- Arena (commit ed0eca8, `enemy_spell` data-driven) + espelho no grid legado (commit 4e035b6, spells do MagicSystem com locks). Spellbreak = stun + CP.

### 11. Taberna #12 / Travessia #13 / Culinária #14 ✅ FEITO (2026-09-01)
- **Taberna #12**: apostas em ouro (entrada 10 ouro, vitória paga 2x) + recompensas exclusivas por sequência de vitórias (amuleto_runico → colar_de_ossos → coroa_da_guerra_de_runas, data-driven em `REWARD_TIERS`). Core puro (`TavernMinigame`) + integração no battle_scene. 8 testes (`test_tavern_bets.gd`). Commit d643e99.
- **Travessia #13**: `traversal_nodes` data-driven no mapa (fenda de arpéu, penhasco, desfiladeiro), `TraversalSystem.attempt_traversal` valida asas/stamina/alcance, desfiladeiro de Zephyr concede Asas de Cinzas. 10 testes (`test_traversal_nodes.gd`). Commit 80015da.
- **Culinária #14**: elixires ganham `max_uses` (gate de usos) + sinal `elixir_crafted` dedicado; bônus PERMANENTES aplicados via `GameManager.apply_elixir_bonuses` (max_hp/max_ether somam à party, attack_percent acumula no save e recalcula do atk base — idempotente no reload). 9 testes (`test_cooking_permanent.gd`).

### 12. Equipamentos sem wiring? (verificar) ✅ FEITO (2026-09-01)
- **Achado da auditoria**: `scripts/crafting/` nunca existiu no repo — não era órfão, era feature ausente. O que existia: `BuildingSystem` com flags `craft_armas_básicas`/`craft_armas_avançadas` (Fornalha Vulcânica / Forja do Rei Ogro) e a API consumidora `is_craft_unlocked()`, sem consumidor.
- **Implementado**: `EquipmentSystem` (puro, data-driven em `EQUIPMENT`: espada/bracelete/arco/manto com slots weapon/trinket/armor) consumindo as flags reais da vila (com acento: `craft_armas_básicas`), custo em materials/gold/éter, regra de 1 item por slot com substituição que reverte o antigo. Bridge: botão "Forja" no painel de ações + `GameManager.apply_equipment_bonuses` (bônus permanentes na party + registro em `game_data["equipped"]`/`equipment_bonuses` para persistência). 11 testes (`test_equipment_system.gd`). Suíte: 667/667.

### 12b. Persistência de puzzles/traversal no save ✅ FEITO (2026-09-01)
- `game_data["world_state"]` por mapa (`is_puzzle_solved`/`mark_puzzle_solved`/`is_traversal_done`/`mark_traversal_done`): revisitar um estágio restaura puzzles e nós como resolvidos (visual verde) e **sem recompensa dupla**. Exploração marca ao resolver. 7 testes (`test_world_state.gd`). Suíte: 674/674.

### 12c. Sessão 2026-09-01/02 — polish completo ✅ FEITO
- **Economia (0df455a)**: batalhas pagavam 0 ouro/0 XP e nada concedia materials (forja inutilizável) — `_finish` deriva gold 50%/XP 40% do soul_ether + 40% chance de material por inimigo; explore paga tudo. Simulação valida Portão do Abismo (500) alcançável.
- **Balance TTK (c2ed23e)**: simulador determinístico expôs Terra=215 turnos (!), Ignis=53, Aqua=44. Def de bosses derrubada, HP de cardeais -40%, orc_chefe +50% atk. Resultado na janela 8-40 (Aurius 15/12/9, pânico crescente). Ferramentas em `tools/balance_stats.py` + `dump_enemies.py`.
- **Save automático (ce40aea)**: travessia/puzzle/elixir/forja gravam save no ato (não só fim de batalha).
- **SFX (5bb9f86)**: 7 sons procedurais (forja/lock hit/break/puzzle/traversal/bet win/lose) wired nos handlers.
- **Forja UI (05b9902)**: painel de seleção por item (nome/slot/custo/estado) com toggle e refresh pós-forja.
- **Side content (0ede89d)**: mapas 2 e 4 com traversal+puzzle+props. Todo mapa explorável (0-10) tem conteúdo completo.

## FILA PARA A PRÓXIMA SESSÃO (2026-09-02)
1. **QA jogável ponta a ponta** — usuário joga intro → Aurius Fase 1 e reporta bugs de runtime/game feel (único risco não coberto pelos 695 testes).
2. **LoRA pixel-art no ComfyUI** — elevar precisão dos assets (usuário instala o LoRA; pipeline em tools/ já pronto).
3. Se sobrar tempo: menu de seleção de elixir na cozinha (hoje pega o 1º craftável), batch 3 de props (estátuas dos Cardeais, decoração Solaria), padronizar indentação tabs→espaços com .editorconfig (quebrou 3x na sessão).
- Suíte: **695/695 ✅** | `main` @ `0ede89d` | working tree limpo.

---

## P1.5 — Mudanças de design (pedidos do usuário)

### 7b. Intro sem escolhas — história canônica ✅ FEITO (2026-08-31)
- **Pedido**: "ele é uma história, não tem essas opções" — a pergunta "O que você faz?" quebrava a imersão narrativa.
- **Fix aplicado**: 1º Pacto de Alma agora é NARRADO (Kaelen ordena gastar a mana → metamorfose em Hobgoblin → "Kroug" nomeado). Kroug nasce sempre: `complete_intro()` emite `first_pact_choice = {consequence: "first_pact"}` no payload (GameManager aplica -15 mana + naming + fé + spawn em batalha, inalterado). `ChoiceContainer` nunca aparece; navegação 100% por input (A avança / ESC pula). Skip da intro segue o mesmo cânone. 5 testes (`test_intro_canonical.gd`).

### 7c. Fluxo linear de enredo — map_select fora do caminho principal ✅ FEITO (2026-08-31)
- **Pedido**: "era pra seguir um enredo" — a intro desaguava no menu de mapas e o jogador caía numa batalha sem contexto.
- **Fix aplicado**: intro → batalha do estágio atual da campanha (Ato I — "Socorro aos Goblins"); pós-vitória "Continuar" → próxima batalha; cutscene de ato → batalha; main_menu (novo jogo/continuar) → batalha do estágio salvo. Cola: `GameManager.sync_current_map_from_campaign()` (fonte única do `map_id` = CampaignSystem). Epílogo no fim da campanha, inalterado. `map_select` permanece como cena para replay futuro (P1 #10). 3 testes (`test_story_flow.gd`) + 3 asserts de roteamento atualizados.

### 7d. Molde Sea of Stars — exploração contínua + arena (opção 3) ✅ MVP (2026-08-31)
- **Pedido**: "estilo de mapa e mecânica igual ao jogo de referência" — escolha pelo formato completo: exploração em mapa contínuo com encontros embutidos + combate arena (sem grid).
- **Implementado (MVP)**:
  - `scripts/explore/explore_scene.gd` — mapa contínuo (terreno do MapDatabase), Kael+Kroug andam em tempo real (WASD/setas), inimigos visíveis perseguem por proximidade (SeamlessEncounterSystem, órfão destravado) e o contato abre a arena IN-PLACE (sem troca de cena).
  - `scripts/battle/arena_combat.gd` — núcleo puro: turnos por agilidade (TurnOrderManager), dano/magia perfurante, IA de foco, condição de fim. 10 testes.
  - `scripts/battle/arena_battle.gd` — overlay de arena: menu Atacar/Magia/Fugir, Timed Hit (clique no impacto) e Timed Block (clique no golpe inimigo), barras de HP flutuantes, Soul Éter.
  - Fluxo linear: intro → exploração → arena → vitória → próximo estágio → ... → cutscene de ato → ... → epílogo. Grid tático (battle_scene) permanece como código legado, fora do caminho principal.
- **Pendências visuais para iterar com o usuário**: ~~todas resolvidas~~ ✅ — ~~tiles decorados~~ ✅ (grade 10x6 de tiles procedurais do PixelArtRenderer/TERRAINS no explore_scene, shaders de água/grama, layout determinístico por seed — `test_explore_terrain.gd`), ~~animações de caminhada/ataque na arena~~ ✅ (UnitAnimator por instância — entrada caminhando, idle respirando, lunge/hit/death, victory — `test_arena_animations.gd`), ~~música por mapa~~ ✅ (P0-4), ~~result screen dedicada~~ ✅ (painel VITÓRIA!/DERROTA + recompensas + Continuar; `battle_ended` só dispara após o jogador ver o resultado — `test_result_screen.gd`), ~~sprites com movimento~~ ✅ (2026-08-31: SpriteMotionLibrary gera ciclos idle 2f/walk 4f em runtime por PNG via bandas cutout a 256px — pernas deslocam mais que cabeça; UnitAnimator cicla texturas com fallback tween preservado; wired em explore (party+inimigos, walk no chase) e arena (entrada na passada) — `test_motion_frames.gd`).

---

## P2 — Qualidade / arquitetura

### 13. `battle_scene.gd` = 1431 linhas (god file)
- Concentra spawn, UI, HUD, combate, campanha, progression. Extrair em módulos coesos: `battle_spawner.gd`, `battle_hud.gd`, `battle_flow.gd`. **Regra: só refatorar com a suíte verde e um item por commit.**

### 14. Save sem versionamento nem backup ✅ FEITO (2026-09-01)
- **Era**: 1 slot (`user://save_game.json`), sem campo `version`, sem backup.
- **Fix aplicado**: `SAVE_VERSION = 2` em `game_manager.gd`; `save_game()` grava `"version"` no JSON e rotaciona o save anterior para `user://save_game_backup.json` (copy_absolute) antes de sobrescrever; `load_game()` valida parse/Dictionary e cai no backup quando o save principal está corrompido (`_load_backup`/`_restore_save` extraído). Saves antigos (sem version) carregam normalmente. 4 testes (`test_save_versioning.gd`: version no save, rotação, fallback de carga, carga limpa sem save). Suíte: 679/679.
- **Não feito** (YAGNI por ora): autosave no `NOTIFICATION_WM_CLOSE_REQUEST` e migração automática — o campo `version` já destrava a migração quando houver necessidade real.

### 15. Higiene de recursos (RID leaks no exit)
- Fontes/texturas alocadas e não liberadas no shutdown dos testes. **Nota (2026-09-01)**: os leaks aparecem só no exit da suíte GUT headless (RIDs de Canvas/CanvasItem/TextServer + 917 orphans) — cosmético, não afeta o jogo em runtime. Baixa prioridade; revisar `free()` nos autoloads.

### 16. Curva de balanceamento não auditada
- Stats dos inimigos fixos; Ato IV (Aurius 800 HP) vs progressão de Kael — verificar se os gates de XP/memória produzem power curve compatível. Criar spreadsheet/data-driven de balanço por ato.

### 17. Menu sem "Continuar" (verificar) ✅ JÁ RESOLVIDO (verificado 2026-09-01)
- `main_menu.gd` já tem `ContinueButton` conectado a `_on_continue()` e desabilitado quando não há `user://save_game.json` (`main_menu.gd:4/12/17/34`). Sem ação necessária.

---

## Ordem sugerida para amanhã (1 mecânica + teste + commit cada)

| # | Item | Racional |
|---|---|---|
| ~~1~~ | ~~P0-1 Boss por nome~~ | ✅ feito (2026-08-31) |
| ~~2~~ | ~~P0-2 animators por instância~~ | ✅ feito (2026-08-31) |
| ~~3~~ | ~~P0-3 troca de sprite na evolução~~ | ✅ feito (2026-08-31) |
| ~~4~~ | ~~P0-4 BGM data-driven~~ | ✅ feito (2026-08-31) |
| ~~5~~ | ~~P0-6 pre-check de png~~ | ✅ feito (2026-08-31) |
| ~~6~~ | ~~P0-5 shaders~~ | ✅ feito e validado (2026-08-31, probe opengl3) |
| ~~7~~ | ~~P1 #10 encounters/puzzles~~ | ✅ feito (2026-08-31, puzzles data-driven) |
| ~~8~~ | ~~P1 #9 ondas do Ato III~~ | ✅ feito (2026-09-01) |
| ~~9~~ | ~~P1 #10 locks do cast inimigo~~ | ✅ feito (2026-09-01) |

### P1 #9 — Ondas escaladas do Ato III ✅ FEITO (2026-09-01)
- **Onde**: `arena_battle.gd` (caminho principal SoS) e `BattleManager.gd` (grid legado), dados em `map_database.gd`.
- **Implementação**: mapa pode declarar `"waves": [{"enemies": [...], "stat_scale": f}]` data-driven. Onda 1 é o spawn inicial (composição da onda, não `enemy_count`); ondas 2..N são reinjetadas ao limpar a arena, com stats escalados por `stat_scale` (padrão 1.0 + 0.25/onda), nome sufijado "(Onda N)" e entrada com vida cheia. `battle_ended`/`battle_won` só dispara após a última onda. Castelo Solaris (mapa 3, Ato III) declara 3 ondas (1.0 → 1.25 → 1.5 com santo_cardeal).
- **Legado**: `BattleManager.setup_waves()/spawn_next_wave()` espelha o mesmo contrato no grid, com fábrica opcional de unidades e `wave_started` emitida por reinjeção.
- **Testes**: `test_arena_waves.gd` (6) + `test_wave_spawner.gd` (5). Suíte: 611/611.

### P1 #10 — Locks do cast inimigo (GDD §3.2) ✅ FEITO (2026-09-01)
- **Onde**: `arena_combat.gd` (núcleo puro) + `arena_battle.gd` (cena), dados em `enemy_database.gd`.
- **Dados**: campo opcional `enemy_spell` por inimigo (`{name, damage, charge_turns, locks:[{type,hits}]}`) — Inquisidor e todos os 9 bosses (5 Cardeais + Aurius 3 fases + Santo Cardeal). Canais limitados a Corte/Éter (os dois tipos que o jogador entrega: físico/magia).
- **Núcleo**: `start_charge` cria locks via LockSystem; `hit_charge` dentes locks do tipo do golpe e faz spellbreak (charge limpo + stun 1 turno) ao quebrar todos; `tick_charge` no turno do canalizador — contador zerado = feitiço sai; `tick_stun` consome o spellbreak.
- **Cena**: IA com `enemy_spell` + MP inicia o canal em vez de atacar; alvo do jogador prioriza canalizador (locks atraem o golpe); físico = Corte, magia = Éter; stun faz o inimigo perder o turno.
- **Testes**: `test_enemy_spell_locks.gd` (8). Suíte: 619/619.
- **Grid legado (espelho, commit 4e035b6)**: spells com `locks`/`cast_turns` no MagicSystem (fire_bolt/fire_blast/shadow_bolt/holy_smite) viram preparação no `BattleManager.cast_magic` inimigo — locks nascem no caster (`LockSystem.begin_enemy_cast`), golpe do jogador com `UnitData.attack_type` reduz o lock, quebrar todos = spellbreak (stun 1 turno em `execute_enemy_ai` + sinal `enemy_stunned`), contador zerado = cast dispara no jogador mais próximo; MP gasto só na resolução; morte do caster cancela cast/locks. `battle_scene` aponta para o LockSystem do BattleManager (feedback CONJURANDO/SPELLBREAK). 9 testes (`test_enemy_cast_locks.gd`). Suíte: 637/637.

---

## Métricas da sessão (2026-08-30/31)

- Testes: 432 → **541** (+109), 0 falhando
- Commits: 10 (fixes de sintaxe, gating, epílogo, cutscenes, chefes data-driven, sprites HD, animação)
- Sprites: 15 → 28 (13 gerados via ComfyUI, 100% do elenco)
- De dívida zerada: parse errors `//`, em-dash nas keys, sprites órfãos, animações mortas
