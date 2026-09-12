param(
    [ValidateSet('desktop', 'mcp')][string]$Component = 'desktop',
    [string]$Version = '',
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'adbtool\bin')
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Repo = 'RemLiquit/adbtool-release'
$Architecture = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
if ($Architecture -ne 'AMD64') { throw 'The published Windows build requires x64 Windows.' }
if (-not $Version) { $Version = (Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest").tag_name }
if ($Version -notmatch '^v\d+\.\d+\.\d+$') { throw 'Expected a stable release version such as v0.1.0.' }
$Asset = if ($Component -eq 'mcp') { 'adbtool-mcp-x86_64-pc-windows-msvc.zip' } else { 'adbtool-windows-x64-setup.exe' }
$Work = Join-Path ([IO.Path]::GetTempPath()) ('adbtool-install-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Work | Out-Null
try {
    $Base = "https://github.com/$Repo/releases/download/$Version"
    $Download = Join-Path $Work $Asset
    Write-Host "Downloading $Component $Version for Windows x64..."
    Invoke-WebRequest -UseBasicParsing "$Base/$Asset" -OutFile $Download
    $SumsPath = Join-Path $Work 'SHA256SUMS'
    Invoke-WebRequest -UseBasicParsing "$Base/SHA256SUMS" -OutFile $SumsPath
    $Sums = Get-Content -LiteralPath $SumsPath -Raw -Encoding UTF8
    $MatchesFound = @($Sums -split '\r?\n' | Where-Object { $_ -match ('^[a-f0-9]{64}  ' + [regex]::Escape($Asset) + '$') })
    if ($MatchesFound.Count -ne 1) { throw 'Missing or ambiguous checksum.' }
    $Expected = $MatchesFound[0].Substring(0, 64)
    if ((Get-FileHash $Download -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Expected) { throw 'Checksum verification failed.' }
    if ($Component -eq 'mcp') {
        if (Get-Process -Name adbtool-mcp -ErrorAction SilentlyContinue) { throw 'Stop the MCP server before replacing its executable.' }
        Expand-Archive -LiteralPath $Download -DestinationPath (Join-Path $Work 'unpacked')
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        Copy-Item (Join-Path $Work 'unpacked\adbtool-mcp.exe') (Join-Path $InstallDir 'adbtool-mcp.exe') -Force
        Write-Host "Installed: $(Join-Path $InstallDir 'adbtool-mcp.exe')"
        Write-Host 'Use this absolute path as your MCP client command and restart the session after upgrades.'
    } else {
        if (Get-Process -Name adbtool -ErrorAction SilentlyContinue) { throw 'Quit adbtool before installing so recordings can finish.' }
        $Installer = Start-Process -FilePath $Download -Wait -PassThru
        if ($Installer.ExitCode -ne 0) { throw "Installer exited with code $($Installer.ExitCode)." }
    }
    Write-Host 'Runtime dependencies: adb; scrcpy 3.x with its matching server for media and screen power.'
} finally {
    Remove-Item -LiteralPath $Work -Recurse -Force
}
