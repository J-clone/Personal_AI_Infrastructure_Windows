$health = $false
try { $resp = Invoke-RestMethod -Uri 'http://localhost:8888/health' -TimeoutSec 2; $health = $true } catch {}
if($health){ Write-Host 'Voice server: running' -ForegroundColor Green; $resp | ConvertTo-Json -Compress }
else { Write-Host 'Voice server: stopped' -ForegroundColor Yellow }
