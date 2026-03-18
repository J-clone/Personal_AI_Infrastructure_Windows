try { Invoke-RestMethod -Uri 'http://localhost:8888/health' -TimeoutSec 2 | Out-Null; Write-Output '🎙️ Voice Server Running' } catch { Write-Output '🎙️⚫ Voice Server Stopped' }
