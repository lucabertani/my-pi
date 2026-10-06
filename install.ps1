# =====================================================================
#  install.ps1 - Checks the latest pi release in this repository and
#  installs (or updates) it automatically on Windows.
#
#  Usage:  .\install.ps1
# =====================================================================

# =====================================================================
#  CONFIGURATION - edit these values
# =====================================================================
$RepoOwner  = "lucabertani"                     # GitHub repository owner
$RepoName   = "my-pi"                           # repository holding the pi releases
$InstallDir = "$env:LOCALAPPDATA\Programs\pi"   # where to install pi (e.g. "C:\pi")
$Token      = ""                                # optional: GitHub token to avoid rate limits
# =====================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

$ApiUrl      = "https://api.github.com/repos/${RepoOwner}/${RepoName}/releases/latest"
$VersionFile = Join-Path $InstallDir "pi-version.txt"

# --- If pi is running, close it before updating
if (Get-Process -Name "pi" -ErrorAction SilentlyContinue) {
    throw "pi.exe is running: close it and try again."
}

# --- Latest available release
Write-Host "Checking latest releases on $RepoOwner/$RepoName ..."
$headers = @{ "User-Agent" = "pi-installer" }
if ($Token) { $headers["Authorization"] = "Bearer $Token" }
$latest    = Invoke-RestMethod -Uri $ApiUrl -Headers $headers
$latestTag = $latest.tag_name

$installed = if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { "" }

Write-Host "Latest release    : $latestTag"
Write-Host "Installed version : $(if ($installed) { $installed } else { 'none' })"

if ($installed -eq $latestTag) {
    Write-Host "pi $latestTag is already installed: nothing to do." -ForegroundColor Green
    exit 0
}

# --- Find the Windows asset in the release
$asset = $latest.assets | Where-Object { $_.name -like "pi-windows-*.zip" } | Select-Object -First 1
if (-not $asset) { throw "No pi-windows-*.zip asset found in release $latestTag" }

# --- Download
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
$tempZip = Join-Path $env:TEMP "pi-$latestTag.zip"
Write-Host "Downloading $($asset.name) ..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -UseBasicParsing

# --- Install (removes files from the previous version first)
Write-Host "Installing to $InstallDir ..."
Get-ChildItem -Path $InstallDir -Force | Remove-Item -Recurse -Force
Expand-Archive -LiteralPath $tempZip -DestinationPath $InstallDir -Force
Remove-Item $tempZip -Force

$latestTag | Set-Content -Path $VersionFile -Encoding ascii

# --- Verify the executable starts
$piExe = Join-Path $InstallDir "pi.exe"
if (-not (Test-Path $piExe)) { throw "pi.exe not found in $InstallDir after extraction" }
& $piExe --version

Write-Host ""
Write-Host "OK: pi $latestTag installed in $InstallDir" -ForegroundColor Green
Write-Host "To use pi from anywhere:  $piExe" -ForegroundColor Yellow
