$ErrorActionPreference='Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$server = Join-Path $ScriptDir 'server.ts'
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { Write-Error 'bun is required'; exit 1 }
Start-Process -FilePath bun -ArgumentList @('run',$server) -WorkingDirectory $ScriptDir -WindowStyle Hidden
Start-Sleep -Seconds 2
Write-Host 'Voice server start requested on http://localhost:8888' -ForegroundColor Green
