# Direção de Arte — Pacto das Cinzas

**Referência oficial (2026-09-06, pedido do usuário): Sea of Stars.** Toda geração de asset
(ComfyUI/LoRA), tileset, iluminação e UI deve mirar essa pegada.

## Pilares extraídos da referência (interior — Grande Biblioteca)

1. **Paleta**: base profunda de roxos/marrons dessaturados; acentos quentes saturados
   (velas, laranja/âmbar) puxam o olho; frio para sombra, quente para luz.
2. **Iluminação pontual com glow**: cada fonte de luz (vela, tocha) tem halo suave e
   gradiente de queda; nada de luz "flat" cobrindo o mapa inteiro.
3. **Densidade e camadas**: cenário com 3+ camadas (parede de fundo, objetos médios,
   primeiro plano); AO (oclusão) forte nos encontros parede/objeto/piso.
4. **Pixel art pintado, não flat**: tiles com sombreamento gradual e cores de rebote
   (não sombra cinza — sombra colorida pela luz ambiente local).
5. **Silhuetas legíveis**: personagens ~32–48px com leitura clara contra o fundo
   (fundo mais escuro/dessaturado onde o personagem anda).
6. **UI de diálogo**: retrato pixel do falante à esquerda, nome acima da caixa,
   palavras-chave coloridas dentro do texto, moldura escura com borda clara.

## Gap atual (QA shots 2026-09-06)

- Tiles procedurais do PixelArtRenderer: flat, sem luz pontual, sem vinheta.
- Ambientes com 1 camada + props; sem AO.
- Sprites HD (ComfyUI) — ok como base, mas sem grade/palette unificada com o cenário.
- Diálogo/cutscenes: sem retrato, sem keywords coloridas.

## Rotas de execução

- **A — Luz + grade (Godot, sem geração)**: PointLight2D nas fontes (velas/tochas),
  CanvasModulate quente, vinheta/grade shader no explore+arena. Imediato e reversível.
- **B — LoRA pixel-art (ComfyUI)**: treinar/instalar LoRA SoS-like para tiles/props/
  retratos; regenerar ambientes densos por bioma. Pendente: LoRA não instalado no
  servidor (só SDXL base + turbo LoRA não-pixel).
- **C — Tilesets reais**: edermunizz overworld já integrado no explore (`explore_scene.gd:657`,
  CC BY-ND 4.0 — uso ok, sem redistribuição); precisa de pack de INTERIOR para cenários
  como a Biblioteca.
