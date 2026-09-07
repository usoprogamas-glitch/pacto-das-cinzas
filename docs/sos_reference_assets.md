# Referência de ASSETS — Sea of Stars (métricas medidas 2026-09-07)

> Fonte: 12 maiores Addressables bundles (385.761 objetos, 4.395 Texture2D,
> 4.216 Sprites, 3.104 AnimationClips). Métricas em `tools/sos_asset_metrics.json`.
> **Nenhum asset copiado** — o que usamos são as REGRAS de produção medidas.

## Números de escala (o que "AAA 2D pixel" significa de verdade)

| Métrica | Valor SoS | Pacto hoje | Ação |
|---|---|---|---|
| Texturas (12 bundles) | 4.395 | ~50 props + 28 char atlas | nossos assets são poucos e ok |
| Sprites | 4.216 | 7357 frames decodificados (sos_motion_loader) | já herdamos a escala via atlas |
| AnimationClips | 3.104 | ~20 anims por char | **aumentar frames de combate** |
| Tiles (mediana) | **64×64** | 32px no canvas | SoS renderiza 64px/tile — nosso LoRA tile 96px está na escala certa (96>64) |
| UI (mediana) | 267×45 | ~36px bars | banners/banner SoS: 267×45 — nosso HUD réplica usa proporção parecida |
| FX | textura por efeito (FlareString = 30 frames) | partículas CPUParticles | FX grandes viram sequência de textura, não partícula |
| Render interno | 88 texturas **1080×540** | 1280×720 canvas_items | SoS renderiza 540p interno + upscale pixel-perfect (35 símbolos PixelPerfect!) |

## Convenção de nome de sprite (decodificada)

`<Char><Part>_<Anim>_D<dir>_F<frame2d>` — ex.: `DwellerOfTormentBody_StompLeft_D5_F09`

- **Personagens grandes são RIGGED CUTOUT**: boss = **459 sprites** (Body/ArmRight/ArmLeft
  trocáveis por anim). Nada de spritesheet monolítico para bosses.
- **D<dir>**: 560 sprites todos D5 (frente) nesse bundle — direções são fatias separadas.
- **Frames por anim**: IdleCombat 24, ataques 20-32 frames, Intro 28. Combate SoS é RICO.
- Anims descobertas: StompLeft/Right, RockLob, ThrowBack/Front, CatchBack/Front, StunIn/Out,
  SonicPainIn, TrampolineTest (nome de teste commitado — até eles deixam bagunça!).

## Paleta

- Mediana de cores únicas por textura: **10 cores** (223 de 358 amostradas ≤64 cores).
- Nosso quantize LoRA usa 24 cores → **alinhado com SoS** (eles usam ainda menos por sprite).
- Texturas de partícula/FX: 1 cor (canal alpha) — FX são máscaras monocromáticas coloridas no shader.

## Naming / organização

- Assets por **região/ato**: `SleeperIsland`, `EvermistIsland`, `WatcherIsland`, `MesaIsland`,
  `Horloge`, `WorldMap` — igual nossa organização por bioma no MapDatabase.
- `Palette` como nome de asset (67×): paletas são recursos nomeados e reutilizáveis.
- UI prefixo `icn` (329 ícones), `dialog` (214), `battle` (146).
- Áudio: 0 AudioClips nos bundles — **100% Wwise** (377 .bnk por região:
  `SB<n>_<Região>_<Subárea>` + `SFX_Common` global).

## Padrões de pipeline (arquitetura confirmada pelos metadados)

1. **PixelPerfect como módulo próprio** (35 símbolos): resolução interna 1080×540 fixa +
   upscale inteiro. Nosso 1280×720 com canvas 320×180 já segue a filosofia.
2. **Sprites fatiados + rig** para personagens grandes (menos memória, partes reutilizáveis).
3. **FX por sequência de texturas** nomeadas `_F00.._F30` (flares, trails, sunball 66 frames).
4. **Paletas nomeadas** reutilizadas entre assets do mesmo bioma.

## Aplicar no Pacto (priorizado)

1. **Anims de combate com mais frames**: nossos ataques têm ~6-10 frames; SoS usa 20-32.
   Alvo: 16-24 frames nos ataques básicos da arena (via LoRA/procedural).
2. **Boss fatiado em partes** quando fizermos o boss do Ato II: Body/ArmX separados,
   rig simples de rotação — não spritesheet única.
3. **Convenção de nome** para nossos sprites gerados: `<Char>_<Anim>_D<dir>_F<NN>`
   (o sos_motion_loader já decodifica o formato SoS; padronizar os nossos no mesmo formato
   significa reusar o loader para nossos assets).
4. **FX sequencial para magias fortes** (Sunball = 66 frames!): Sunball/Moonerang
   level do nosso combo pode virar sequência de 12-16 texturas quantizadas.
5. **Paletas nomeadas por bioma** no pipeline LoRA: quantizar todos os assets do bioma
   contra a MESMA paleta (consistência visual que SoS tem e nós quase temos).
6. **Considerar render interno 1080×540** se aparecer shimmering em 720p (pixel-perfect
   downscale do nosso 1280→540/2 = 640 não fecha inteiro; 1080×540 = 2x de 540p).
