param(
    [string]$GitHubUser = "Ammner",
    [string]$TestRepoUrl = "https://github.com/Ammner/Github-.git",
    [string]$StatusPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($StatusPath)) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    $StatusPath = Join-Path $RepoRoot "tmp\github-auth-test.status"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $StatusPath) | Out-Null
Set-Content -Path $StatusPath -Value "RUNNING" -Encoding ASCII

trap {
    Set-Content -Path $StatusPath -Value ("FAIL " + $_.Exception.Message) -Encoding UTF8
    break
}

Write-Host "This will store a GitHub PAT in Windows Git Credential Manager."
Write-Host "Enter the PAT in the password field. It will not be printed."
Write-Host ""

$inputUser = Read-Host "GitHub username [$GitHubUser]"
if (-not [string]::IsNullOrWhiteSpace($inputUser)) {
    $GitHubUser = $inputUser
}
$securePat = Read-Host "GitHub PAT (input hidden)" -AsSecureString

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePat)
try {
    $pat = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    if ([string]::IsNullOrWhiteSpace($pat)) {
        throw "PAT was empty."
    }

    "protocol=https`nhost=github.com`n`n" | git credential reject | Out-Null

    $approval = "protocol=https`nhost=github.com`nusername=$GitHubUser`npassword=$pat`n`n"
    $approval | git credential approve | Out-Null
} finally {
    if ($bstr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    $pat = $null
    $approval = $null
}

Write-Host "Stored credential. Testing read access:"
git ls-remote $TestRepoUrl HEAD

Write-Host ""
Write-Host "GitHub credential test completed."
Set-Content -Path $StatusPath -Value ("OK " + (Get-Date).ToString("s")) -Encoding ASCII
