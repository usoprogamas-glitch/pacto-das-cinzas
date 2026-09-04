# =============================================================
# rodar_tudo.ps1 — "O Pacto das Cinzas"
# =============================================================
# Faz a integração completa em um comando:
#   1. Copia os sprites do pacote extraído para o projeto
#   2. Localiza o executável do Godot 4.3
#   3. Importa os recursos (headless)
#   4. Gera os SpriteFrames (.tres) das animações
#
# USO:
#   powershell -ExecutionPolicy Bypass -File rodar_tudo.ps1
#   powershell -ExecutionPolicy Bypass -File rodar_tudo.ps1 -Conjuntos "FeralQueenValere"
# =============================================================
param(
	[string]$Conjuntos = "FeralQueenValere,Zale,Valere",
	[string]$GodotExe = ""
)

$ErrorActionPreference = "Continue"
$PROJETO = "C:\Users\Administrator\Documents\Default Project\Pacto_das_Cinzas"
$TOOLS = Join-Path $PROJETO "tools"

Write-Host "=== O Pacto das Cinzas - Integracao de Assets ===" -ForegroundColor Cyan

# ---------- 1. COPIA ----------
Write-Host "`n[1/3] Copiando sprites..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File (Join-Path $TOOLS "copiar_sprites.ps1") -Conjuntos $Conjuntos
if ($LASTEXITCODE -ne 0) { Write-Host "[erro] falha na copia" -ForegroundColor Red; exit 1 }

# ---------- 2. LOCALIZAR GODOT ----------
Write-Host "`n[2/3] Localizando Godot..." -ForegroundColor Yellow
$godot = $null
if ($GodotExe -ne "" -and (Test-Path $GodotExe)) {
	$godot = $GodotExe
} else {
	$candidatos = @()
	# pasta conhecida
	$pastaGodot = Join-Path $env:USERPROFILE "Downloads\Godot43"
	if (Test-Path $pastaGodot) {
		$candidatos += Get-ChildItem $pastaGodot -Filter *.exe -Recurse -Depth 1 -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -notmatch "console|server" } |
			Select-Object -ExpandProperty FullName
	}
	# no PATH
	$cmd = Get-Command godot -ErrorAction SilentlyContinue
	if ($cmd) { $candidatos += $cmd.Source }
	# locais comuns
	foreach ($p in @("$env:LOCALAPPDATA\Programs\Godot", "C:\Program Files\Godot", "D:\Godot")) {
		if (Test-Path $p) {
			$candidatos += Get-ChildItem $p -Filter *.exe -Recurse -Depth 1 -ErrorAction SilentlyContinue |
				Where-Object { $_.Name -notmatch "console|server" } |
				Select-Object -ExpandProperty FullName
		}
	}
	# prioriza 4.x
	$godot = $candidatos | Where-Object { $_ -match "4\." } | Select-Object -First 1
	if (-not $godot) { $godot = $candidatos | Select-Object -First 1 }
}

if (-not $godot -or -not (Test-Path $godot)) {
	Write-Host "[erro] Godot nao encontrado." -ForegroundColor Red
	Write-Host "Rode de novo informando o caminho:" -ForegroundColor Yellow
	Write-Host '  powershell -ExecutionPolicy Bypass -File rodar_tudo.ps1 -GodotExe "C:\caminho\Godot_v4.3-stable_win64.exe"' -ForegroundColor Yellow
	exit 1
}
Write-Host "Godot: $godot" -ForegroundColor Gray

# ---------- 3. IMPORTAR + GERAR ----------
Write-Host "`n[3/3] Importando recursos e gerando animacoes (pode levar alguns minutos)..." -ForegroundColor Yellow
& $godot --path $PROJETO --headless --import 2>&1 | Out-Null
Write-Host "Import concluido." -ForegroundColor Gray
& $godot --path $PROJETO --headless --script "res://tools/build_sprite_frames_headless.gd"

Write-Host "`n=== Pronto! ===" -ForegroundColor Cyan
Write-Host "Anims em: res://assets/animations/  |  Uso: `$Sprite2D.play(`"walk_d3`")" -ForegroundColor Green
