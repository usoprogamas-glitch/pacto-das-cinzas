# Integração de Assets — O Pacto das Cinzas

Assets extraídos do Sea of Stars (uso **pessoal/estudo** — não distribuir).

## 📁 O que já está configurado

| Item | Status |
|---|---|
| `project.godot` | `default_texture_filter = Nearest` (pixel art nítido) ✅ |
| `tools/copiar_sprites.ps1` | Copia conjuntos de sprites do pacote pra `res://assets/sprites/` |
| `tools/build_sprite_frames.gd` | Gera `SpriteFrames` (.tres) automaticamente → `res://assets/animations/` |

## 🚀 Passo a passo

### 1. Copiar sprites escolhidos
No PowerShell:
```powershell
cd "C:\Users\Administrator\Documents\Default Project\Pacto_das_Cinzas\tools"
powershell -ExecutionPolicy Bypass -File copiar_sprites.ps1
# ou conjuntos específicos:
powershell -ExecutionPolicy Bypass -File copiar_sprites.ps1 -Conjuntos "Zale,Valere"
```

### 2. Gerar as animações
1. Abra o projeto no Godot 4.3
2. Abra `tools/build_sprite_frames.gd` no editor de scripts
3. **Arquivo → Executar** (Ctrl+Shift+X)
4. Saída: `assets/animations/<Personagem>.tres` (SpriteFrames com anims `acao_direcao`, ex: `walk_d3`)

### 3. Usar no jogo
```gdscript
var frames := load("res://animations/FeralQueenValere.tres")
$Sprite2D.sprite_frames = frames
$Sprite2D.play("walk_d3")
```

## 🔍 Como achar mais assets
Abra `D:\Games\Sea of Stars\assets_extraidos\indice_assets.csv` (Excel) e filtre
a coluna *nome*. Depois adicione o padrão no dicionário `$CONJUNTOS` do
`copiar_sprites.ps1` e rode de novo.

## ⚠️ Regras
- Uso pessoal/estudo apenas — não publique/distribua o jogo com esses assets.
- Os sprites seguem `Personagem_Acao_Direção_Frame` (ex: `_Walk_D3_F05`).
