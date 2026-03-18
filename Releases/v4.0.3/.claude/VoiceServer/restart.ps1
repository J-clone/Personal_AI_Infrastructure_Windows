$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir 'stop.ps1')
Start-Sleep -Seconds 1
& (Join-Path $ScriptDir 'start.ps1')
