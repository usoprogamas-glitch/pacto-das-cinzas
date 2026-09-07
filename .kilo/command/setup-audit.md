---
description: Setup audit - recomenda skills plugins hooks e arquiva o que suja o contexto
---

Voce e o Setup Auditor deste projeto. Siga em ordem:

## 1. Perfil do projeto
- Detecte a stack (engine, linguagens, testes, ferramentas) lendo `AGENTS.md`, `docs/CARTOGRAPHY.md`, `project.godot`/package.json/etc.

## 2. Inventario de contexto
- Skills globais: `C:\Users\Administrator\.agents\skills\` (pastas com SKILL.md)
- Skills do projeto: `.agents/skills/`, `.kilo/skills/`
- Commands: `.kilo/command/*.md`, `~/.config/kilo/command/*.md`
- Agents: `.kilo/agent/*.md`, `~/.config/kilo/agent/*.md`
- MCPs: `kilo.json` (global e projeto), campo `mcp`

## 3. Classificacao (para CADA skill/command/agent)
- **KEEP**: usado por este projeto ou por 2+ fluxos reais recentes
- **ARCHIVE**: irrelevante para a stack (mover para `C:\Users\Administrator\.agents\skills-archive\<nome>`; reversivel)
- **ADD**: lacuna clara com skill/hooks conhecida do ecossistema (proponha command/agent Kilo equivalente; plugins do marketplace Claude Code nao carregam no Kilo)

## 4. Relatorio (tabela)
| Item | Classe | Motivo em 1 linha |
Com totais de tokens estimados economizados (~40 tokens por SKILL.md carregada).

## 5. Execucao
- ARCHIVE: so com confirmacao do usuario na mesma sessao (impacta todos os projetos).
- ADD: crie em `.kilo/command/` ou `.kilo/agent/` (nada fora do repo sem confirmacao).
- Atualize `docs/CARTOGRAPHY.md` se criar modulo novo.

## Regras
- NUNCA apagar: mover para archive e sempre o mecanismo.
- Intocaveis: `comfy_local`, `second-brain`, `kilo-config` e o fluxo `spec`->`build`->`review`.
- Ignore `skills-archive` no inventario.
