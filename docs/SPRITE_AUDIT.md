# Sprite Audit — assets/sprites (27 PNGs ComfyUI, 2026-09-08)

**Veredito: TODOS os 27 sprites estão em uso real ou reservado pelo GDD — nada a remover.**
Primeiro scan marcou 19 como "órfãos"; rastreando os chains descobriu-se que eram
falsos órfãos (mapeamento indireto). Detalhes abaixo.

## Grupos de uso

### 1. Party + protagonista (9) — usados diretamente
| Sprite | Uso |
|---|---|
| kael | protagonista (arena + placa + retrato) |
| kroug | aliado inicial (`starting_ally`) + placa/retrato |
| lira, thalkor | party futura (GDD §3) — battle_spawner tem create_lira/create_thalkor |
| imp_menor, nobre_abissal, arquidemonio, avatar_primordial | **formas da evolução do Kael** (character_progression §8; `_swap_protagonist_sprite` troca via `_sprite_key("Imp Menor")` → "imp_menor") |

### 2. Inimigos comuns dos mapas (8) — usados como FALLBACK
| Sprite | Mapa/uso |
|---|---|
| mercenario, cacador | Fronteira (mapa 0) |
| esqueleto | Caverna (2) |
| paladino, inquisidor | Castelo Solaria (3) |
| troll | Vulcões (4/5) |
| lobo_sombrio, aranha_gigante | Floresta Sombria (1) |
| goblin_da_lama | EnemyDatabase `goblin_lama`, sprite casado por `_sprite_key("Goblin da Lama")` |

**Nota**: com `assets/sos_clean` presente (local), a arena usa os sprites reais do
SoS (StrifeMinion/Owlsassin/BilePile...). Os PNGs ComfyUI são o **fallback de CI/QA**
(onde sos_clean não é commitado) — permanecem.

### 3. Bosses (10) — usados por boss_system/campaign
| Sprite | Boss |
|---|---|
| santo_cardeal | boss do Ato I (menção), enemy_database |
| ignis | Cardeal Ignis (cardeal_ignis, Ato II) |
| zephyr | Cardeal Zephyr |
| aqua | Cardeal Aqua |
| terra | Cardeal Terra |
| umbra | Cardeal Umbra |
| aurius_falso_demiurgo | Aurius fase 1 (aurius_fase1) |
| aurius_serafim_tirano | Aurius fase 2 |
| aurius_luz_desesperada | Aurius fase 3 |
| chefe_orc | boss_enemy do Ato I (campaign L12) |

## Falsos órfãos explicados (lição de auditoria)

Meu primeiro grep marcou 19 sem referência — todos com mapeamento indireto:
1. **cardeal_X → X.png**: boss_system/cardeal_ignis mapeia via `replace("cardeal_", "")`
2. **aurius_faseN → aurius_*.png**: boss_system fases (3 fases do GDD §5)
3. **"Goblin da Lama" → goblin_da_lama.png**: `_sprite_key` normaliza nome→snake_case
4. **"Imp Menor" → imp_menor.png**: formas do protagonista via `_sprite_key(new_form)`
5. **chefe_orc**: `boss_enemy` do campaign_system, não do MapDatabase

**Lição**: sprites são referenciados por `_sprite_key(nome exibido)` — auditoria de
assets precisa seguir o CHAIN (banco → nome exibido → key), não grep de ID.

## O que melhorar (não é remoção)

1. **Cardeais reutilizam sprites elementais com mesmo nome da party?** Não conflita:
   a party do GDD v2 é Kael/Kroug/Lira/Valera/Brugaves — Ignis/Zephyr/Aqua/Terra/Umbra
   são os CARDEAIS. OK.
2. **Inimigos comuns ComfyUI** ficam como fallback oficial — e são a fonte dos
   combat sets gerados por bandas quando sos_clean não tem o inimigo.
3. **Novos sprites valiosos** (pipeline LoRA pronto): Valera e Brugaves (party GDD
   ainda sem sprite próprio), TorredeVigia/cenários grandes.
