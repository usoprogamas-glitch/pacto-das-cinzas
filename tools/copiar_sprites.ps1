# =============================================================
# copiar_sprites.ps1 — "O Pacto das Cinzas"
# =============================================================
# Copia os conjuntos de sprites escolhidos do pacote extraído do
# Sea of Stars para o projeto Godot.
#
# USO (no PowerShell):
#   powershell -ExecutionPolicy Bypass -File copiar_sprites.ps1
#   powershell -ExecutionPolicy Bypass -File copiar_sprites.ps1 -Conjuntos "Zale,Valere"
#
# Re-executável a qualquer momento.
# =============================================================
param(
	[string]$Conjuntos = "FeralQueenValere,Zale,Valere"
)

$ORIGEM  = "D:\Games\Sea of Stars\assets_extraidos\sprites"
$DESTINO = "C:\Users\Administrator\Documents\Default Project\Pacto_das_Cinzas\assets\sprites"

# Conjuntos disponíveis: Nome => padrão regex de prefixo dos arquivos
$CONJUNTOS = [ordered]@{
	"FeralQueenValere" = "^FeralQueenValere_"
	"Zale"             = "^Zale_"
	"Valere"           = "^Valere_"
	"RetratosDLC"      = "^dialog-portrait-"
}

if (-not (Test-Path $ORIGEM)) {
	Write-Host "[erro] Origem nao encontrada: $ORIGEM" -ForegroundColor Red
	exit 1
}

$lista = $Conjuntos -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

foreach ($nome in $lista) {
	if (-not $CONJUNTOS.Contains($nome)) {
		Write-Host "[aviso] conjunto desconhecido: '$nome' (disponiveis: $($CONJUNTOS.Keys -join ', '))" -ForegroundColor Yellow
		continue
	}

	$padrao = $CONJUNTOS[$nome]
	$arquivos = Get-ChildItem -Path $ORIGEM -Filter *.png -File -ErrorAction SilentlyContinue |
		Where-Object { $_.Name -match $padrao }

	if (-not $arquivos -or $arquivos.Count -eq 0) {
		Write-Host "[aviso] nenhum arquivo encontrado para '$nome' (padrao: $padrao)" -ForegroundColor Yellow
		continue
	}

	$dest = Join-Path $DESTINO $nome
	New-Item -ItemType Directory -Force -Path $dest | Out-Null

	foreach ($a in $arquivos) {
		Copy-Item -Path $a.FullName -Destination (Join-Path $dest $a.Name) -Force
	}

	Write-Host "[ok] $nome -> $dest ($($arquivos.Count) arquivos)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Feito. Agora abra o Godot e execute tools/build_sprite_frames.gd (Ctrl+Shift+X)." -ForegroundColor Cyan
