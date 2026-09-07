# AGENTS.md — Pacto das Cinzas (Godot 4.3, 2D pixel-art RPG)

## Protocolo de consulta (economia de tokens)

** Leia `docs/CARTOGRAPHY.md` ANTES de grepar/ler código.** Ele mapeia todos os
módulos (o que faz, onde está, quem chama quem, linhas-chave) e as convenções
críticas do projeto. Atualize 1 linha lá ao criar módulos novos.

## Comandos essenciais

- **Suíte GUT**: `C:\Godot43\Godot_v4.3-stable_win64_console.exe --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit` (83 scripts, 735 testes — deve ficar verde antes de qualquer commit)
- **QA visual**: mesmo Godot com `--rendering-driver opengl3 -s tools/qa_run.gd` (12 shots em `tools/qa_shots`; nunca `--headless` — screenshots exigem renderer real)
- **Rebuild de cache corrompido**: `--headless --path . --import` (não deletar `.godot/` seletivamente)

## Regras inegociáveis

1. Identação MISTA no repo (alguns arquivos usam 1 espaço, outros tab) — conferir o alvo antes de editar.
2. Testes instanciam cenas sem `_ready` e stubam com `.set()` — handlers toleram `null`.
3. Novo `class_name` não entra no cache headless — usar `preload`.
4. Nunca commitar sem a suíte verde. 1 módulo por commit em refactors.
5. Direção de arte: Sea of Stars (`docs/direcao_arte.md`). Assets via pipeline LoRA (`tools/comfy_sos_batch.py`).
6. Segundo cérebro do usuário (Obsidian `01 - Projetos/O Pacto das Cinzas/`) é atualizado quando ele pedir.

## Contexto vivo

- `docs/AUDIT.md` — auditoria P0/P1/P2 (tudo resolvido) + fila atual.
- `docs/GDD_Completo_v2.md` — lore/escopo (fonte de verdade do design).
- `docs/CARTOGRAPHY.md` — mapa do codebase (ver protocolo acima).
- Repo: github.com/usoprogamas-glitch/pacto-das-cinzas (main).
