# UI Refinement Plan — O Pacto das Cinzas

Data: 2026-08-25 | Status: Em desenvolvimento

## Objetivo
Refinar os elementos visuais do HUD de batalha (battle_scene.gd) para melhor feedback ao jogador, conectando os sinais dos sistemas §6-7.

## Componentes

1. **Combo Points (CP)** — 3 pontos máx. Indicador visual (círculos/dots) + label textual.
2. **Éter / Fúria (Balance Bar)** — Barra bipolar 0-100. Cor: Éter (cobalto) / Fúria (vermelho) / Simbiose (roxo).
3. **Boss HP Panels** — Barra de HP do chefe com seções quebráveis (parte do BossSystem).
4. **Traversal / Camp / Cooking / Tavern** — ✅ Implementado: painel de ações §6-7 em battle_scene.gd (4 botões) que excita os sinais já conectados (traversal_completed, rest_completed, recipe_crafted, game_over) e alimenta o HUD de progressão. Testes: `test_battle_actions.gd` (5). Ver `docs/ui_refinement/UI_Refinement_Plan.md` → smoke manual pendente.

## Arquivos envolvidos
- `scripts/battle/battle_scene.gd` (HUD e handlers já conectados)
- `.godot/global_script_class_cache.cfg` (atualizado)
- `tests/unit/test_...` (manter 328 testes)

## Próximo passo
Implementar as alterações no `battle_scene.gd` e adicionar elementos visuais na cena.
