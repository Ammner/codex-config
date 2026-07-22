param(
    [string]$InstallDir = (Join-Path $HOME "bin"),
    [string]$NimbalystUserData = (Join-Path $env:APPDATA "@nimbalyst\electron"),
    [switch]$SkipNimbalystConfig
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Source = Join-Path $RepoRoot "claude\nimbalyst-cc3p-launcher.cs"
$Target = Join-Path $InstallDir "nimbalyst-cc3p.exe"
$SecretFile = Join-Path $HOME ".hermes\secrets\third-party.env"

if (-not (Test-Path $SecretFile)) {
    throw "Missing CC 3P secret file: $SecretFile"
}
$secretNames = Get-Content $SecretFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=') { $Matches[1].Trim() }
}
if ($secretNames -notcontains "THIRD_PARTY_AUTH_TOKEN") {
    throw "THIRD_PARTY_AUTH_TOKEN is missing from $SecretFile"
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$tempTarget = "$Target.new"
if (Test-Path $tempTarget) { Remove-Item -LiteralPath $tempTarget -Force }
$Compiler = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Compiler) {
    throw "Windows .NET Framework C# compiler (csc.exe) was not found"
}
& $Compiler /nologo /target:exe /optimize+ "/out:$tempTarget" $Source
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tempTarget)) {
    throw "Failed to compile $Target"
}
if (Test-Path $Target) {
    Copy-Item $Target "$Target.bak" -Force
    Remove-Item -LiteralPath $Target -Force
}
Move-Item -LiteralPath $tempTarget -Destination $Target

Write-Host "Installed Nimbalyst CC 3P launcher: $Target"

if (-not $SkipNimbalystConfig) {
    $running = Get-Process Nimbalyst -ErrorAction SilentlyContinue
    if ($running) {
        throw "Nimbalyst is running. Close it, then rerun this installer to update its configuration safely."
    }

    $settingsPath = Join-Path $NimbalystUserData "ai-settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $settings | Add-Member -NotePropertyName customClaudeCodePath -NotePropertyValue $Target -Force
        if ($settings.apiKeys) {
            $settings.apiKeys.PSObject.Properties.Remove("claude-code")
        }
        foreach ($containerName in @("environmentVariables", "envVars")) {
            $container = $settings.$containerName
            if ($container) {
                foreach ($name in @("ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY")) {
                    $container.PSObject.Properties.Remove($name)
                }
            }
        }
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $settingsPath "$settingsPath.bak-$stamp" -Force
        $tempSettings = "$settingsPath.new"
        [System.IO.File]::WriteAllText(
            $tempSettings,
            (($settings | ConvertTo-Json -Depth 100) + "`n"),
            [System.Text.UTF8Encoding]::new($false)
        )
        Move-Item -LiteralPath $tempSettings -Destination $settingsPath -Force
        Write-Host "Configured Nimbalyst custom Claude path: $Target"
        Write-Host "Cleared the conflicting Claude API Key and stale copied 3P variables."
    } else {
        Write-Host "Nimbalyst settings were not found at $settingsPath"
        Write-Host "After installing Nimbalyst, set Custom Claude Installation to: $Target"
    }
}
