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

### 2. `unit_animators` colide com nomes duplicados 🐛
- **Onde**: `battle_scene.gd` — `unit_animators[unit_name] = animator`
- **Problema**: dois inimigos "Mercenário" na mesma batalha → o segundo **sobrescreve** o animator do primeiro; animações (walk/attack/death) tocam na unidade errada ou em nenhuma.
- **Impacto**: visível em todo encontro com inimigos repetidos (que é a regra, não a exceção).
- **Fix**: key por instância (`unit.get_instance_id()`) ou guardar o animator como filho nomeado da Unit e buscar nele; lookup em `_on_unit_attacked`/`_on_unit_died` muda junto.
- **Teste**: spawnar 2 units de mesmo nome → 2 animators independentes.

### 3. Evolução de forma NÃO troca o sprite 🐛 ✅ CORRIGIDO (2026-08-31)
- **Onde**: `battle_scene.gd::_on_protagonist_form_changed` — só pisca o FormLabel.
- **Problema**: os 4 sprites de forma (`imp_menor`, `nobre_abissal`, `arquidemonio`, `avatar_primordial`) foram gerados mas **nunca aparecem** — a unit do Kael continua com o sprite da forma 1 o jogo inteiro.
- **Fix aplicado**: `_apply_protagonist_form_stats` agora chama `_swap_protagonist_sprite(unit, new_form)` — troca a textura do MESMO nó Sprite2D (animator não perde referência) + re-normaliza à célula de 32px. Png ausente → textura mantida. 6 testes (`test_form_sprite_swap.gd`).

### 4. Música não existe em runtime 🐛
- **Onde**: `map_database.gd` define `"music": "exploration"/"battle"` por mapa — **nenhum código lê esse campo**. `SoundManager.play_sfx` é chamado (select/step/hit/death), mas zero BGM.
- **Impacto**: jogo inteiro em silêncio de fundo; campo de dados morto.
- **Fix**: `SoundManager.play_music(track)` procedural (sound_generator já gera áudio) chamado no `setup_battle` lendo `current_map.music`, data-driven.
- **Teste**: setup_battle → SoundManager recebe track do mapa.

### 5. Shaders do PixelArtRenderer não compilam 🐛
- **Onde**: `pixel_art_renderer.gd` (853 linhas) — GLSL inválido: `Range hint is for 'float' and 'int' only` (uniforms com hint em tipos errados), `Tokenizer: Unknown character #1` (caracteres não-ASCII dentro de shader code).
- **Impacto**: outline, glow, rim light, water, grass, dither — **todos mortos silenciosamente** no jogo.
- **Fix**: corrigir hints (`hint_range` só em float/int), remover/caracteres especiais dos comentários GLSL, validar cada shader.
- **Teste**: headless não compila shader — validar via script de sanity (material != null, shader.code ASCII-safe) + inspeção visual.

### 6. Log poluído por probe de png faltante
- **Onde**: `_load_hd_sprite` faz `img.load()` direto → Godot imprime ERROR para cada nome sem png (`fantasma`, `guerreiro`, `teia`...).
- **Impacto**: cosmetico, mas mascara erros reais em produção.
- **Fix**: `FileAccess.file_exists(path)` antes do load (o teste de fallback continua válido).

---

## P1 — Conteúdo do ROADMAP (após P0)

### 7. ROADMAP #11 — Timed blocks (mitigação na defesa) 🟡
- `timed_hit_system` cobre só ataque; defesa reativa (bloqueio com timing) é o outro lado do combate-assinatura §3.1. Espelhar o pipeline existente.

### 8. ROADMAP #10 — SeamlessEncounter + LightPuzzle órfãos 🟡
- Sistemas prontos e testados, **zero instanciação runtime**. Conectar: encuentros por proximidade no overworld/map_select e 1-2 puzzles posicionados data-driven em mapas dos Atos I-II.

### 9. Ato III em ONDAS (decisão #7 pendente de execução) 🟡
- Decisão tomada (turno por-fase + ondas escaladas), execução inexistente. `BattleManager` precisa de wave spawner (reinjetar inimigos com stats escalados por onda).

### 10. Locks não nascem do cast inimigo 🟡
- LockSystem só no caminho do jogador. Cast inimigo deveria criar lock defensivo (GDD §3.2).

### 11. Taberna #12 / Travessia #13 / Culinária #14 🟡
- Parciais: apostas, vertical/arpéu, bônus permanentes de cozinha. Conteúdo sobre sistemas vivos.

### 12. Equipamentos sem wiring? (verificar)
- `crafting/` (recipe/material/equipment databases + crafting_manager + crafting_ui) — wiring não auditado nesta passada. Confirmar se alcançável pelo jogador; senão, entra como órfão na lista.

---

## P2 — Qualidade / arquitetura

### 13. `battle_scene.gd` = 1431 linhas (god file)
- Concentra spawn, UI, HUD, combate, campanha, progression. Extrair em módulos coesos: `battle_spawner.gd`, `battle_hud.gd`, `battle_flow.gd`. **Regra: só refatorar com a suíte verde e um item por commit.**

### 14. Save sem versionamento nem backup
- 1 slot (`user://save_game.json`), sem campo `version` (migração futura impossível), sem backup rotativo, sem save-on-quit.
- Fix mínimo: `"version": 1` no save_data + backup `.bak` + autosave no `NOTIFICATION_WM_CLOSE_REQUEST`.

### 15. Higiene de recursos (RID leaks no exit)
- Fontes/texturas alocadas e não liberadas no shutdown dos testes. Baixa prioridade; revisar `free()` nos autoloads.

### 16. Curva de balanceamento não auditada
- Stats dos inimigos fixos; Ato IV (Aurius 800 HP) vs progressão de Kael — verificar se os gates de XP/memória produzem power curve compatível. Criar spreadsheet/data-driven de balanço por ato.

### 17. Menu sem "Continuar" (verificar)
- `GameManager.load_game()` existe; confirmar se o `main_menu` expõe "Continuar". Se não, o save só é usado indiretamente.

---

## Ordem sugerida para amanhã (1 mecânica + teste + commit cada)

| # | Item | Racional |
|---|---|---|
| ~~1~~ | ~~P0-1 Boss por nome~~ | ✅ feito (2026-08-31) |
| ~~2~~ | ~~P0-2 animators por instância~~ | ✅ feito (2026-08-31) |
| ~~3~~ | ~~P0-3 troca de sprite na evolução~~ | ✅ feito (2026-08-31) |
| 4 | P0-4 BGM data-driven | campo `music` já existe nos dados |
| 5 | P0-6 pre-check de png | trivial, limpa o log |
| 6 | P0-5 shaders | médio; isolar shader por shader |
| 7 | P1 #11 timed blocks | próximo mecânica-assinatura |
| 8 | P1 #10 encounters/puzzles | destrava sistemas órfãos |

---

## Métricas da sessão (2026-08-30/31)

- Testes: 432 → **483** (+51), 0 falhando
- Commits: 10 (fixes de sintaxe, gating, epílogo, cutscenes, chefes data-driven, sprites HD, animação)
- Sprites: 15 → 28 (13 gerados via ComfyUI, 100% do elenco)
- De dívida zerada: parse errors `//`, em-dash nas keys, sprites órfãos, animações mortas
