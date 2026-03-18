$pids = netstat -ano | Select-String ':8888' | Select-String 'LISTENING' | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
foreach($pid in $pids){ try { Stop-Process -Id $pid -Force -ErrorAction Stop } catch {} }
Write-Host 'Voice server stop requested.' -ForegroundColor Yellow
