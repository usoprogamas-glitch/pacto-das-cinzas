# Auditoria e fontes de assets

Documento consolidado para **O Pacto das Cinzas**, um RPG tático em Godot 4 com fantasia sombria e referência visual em Sea of Stars.

> Auditoria e pesquisa verificadas em 21/08/2026. Preços, versões e licenças podem mudar.

## Diagnóstico atual

O projeto tem uma boa base de conceito, cenas, bancos de dados e sistemas separados. Porém ainda é um protótipo: muitos sistemas existem como esqueleto e não estão ligados em uma experiência contínua.

O objetivo imediato deve ser fazer este ciclo funcionar sem erros:

**Iniciar -> Introdução -> Escolher mapa -> Batalha -> Vitória -> Recompensas -> Vila -> Salvar -> Continuar**

## P0 - Bloqueadores imediatos

### Introdução

- `GameManager` cria uma segunda instância de `IntroStory` sem os nós visuais da cena.
- A introdução termina ficando invisível, mas não leva o jogador ao menu, mapa ou batalha.
- A lógica de escolhas está dentro do bloco errado em `intro_story.gd`.
- As consequências podem ser aplicadas duas vezes, inclusive o custo de mana.

Arquivos: [`game_manager.gd`](https://github.com/usoprogamas-glitch/pacto-das-cinzas/blob/main/scripts/game_manager.gd#L31-L79) e [`intro_story.gd`](https://github.com/usoprogamas-glitch/pacto-das-cinzas/blob/main/scripts/ui/intro_story.gd#L94-L158).

### Batalha

- O nó `BattleGrid` da cena é apenas `Node2D` e não tem o script `grid.gd` anexado.
- O autotile mistura APIs de `TileMap` e `TileMapLayer`.
- Quando um mapa existe, `setup_battle()` cria inimigos, mas não cria Kael nem aliados.
- `start_battle()` não é chamado de modo confiável.
- O turno inimigo não retorna ao turno do jogador.
- O estado global de `BattleManager` não é limpo ao reiniciar a cena.
- A unidade selecionada localmente não é sincronizada com `BattleManager`.
- A barra de HP só é atualizada no ramo de ataque inimigo.
- Vitória e derrota podem ser emitidas mais de uma vez.

Arquivos: [`battle_scene.gd`](https://github.com/usoprogamas-glitch/pacto-das-cinzas/blob/main/scripts/battle/battle_scene.gd#L78-L103) e [`BattleManager.gd`](https://github.com/usoprogamas-glitch/pacto-das-cinzas/blob/main/scripts/battle/BattleManager.gd#L55-L90).

### Estabilidade

- Há métodos e variáveis duplicados nos scripts visuais.
- `PixelArtRenderer` é usado como se fosse estático, mas os métodos são de instância.
- Existem chamadas com assinaturas incompatíveis em animação e efeitos de tela.
- O projeto não contém assets finais: spritesheets, tilesets, fontes, música ou efeitos sonoros reais.

## P1 - Vertical slice completa

Para deixar uma primeira versão realmente jogável, ainda falta:

- Magias e habilidades aplicarem dano, cura, buffs, custos e cooldowns.
- Status funcionais: veneno, silêncio, cegueira, stun, lentidão e sangramento.
- Iniciativa, linha de visão, obstáculos, alcance e objetivos de batalha.
- Recompensas reais: ouro, Soul Éter, experiência, drops e desbloqueios.
- Um sistema único de progressão para fé, nomeação, almas e evolução.
- Kroug recrutável e evolutivo; depois Lira e Thal'kor.
- Construções da vila alterarem produção, fé, recrutamento ou novas regiões.
- Crafting com inventário, materiais, equipamentos e drops ligados aos inimigos.
- Eventos e diálogos conectados ao fluxo, com recompensas aplicadas.
- Salvamento automático e carregamento de itens, almas, progresso, mapas e eventos.
- Botão de finalizar turno, objetivos, pausa, opções e feedback de ação.

## P2 - Conteúdo de campanha

- Mapas autorais dos quatro atos.
- As quatro formas do protagonista com sprites e estatísticas funcionais.
- Quatro Apóstolos com linhas evolutivas completas.
- Cinco Cardeais com mecânicas diferentes.
- Aurius como chefe final em fases reais.
- Anões, elfos, humanos aliados, diplomacia, regiões, cercos e exércitos.
- Cenas entre batalhas, final, epílogo e decisões persistentes.

## UX, acessibilidade e lançamento

- Suporte a teclado e controle.
- Interface responsiva, fonte ajustável e contraste configurável.
- Modo daltônico e opções para reduzir flashes e tremores.
- Tooltips, preview de dano, alcance, iniciativa e objetivo.
- Testes de carregamento de cenas, combate, vitória, derrota, save e restart.
- Medição de performance antes de tentar 1.000 unidades.
- Configuração de exportação para as plataformas desejadas.

## Fontes analisadas

### Kenney - melhor encaixe imediato para 2D

Os assets 2D da Kenney são PNG, pequenos e fáceis de importar no Godot. A licença informada nos packs abaixo é Creative Commons CC0.

- [Tiny Battle](https://kenney.nl/assets/tiny-battle): 190 arquivos, pixel art, tile 16x16. Melhor para testar falanges, guerra e unidades.
- [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon): 130 arquivos, pixel art, tile 16x16. Melhor para minas, ruínas, prisões e dungeons.
- [Splat Pack](https://kenney.nl/assets/splat-pack): 30 VFX 2D. Serve para impactos, dano e sangue.
- [Sketch Desert](https://kenney.nl/assets/sketch-desert): 240 arquivos isométricos. Útil para conceito de wasteland, mas não é pixel art.
- [Pico-8 City](https://kenney.nl/assets/pico-8-city): 360 arquivos em 8x8. Bom para estudo, mas pequeno demais para a direção HD.

### Quaternius - opção 3D ou 2.5D

Quaternius oferece modelos 3D gratuitos em CC0. Alguns source packs incluem implementação para Godot, mas não são sprites 2D prontos.

- [Ultimate Monsters](https://quaternius.com/packs/ultimatemonsters.html): 50 monstros 3D animados.
- [Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html): mais de 300 peças modulares; a versão source inclui Godot, shaders e colisões.
- [Stylized Nature MegaKit](https://quaternius.com/packs/stylizednaturemegakit.html): 116 árvores, plantas, flores e pedras.
- [RPG Character Pack](https://quaternius.com/packs/rpgcharacters.html): 6 personagens 3D rigged e animados.
- [Ultimate RPG Pack](https://quaternius.com/packs/ultimaterpg.html): mais de 100 modelos RPG e renders PNG.

Use Quaternius somente se o projeto adotar 2.5D/3D ou se os modelos forem renderizados previamente como sprites PNG.

### KayKit / Kay Lousberg - opção 3D estilizada

KayKit também oferece modelos 3D low-poly em CC0, compatíveis com Godot. As versões gratuitas são suficientes para protótipo.

- [Dungeon Pack](https://kaylousberg.itch.io/kaykit-dungeon-pack): mais de 200 peças 3D de dungeon, com paredes, pisos, escadas, portas e props.
- [Forest Nature Pack](https://kaylousberg.itch.io/kaykit-forest): mais de 100 modelos gratuitos de árvores, pedras, arbustos e grama.
- [Adventurers](https://kaylousberg.itch.io/kaykit-adventurers): 5 personagens 3D com acessórios e animações.
- [Skeletons](https://kaylousberg.itch.io/kaykit-skeletons): 4 personagens esqueletos 3D com armas e animações.
- [Medieval Hexagon Pack](https://kaylousberg.itch.io/kaykit-medieval-hexagon): mais de 200 peças para mapas hexagonais e estratégia.

KayKit não deve ser misturado diretamente com pixel art 2D no mesmo mapa. Escolha entre pixel art 2D e 2.5D estilizado antes de produzir muito conteúdo.

## Decisão recomendada

### Caminho 2D

Continue com `Node2D` e `TileMapLayer`. Use Kenney para prototipagem, Emberfen como base 32x32, Volcanic Inferno para a Nação das Cinzas e um pack de VFX mágico. Produza os quatro Apóstolos, o protagonista e Aurius no mesmo estilo.

### Caminho 2.5D

Troque para `Node3D` com câmera ortográfica, iluminação e pipeline de renderização. Use KayKit e Quaternius para cenários e personagens, aceitando uma mudança importante em código, câmera, arte e identidade visual.

### Recomendação final

**Não trocaria o projeto para 3D agora.** O GDD, a referência Sea of Stars e a base atual apontam para 2D. Kenney ajuda diretamente no protótipo; Quaternius e KayKit ficam como referência ou plano futuro de 2.5D.

## Ordem de trabalho

1. Estabilizar sintaxe, introdução, grade, aliados e turnos.
2. Completar uma batalha da Fronteira Cinzenta.
3. Ligar vitória, recompensas, vila e salvamento.
4. Integrar nomeação, evolução, habilidades e crafting.
5. Adicionar conteúdo dos quatro atos, arte final, áudio e acessibilidade.

Nenhum arquivo de terceiros foi copiado para o projeto; este documento contém apenas referências e recomendações.

