$taskName='PAI-VoiceServer'
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
  Write-Host 'Removed scheduled task.' -ForegroundColor Green
}
$pids = netstat -ano | Select-String ':8888' | Select-String 'LISTENING' | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
foreach($pid in $pids){ try { Stop-Process -Id $pid -Force -ErrorAction Stop } catch {} }
