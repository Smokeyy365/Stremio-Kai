# Installs Stremio Kai's mpv scripts into AIOStreams Desktop.
# Run from this folder:  powershell -ExecutionPolicy Bypass -File .\install.ps1 [-KaiDir C:\Stremio-Kai]
param(
    # An existing Stremio Kai folder, to copy its shaders and fonts. Without it, only Anime4K is downloaded.
    [string]$KaiDir,
    # mpv folder of a portable AIOStreams Desktop copy: <copy>\data\mpv
    [string]$MpvDir = (Join-Path $env:APPDATA 'AIOStreams Desktop\mpv')
)
$ErrorActionPreference = 'Stop'
$kai = Join-Path $PSScriptRoot '..\portable_config'
New-Item -ItemType Directory -Force "$MpvDir\scripts", "$MpvDir\script-opts", "$MpvDir\shaders" | Out-Null

# Keep what the user had before the first install.
foreach ($f in 'mpv.conf', 'input.conf') {
    if ((Test-Path "$MpvDir\$f") -and -not (Test-Path "$MpvDir\$f.pre-kai")) {
        Copy-Item "$MpvDir\$f" "$MpvDir\$f.pre-kai"
    }
}

# Kai writes its own log next to Stremio; the app keeps logs already.
Get-Content -Encoding UTF8 "$kai\mpv.conf" | Where-Object { $_ -notmatch '^log-file=' } | Set-Content -Encoding UTF8 "$MpvDir\mpv.conf"
# 'q quit' would shut down the app's player.
Get-Content -Encoding UTF8 "$kai\input.conf" | Where-Object { $_ -notmatch '^q\s+quit' } | Set-Content -Encoding UTF8 "$MpvDir\input.conf"

Copy-Item -Recurse -Force "$kai\scripts\notify_skip" "$MpvDir\scripts\"
Copy-Item -Force "$kai\scripts\profile-manager.lua", "$kai\scripts\reactive_vf_bypass.lua", "$kai\scripts\svp_cleanup.lua", "$PSScriptRoot\kai-bridge.lua" "$MpvDir\scripts\"
# The selector's remembered tracks live beside it; never overwrite them.
New-Item -ItemType Directory -Force "$MpvDir\scripts\smart-track-selector" | Out-Null
Copy-Item -Force "$kai\scripts\smart-track-selector\main.lua" "$MpvDir\scripts\smart-track-selector\"
if (-not (Test-Path "$MpvDir\scripts\smart-track-selector\track_preferences.json")) {
    Copy-Item "$kai\scripts\smart-track-selector\track_preferences.json" "$MpvDir\scripts\smart-track-selector\"
}
Copy-Item -Force "$kai\svp_anime.vpy", "$kai\svp_cinema.vpy" "$MpvDir\"

# Option files are the user's settings, so only add missing ones.
$opts = @("$kai\script-opts\notify_skip.conf", "$kai\script-opts\smart_track_selector.conf",
          "$kai\script-opts\stats.conf", "$kai\script-opts\svp.conf", "$PSScriptRoot\kai_bridge.conf")
foreach ($f in $opts) {
    $to = Join-Path "$MpvDir\script-opts" (Split-Path $f -Leaf)
    if (-not (Test-Path $to)) { Copy-Item $f $to }
}

if ($KaiDir) {
    foreach ($d in 'shaders', 'fonts') {
        if (Test-Path "$KaiDir\portable_config\$d") {
            Copy-Item -Recurse -Force "$KaiDir\portable_config\$d" "$MpvDir\"
        }
    }
} else {
    $zip = Join-Path $env:TEMP 'Anime4K_v4.0.zip'
    Invoke-WebRequest 'https://github.com/bloc97/Anime4K/releases/download/v4.0.1/Anime4K_v4.0.zip' -OutFile $zip
    Expand-Archive -Force $zip "$MpvDir\shaders"
    Remove-Item $zip
}

Write-Host "Installed into $MpvDir. Restart AIOStreams Desktop; settings are in script-opts\kai_bridge.conf."
