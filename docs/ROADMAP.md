# ROADMAP — O Pacto das Cinzas

> Documento vivo de progresso (não especulação): estado verificado contra o código em 2026-08-29.
> **Engine** Godot 4.3 | **Testes** GUT headless 403/403 ✅ | **Último commit** `931d92e` (IA caster lança magia)
> Fonte de lore/spec: [GDD_Completo_v2.md](GDD_Completo_v2.md) | Tracking técnico anterior: memória do projeto

**Legenda de estado**
- ✅ **Vivo** — código real, ligado ao runtime e testado
- 🟡 **Órfão** — código real e testado isolado, mas NUNCA alcançado no jogo (instanciado e nunca conectado)
- ⚪ **Spec** — citado no GDD, código inexistente/irrelevante

---

## Começo — onde estamos agora (base jogável)

Existe um único caminho jogável: **intro → menu → map_select → 1 batalha → resultado → menu**. Mais a village_scene (sandbox, **inalcançável** de jogo novo) e o settings.

O **loop tático individual** está sólido e testado: turnos por fase (PLAYER→ENEMY), grid, IA inimiga (10 arquétipos + caster com magia), dano pipeline (terreno→flanco→adjacência→timed), Éter/Fúria, combos, lock break, chefes 1-way, acampar/cozinhar/taberna/travessia, progressão persistente no save.

## Meio — o que falta para ser um jogo (do menu ao epílogo)

PRIORIDADE 1 (bloqueia o resto) — **a campanha**:

Agente auditoria (per-aspect):

| # | Pendência | Sistema(s) | Estado | Por que importa |
|---|---|---|---|---|
| 1 | **Morte por magia não encerra batalha** | BattleManager.cast_magic | ✅ feito (`e21bd99`) | Caster mata alvo → HP 0 fica no grid, sem `unit_died`/soul_ether; `battle_won` pode não disparar |
| 2 | **Fluxo de campanha (atos)** | — | ⚪ | Hoje: 1 batalha + sandbox. Falta: encadeamento intro→ato→batalhas→chefes→créditos |
| 3 | **Naming/Pacto de Alma como mecânica viva** | NamingSystem+NamingUI | 🟡 morto | A mecânica-assinatura do lore NUNCA roda: nomear um monstro caído, ganhar apóstolo, metamorfose |
| 4 | **Overworld + desbloqueio de mapa por ato** | map_select | 🟡 gated hardcoded | `unlocked:false` sem condição; batalhas não destravam o próximo mapa |
| 5 | **Kaelen HUD** (análise bio/psi/tática, "nome sugerido") | KaelenSystem | 🟡 morto | GDD §3.4 inteiro está inalcançável (instanciado, sinais nunca conectados) |
| 6 | **Feedback de evolução de forma** | CharacterProgression | 🟡 parcial | Evoluir muda só estado interno/atalho no HUD — nada muda no mundo (stats/visual/inimigos) |
| 7 | **Decisão: turno individual vs 1.000+ unidades** | TurnOrderManager | 🟡 morto | velocity-sort é órfão (default fase); GDD promete batalhas de 1.000 unidades — escolher UM modelo |
| 8 | **Conteúdo de chefes de verdade** | BossSystem | 🟡 1-way | Só alcançável marcando inimigo "Boss"; os 5 Cardeais + Aurius de 3 fases são spec |
| 9 | **Continuidade do nome no save** | unit nome | 🟡 | Nomes são literais da battle_scene ("Kroug"), desconectados do save/apóstolos |

PRIORIDADE 2 (após a campanha existir):

| # | Pendência | Estado | Nota |
|---|---|---|---|
| 10 | Conectar SeamlessEncounter + LightPuzzle ao overworld | 🟡 | sistemas prontos, zero instanciação runtime |
| 11 | Timed **blocks** (mitigação de dano na defesa) | 🟡 parcial | só o caminho de ataque existe |
| 12 | Taberna: apostas + recompensas exclusivas (hoje autobattle) | 🟡 parcial | vira conteúdo |
| 13 | Travessia vertical / arpéu (hoje só dash) | 🟡 parcial | vira conteúdo |
| 14 | Culinária com bônus permanentes | 🟡 parcial | hoje temp only |

## Fim — os 4 Atos (alvo de conteúdo)

Do [GDD §1](GDD_Completo_v2.md): a arco começo→fim. Hoje nada disso tem cena — é o conteúdo a construir sobre a base técnica.

| Ato | Cenário | Forma do protagonista | Apóstolo destaque | Inimigo principal | Marcos do ato | Estado |
|---|---|---|---|---|---|---|
| **I — Fronteira Cinzenta** | vale vulcânico estéril | Imp Menor / Querubim (0% memória) | **Kroug** (Goblin da Lama) | Hienas & Batedores | Salvar goblins → **nomear Kroug** (1º Pacto) → derrotar chefe orc → purificar a fonte → 1º Acampamento das Cinzas | ⚪ só lore |
| **II — O Despertar** | Vale dos Despojos / Florestas Queimadas | Nobre Abissal (25% memória) | Lira & Garm (Dríade / Lobo) | Inquisidores de Aço | Migração de criaturas; **ataque noturno** da Inquisição; executar o Grande Inquisidor; Nação das Cinzas nasce | ⚪ só lore |
| **III — Guerra Fria** | Aethelgard em guerra (anões/elfos/tricheiras) | Arquidemônio (75% memória) | Thal'kor | Santos Cardeais & Paladinos | Libertar os Anões dos Picos de Cinza e os Elfos Caídos; Guerra Santa; cerco nos Desfiladeiros de Ferro; quebrar a Linha Dourada | ⚪ só lore |
| **IV — Queda de Solaria** | Solaria, Cidade Eterna | Avatar Primordial (100% memória) | Todos os 4 | **Aurius, o Falso Deus** (3 fases) | Marcha final; **revelação de Kaelen** (máquina de vingança) e a escolha de abraçá-lo; executar Aurius; Tratado do Éter e da Carne | ⚪ só lore |

**Gate de progressão já existe** (GDD §8): 4 Atos + curva XP + avanço por memória(25/75/100)/almas(10/100/1000)/level(10/25/40), testes ✅. Falta o **conteúdo** que o gate destrava.

## Estado por sistema (auditado 2026-08-29)

Combate (§3–§5) — ```scripts/battle/```

| Sistema | GDD | Código | Wiring | Teste | Gap vs GDD |
|---|---|---|---|---|---|
| Timed Hits | §3.1 | ✅ | ✅ | ✅ | sem timed **block** |
| Locks | §3.2 | ✅ | ✅ | ✅ | locks não nascem do cast inimigo |
| Combos (CP) | §3.1 | ✅ | ✅ | ✅ | Triple Combo é dado-only (depende da party) |
| Éter/Fúria/Balance | §3.3 | ✅ | ✅ | ✅ | escala 1.000+ unidades ausente (ver #7) |
| Adjacency | §3 | ✅ | ✅ | ✅ | — |
| Flanking | §3 | ✅ | ✅ | ✅ | — |
| Terrain | §3 | ✅ | ✅ | ✅ | aplicado só no caminho individual |
| Magic | §3.3 | ✅ | ✅ (inimigo) | ✅ | **morte por magia não resolve a batalha** (#1) |
| Kaelen | §3.4 | ✅ | 🟡 morto | ✅ | HUD inteiro inalcançável (#5) |
| Lineage | §3.4/§4 | ✅ | ✅ (ato) | ✅ | evolução só no advance de ato |
| Boss | §5 | ✅ | 🟡 1-way | ✅ | Cardeais + Aurius = spec (#8) |
| TurnOrderManager | §5.1 | ✅ | 🟡 morto | ✅ | velocity-sort órfão (#7) |
| BattleManager/Grid/IA | §3 | ✅ | ✅ | ✅ | layer de equipamento ausente |

Exploração/campo (§6–§7) — ```scripts/battle/```

| Sistema | GDD | Código | Wiring | Teste | Gap vs GDD |
|---|---|---|---|---|---|
| Traversal | §6.1 | ✅ | ✅ | ✅ | só dash; sem vertical/arpéu (#13) |
| Seamless Encounter | §6.2 | ✅ | 🟡 morto | ✅ | zero instanciação runtime (#10) |
| Light Puzzle | §6.3 | ✅ | 🟡 morto | ✅ | zero puzzles posicionados (#10) |
| Campfire | §7.1 | ✅ | ✅ | ✅ | sem árvores de diálogo |
| Cooking | §7.2 | ✅ | ✅ | ✅ | bônus só temporários (#14) |
| Tavern | §7.3 | ✅ | ✅ | ✅ | autobattle, sem apostas (#12) |
| Progression | §8 | ✅ | ✅ + save | ✅ | evolução não muda o mundo (#6) |

Narrativa/mundo — ```scripts/narrative/```

| Sistema | GDD | Código | Wiring | Teste | Nota |
|---|---|---|---|---|---|
| CharacterProgression | §8 | ✅ | ✅ | ✅ | persistido |
| ProgressionSystem | §8 | ✅ | ✅ | ✅ | gates de ato prontos |
| NamingSystem | §2.1/§4 | ✅ | 🟡 morto | — | **a mecânica-assinatura, nunca roda** (#3) |

## Como usar este roadmap

- **A cada sessão**: comece pelo item de maior prioridade não-'✅' (hoje: **#1 morte por magia** — bug que quebra vitória).
- **Regra do projeto**: 1 mecânica por prompt + teste GUT junto + commit por feature + conteúdo data-driven (nada hardcoded).
- **Ao concluir um item**, atualize a tabela acima + a memória do projeto (commit e contagem GUT).

## Pendências já marcadas no código (ponytail:)

- `BattleManager.cast_magic`: morte por magia não emite `unit_died`/`unregister_unit` — item #1.