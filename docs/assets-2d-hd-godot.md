# Assets 2D para O Pacto das Cinzas

Pesquisa de assets para Godot 4, orientada pela referência visual de **Sea of Stars** e pela ambientação de fantasia sombria do projeto.

> Preços, disponibilidade e licenças foram conferidos em 21/08/2026 e podem mudar. Leia sempre o arquivo `LICENSE` incluído no download antes de publicar o jogo.

## Assets gratuitos

### Fantasy Battle Pack

- [Página do asset](https://mattwalkden.itch.io/fantasy-battle-pack)
- Download: nomeie seu preço
- 11 classes com idle, movimento, ataque e morte
- Quatro direções, cursores e áreas de alcance
- Tiles para masmorras, natureza, ruínas e água animada
- Licença royalty-free para projetos pessoais e comerciais
- Escala: grid 16x16; frames de personagem 32x32
- Melhor uso: protótipo das falanges e batalhas de larga escala

### Pixel RPG VFX Pack

- [Página do asset](https://pewas.itch.io/pixel-rpg-vfx-pack-free-animated-effects)
- Download: gratuito
- 35 efeitos animados de explosão, corte, aura, projétil, escudo, cura e impacto
- Cores: fogo, gelo, veneno, sagrado e arcano
- Resoluções: 32, 64, 128 e 256 px
- Formatos: PNG spritesheet, frames PNG individuais e GIF
- Compatível com Godot
- Uso pessoal e comercial permitido; não redistribuir o pack como está
- Observação: o autor declara uso de pipeline assistido por IA

### Diamond - Top Down Pixel Art Pack

- [Página do asset](https://dotmancer.itch.io/diamond-top-down-pixel-art)
- Download: gratuito
- Projeto exemplo pronto para Godot
- Mais de 712 frames, personagens, monstro, floresta, UI e ícones
- Inclui sistema de combate, IA básica, autotiling e UI de exemplo
- Assets em PNG, também compatíveis com Unity, GameMaker e RPG Maker
- Uso comercial e modificação permitidos; não redistribuir os assets
- Melhor uso: aprender a importar assets e montar um protótipo jogável

### 2DPIXX - Free 2D Isometric Fantasy Pack

- [Página no Godot Asset Store](https://store.godotengine.org/asset/twodpixx/test/)
- Download: gratuito
- Tilesets de dungeon, floresta e vila
- Wizard, warrior e archer com idle, walk e attack em quatro direções
- PNG em 128x128 e spritesheets de personagens em 128x160
- Licença: Creative Commons Attribution 4.0
- É obrigatório dar atribuição a Jana Ochse / 2DPIXX
- Melhor uso: estudo e protótipo isométrico; não é a melhor base para o visual final

### Demo de personagens Fantasy RPG Characters Pack

- [Página do asset](https://pixel-banner.itch.io/rpg-characters-pack)
- Demo gratuita com dois personagens
- A versão completa tem 23 inimigos, mas é paga
- A licença permite uso comercial e modificação; não redistribuir os assets
- Observação: os personagens usam apresentação lateral, não quatro direções top-down

## Assets pagos que combinam com o projeto

| Asset | Melhor uso | Escala / conteúdo | Preço observado |
|---|---|---|---:|
| [Emberfen](https://najjar320.itch.io/emberfen-top-down-rpg-tileset) | Base do mapa e personagens | 32x32, 620 arquivos, 6 personagens, UI e terrains para Godot 4 | US$ 4 em promoção |
| [Winlu Fantasy Overworld](https://winlu.itch.io/fantasy-overworld) | Overworld de Aethelgard | 48x48, wasteland, desertos, templos, castelos e Godot Textures | US$ 17,50 em promoção |
| [Volcanic Inferno Dungeon](https://sakpix.itch.io/volcanic-inferno-dungeon-complete-pixel-art-tileset) | Nação das Cinzas e arenas | 32x32, lava, obsidiana, cinzas, armadilhas e partículas | US$ 4 em promoção |
| [HIKARI Monster Vol. 1](https://hikari-ex.itch.io/fantasy-monster-pack-vol1) | Inimigos comuns animados | 9 monstros, PNG, Aseprite, 5 animações | US$ 1 |
| [Raven Fantasy Battler Set 2](https://clockworkraven.itch.io/raven-fantasy-pixel-art-creatures-battler-set-2) | Chefes e combate JRPG | 22 criaturas, 2 chefes, 64x64 e 128x128; estáticos | US$ 10 |
| [Pixel Art RPG VFX](https://pixogenassets.itch.io/pixel-art-rpg-vfx) | Magias e impactos premium | 636 sprites em 108 animações | EUR 19,99 |

## Combinação recomendada

Para começar sem gastar:

1. **Diamond** para aprender a estrutura de um projeto Godot 4.
2. **Fantasy Battle Pack** para testar as batalhas e a escala dos exércitos.
3. **Pixel RPG VFX Pack** para dar resposta visual aos ataques e habilidades.
4. **2DPIXX** apenas se o protótipo usar perspectiva isométrica e a atribuição estiver visível.

Para uma base visual mais consistente no jogo final, a recomendação é **Emberfen + Volcanic Inferno + VFX**, criando os quatro Apóstolos, o protagonista e Aurius com sprites originais ou encomendados no mesmo estilo.

## Regras de importação no Godot

- Use filtro `Nearest` para preservar os pixels.
- Evite misturar 8x8, 16x16, 32x32 e 48x48 na mesma camada sem definir uma escala de conversão.
- Use 32x32 como escala principal sugerida para mapas e personagens.
- Reserve 64x64 ou 128x128 para battlers e chefes.
- Para spritesheets, valide a quantidade de colunas, linhas e frames antes de montar o `SpriteFrames`.
- Para TileSet, teste os terrains em uma cena pequena antes de pintar o mapa inteiro.
- Guarde a URL e o `LICENSE` de cada asset em uma pasta de documentação do projeto.

## Avisos de licença

Uso comercial não significa que os PNGs podem ser revendidos separadamente. Em geral, os assets podem ser incluídos dentro do jogo, mas não podem ser redistribuídos como outro pacote de assets. O pack **2DPIXX** exige atribuição. O pack VFX de **pewas** declara pipeline assistido por IA. Verifique os termos atuais antes do lançamento.
