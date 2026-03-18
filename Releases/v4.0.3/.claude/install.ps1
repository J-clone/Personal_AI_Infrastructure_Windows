$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "  ℹ $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  ✓ $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  ⚠ $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "  ✗ $m" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallerDir = Join-Path $ScriptDir 'PAI-Install'
if (-not (Test-Path $InstallerDir)) { $InstallerDir = $ScriptDir }

$bun = Get-Command bun -ErrorAction SilentlyContinue
if (-not $bun) {
  Info 'Installing Bun runtime...'
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm bun.sh/install.ps1|iex"
  $env:PATH = "$env:USERPROFILE\\.bun\\bin;$env:PATH"
}

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
  Fail 'Bun was not found after install. Install from https://bun.sh and rerun.'
  exit 1
}
Ok "Bun found: $(bun --version)"

$mode = if ($env:CI -eq 'true' -or $env:SSH_CONNECTION) { 'cli' } else { 'gui' }
Info "Launching installer in $mode mode..."
& bun run (Join-Path $InstallerDir 'main.ts') --mode $mode
