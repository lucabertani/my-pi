# =====================================================================
#  install.ps1 - Verifica l'ultima release di pi in questa repository
#  e la installa (o aggiorna) automaticamente su Windows.
#
#  Uso:  .\install.ps1
# =====================================================================

# =====================================================================
#  CONFIGURAZIONE - modifica questi valori
# =====================================================================
$RepoOwner  = "lucabertani"                  # owner della repository GitHub
$RepoName   = "my-pi"                        # repository con le release di pi
$InstallDir = "$env:LOCALAPPDATA\Programs\pi"  # dove installare pi (es. "C:\pi")
$Token      = ""                             # opzionale: token GitHub per evitare rate limit
# =====================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

$ApiUrl      = "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases/latest"
$VersionFile = Join-Path $InstallDir "pi-version.txt"

# --- Se pi e' in esecuzione, chiudilo prima di aggiornare
if (Get-Process -Name "pi" -ErrorAction SilentlyContinue) {
    throw "pi.exe e' in esecuzione: chiudilo e riprova."
}

# --- Ultima release disponibile
Write-Host "Controllo ultime release su $RepoOwner/$RepoName ..."
$headers = @{ "User-Agent" = "pi-installer" }
if ($Token) { $headers["Authorization"] = "Bearer $Token" }
$latest    = Invoke-RestMethod -Uri $ApiUrl -Headers $headers
$latestTag = $latest.tag_name

$installed = if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { "" }

Write-Host "Ultima release : $latestTag"
Write-Host "Versione installata : $(if ($installed) { $installed } else { 'nessuna' })"

if ($installed -eq $latestTag) {
    Write-Host "pi $latestTag e' gia' installata: niente da fare." -ForegroundColor Green
    exit 0
}

# --- Trova l'asset Windows nella release
$asset = $latest.assets | Where-Object { $_.name -like "pi-windows-*.zip" } | Select-Object -First 1
if (-not $asset) { throw "Nessun asset pi-windows-*.zip trovato nella release $latestTag" }

# --- Download
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
$tempZip = Join-Path $env:TEMP "pi-$latestTag.zip"
Write-Host "Download di $($asset.name) ..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -UseBasicParsing

# --- Installazione (pulisco i file della versione precedente)
Write-Host "Installazione in $InstallDir ..."
Get-ChildItem -Path $InstallDir -Force | Remove-Item -Recurse -Force
Expand-Archive -LiteralPath $tempZip -DestinationPath $InstallDir -Force
Remove-Item $tempZip -Force

$latestTag | Set-Content -Path $VersionFile -Encoding ascii

# --- Verifica che l'eseguibile parta
$piExe = Join-Path $InstallDir "pi.exe"
if (-not (Test-Path $piExe)) { throw "pi.exe non trovato in $InstallDir dopo l'estrazione" }
& $piExe --version

Write-Host ""
Write-Host "OK: pi $latestTag installata in $InstallDir" -ForegroundColor Green
Write-Host "Per usare pi da qualsiasi cartella:  $piExe" -ForegroundColor Yellow
