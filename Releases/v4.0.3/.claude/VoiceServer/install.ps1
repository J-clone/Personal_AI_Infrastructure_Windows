$ErrorActionPreference='Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { Write-Error 'bun is required'; exit 1 }
Write-Host 'Installing VoiceServer for Windows (startup task)...' -ForegroundColor Cyan
$taskName='PAI-VoiceServer'
$action = New-ScheduledTaskAction -Execute 'bun' -Argument "run `"$(Join-Path $ScriptDir 'server.ts')`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description 'PAI Voice Server' -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host 'Installed scheduled task PAI-VoiceServer.' -ForegroundColor Green
