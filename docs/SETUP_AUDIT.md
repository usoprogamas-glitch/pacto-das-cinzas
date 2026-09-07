# Setup Audit — 2026-09-07 (via /setup-audit)

## Perfil do projeto
Godot 4.3, GDScript, pixel-art 2D (Sea of Stars), suíte GUT 83/735, pipeline LoRA ComfyUI (Python),
Obsidian como segundo cérebro. Sem web/frontend/mobile/cloud.

## Executado (com confirmação do usuário)

### Skills globais ARCHIVE — 81 movidas para `C:\Users\Administrator\.agents\skills-archive\`
Ficaram 33 skills ativas (game-dev/Godot/workflow):

`audio-design, build, code-reviewer, core-3d-animation, debugging-wizard, design-quest-mission-design,
feature-forge, find-skills, game-audio, game-balance-economy, game-design-theory, game-developer,
godot-animation, godot-gdscript-patterns, godot-shaders, godot-tilemap, godot-ui, humanizer, level-design,
performance-booster, pixel-art-sprites, prompt-engineer, python-pro, review, router, second-brain,
security-reviewer, skill-creator, skill-vetter, spec, spec-miner, test-master, the-fool`

Removidas do contexto (irrelevantes para Godot 2D): 12 web frameworks (angular/nextjs/vue/react*/...),
8 backends (django/laravel/rails/nestjs/fastapi/...), 6 cloud/devops (k8s/terraform/sre/monitoring/...),
remotion* (11), 3d web (threejs/r3f/babylon/web3d), mobile (flutter/react-native/swift/kotlin),
dados (pandas/sql/postgres/spark/rag/ml), e demais single-stack (rust/cpp/java/csharp/php/golang/swift...).

**Efeito**: ~81 SKILL.md (~10.4 MB, ~70k tokens de descrições) deixam de ser oferecidas a cada sessão.
Para restaurar qualquer uma: mover a pasta de volta para `.agents/skills/`.

### Commands Kilo criados
- `.kilo/command/setup-audit.md` — este auditor, reexecutável a qualquer momento (`/setup-audit`).

## Pareceres sem execução (fora do escopo deste repo)

### Plugins Claude Code (12, todos habilitados, instalados 26-27/08)
Mexer aqui muda o setup global do Claude Code do usuário, não este projeto. Parecer por plugin:

| Plugin | Parecer |
|---|---|
| claude-code-setup | KEEP — é o auditor ped pelo usuário (analisa e recomenda plugins/skills/hooks) |
| context7 | KEEP — docs atualizadas de libs (útil se migrar APIs Godot 4.x) |
| superpowers | KEEP — framework de skills genérico bem mantido |
| claude-mem | KEEP — memória persistente (complementa o Obsidian) |
| genjutsu | REVIEW — verificar se ainda é mantido/usado |
| codex | REVIEW — só se usar o Codex da OpenAI junto |
| agent-tasks | REVIEW — overlap com Agent Manager do Kilo |
| ponytail | REVIEW — statusline/custom, cosmético |
| codeknow | REVIEW — overlap com CARTOGRAPHY.md (mapa do codebase já cobre) |
| frontend-design | ARCHIVE — sem frontend no projeto |
| core-3d-animation | KEEP — já é skill ativa (babylon/three/gsap) |
| animation-components | ARCHIVE — web components, não pixel-art |

Comandos para agir (quando o usuário quiser, fora do Kilo):
`claude plugin remove frontend-design@claude-plugins-official` etc.

### Hooks (settings.json: `hooks: {}` — vazio)
Recomendação de 2 hooks baratos para o projeto (criar no Claude Code quando desejar):
1. **PreToolUse em Edit/Write** — bloquear edição sem conferir indentação do alvo (regra 1 do AGENTS.md; 3 quebras nesta semana).
2. **PostToolUse em Bash(git commit)** — rodar a suíte GUT antes de permitir o commit (regra 4).

## KEEP list por domínio (referência rápida)
- Godot/2D: godot-* (5), pixel-art-sprites, game-developer, level-design, audio-design, game-balance-economy, game-design-theory, game-audio, design-quest-mission-design, core-3d-animation
- Workflow: spec→build→review, feature-forge, test-master, code-reviewer, security-reviewer, debugging-wizard, spec-miner, router, find-skills
- Meta: second-brain, kilo-config, prompt-engineer, skill-creator/vetter, humanizer, performance-booster, python-pro, the-fool
