param(
    [string]$CodexHome = "",
    [string]$CodexWorkRoot = "D:\Codex",
    [string]$HermesWorkRoot = "D:\Hermes",
    [switch]$ForceConfig
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if ($env:CODEX_HOME) {
        $CodexHome = $env:CODEX_HOME
    } elseif (Test-Path "D:\Codex\.codex") {
        $CodexHome = "D:\Codex\.codex"
    } else {
        $CodexHome = Join-Path $HOME ".codex"
    }
}

$HermesHome = Join-Path $HermesWorkRoot ".hermes"
$GraphitiHome = Join-Path $HermesWorkRoot ".graphiti"

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HermesWorkRoot "tmp") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HermesWorkRoot "logs\playwright") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HermesWorkRoot "browser-profiles\chrome-devtools") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HermesWorkRoot "browser-profiles\playwright") | Out-Null

[Environment]::SetEnvironmentVariable("CODEX_HOME", $CodexHome, "User")
[Environment]::SetEnvironmentVariable("HERMES_WORK_ROOT", $HermesWorkRoot, "User")
[Environment]::SetEnvironmentVariable("HERMES_HOME", $HermesHome, "User")
[Environment]::SetEnvironmentVariable("GRAPHITI_HOME", $GraphitiHome, "User")
[Environment]::SetEnvironmentVariable("NPM_CONFIG_CACHE", (Join-Path $HermesWorkRoot "npm-cache"), "User")
[Environment]::SetEnvironmentVariable("PIP_CACHE_DIR", (Join-Path $HermesWorkRoot "pip-cache"), "User")
[Environment]::SetEnvironmentVariable("UV_CACHE_DIR", (Join-Path $HermesWorkRoot "uv-cache"), "User")

$env:CODEX_HOME = $CodexHome
$env:HERMES_WORK_ROOT = $HermesWorkRoot
$env:HERMES_HOME = $HermesHome
$env:GRAPHITI_HOME = $GraphitiHome

$AgentsSource = Join-Path $RepoRoot "AGENTS.md"
$AgentsTarget = Join-Path $CodexHome "AGENTS.md"
if (Test-Path $AgentsTarget) {
    Copy-Item $AgentsTarget "$AgentsTarget.bak" -Force
}
Copy-Item $AgentsSource $AgentsTarget -Force

$Common = Get-Content (Join-Path $RepoRoot "codex\config.common.toml") -Raw
$Overlay = Get-Content (Join-Path $RepoRoot "codex\config.windows.toml") -Raw

$HermesWorkRootFwd = $HermesWorkRoot -replace "\\", "/"
$Overlay = $Overlay.Replace("{{CODEX_WORK_ROOT}}", ($CodexWorkRoot.ToLowerInvariant()))
$Overlay = $Overlay.Replace("{{HERMES_WORK_ROOT}}", ($HermesWorkRoot.ToLowerInvariant()))
$Overlay = $Overlay.Replace("{{HERMES_WORK_ROOT_FWD}}", $HermesWorkRootFwd)

$Generated = ($Common.TrimEnd() + "`n`n" + $Overlay.TrimStart())
$GeneratedPath = Join-Path $CodexHome "config.sync.generated.toml"
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($GeneratedPath, $Generated, $Utf8NoBom)

$ConfigPath = Join-Path $CodexHome "config.toml"
if ((-not (Test-Path $ConfigPath)) -or $ForceConfig) {
    if (Test-Path $ConfigPath) {
        $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $ConfigPath "$ConfigPath.bak-$Stamp" -Force
    }
    Copy-Item $GeneratedPath $ConfigPath -Force
    Write-Host "Wrote active Codex config: $ConfigPath"
} else {
    Write-Host "Left active Codex config unchanged: $ConfigPath"
    Write-Host "Generated synced template: $GeneratedPath"
}

Write-Host "Copied AGENTS.md to: $AgentsTarget"
Write-Host "Set user env: CODEX_HOME=$CodexHome"
Write-Host "Set user env: HERMES_HOME=$HermesHome"
