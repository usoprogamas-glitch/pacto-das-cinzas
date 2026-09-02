$ErrorActionPreference = 'SilentlyContinue'
# Encontrar ComfyUI root navegando pelo PID ativo
$pid_ = 30644
$proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
if ($proc) {
    $base = Split-Path $proc.Path
    Write-Host "PROC_PATH: $($proc.Path)"
    Write-Host "PROC_DIR:  $base"
}
# Procurar background_removal e/ou models dir
$cands = @(
    "C:\Users\Administrator\ComfyUI",
    "C:\Users\Administrator\AppData\Roaming\Comfy Desktop\ComfyUI",
    "C:\Users\Administrator\AppData\Local\Programs\Comfy Desktop\ComfyUI",
    "C:\Users\Administrator\AppData\Local\Programs\Comfy Desktop\resources\app\ComfyUI"
)
foreach ($c in $cands) {
    if (Test-Path $c) { Write-Host "EXISTE: $c" }
}
# Grep pela pasta models/background_removal
Get-ChildItem -Path 'C:\Users\Administrator\AppData\Local\Programs\Comfy Desktop' -Recurse -Filter 'background_removal' -Directory -Depth 8 -ErrorAction SilentlyContinue | % { Write-Host "BG_DIR: $($_.FullName)" }
Get-ChildItem -Path 'C:\Users\Administrator\AppData\Roaming\Comfy Desktop' -Recurse -Filter 'background_removal' -Directory -Depth 8 -ErrorAction SilentlyContinue | % { Write-Host "BG_DIR: $($_.FullName)" }
Write-Host "DONE"
