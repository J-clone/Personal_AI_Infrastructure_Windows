$paiDir = if($env:PAI_DIR){$env:PAI_DIR}else{"$env:USERPROFILE\\.claude"}
$settings = Join-Path $paiDir 'settings.json'
$inputJson = [Console]::In.ReadToEnd()
try { $payload = $inputJson | ConvertFrom-Json } catch { $payload = $null }
$ai = 'Assistant'; $ver='-'
if(Test-Path $settings){
  try { $s = Get-Content $settings -Raw | ConvertFrom-Json; if($s.daidentity.name){$ai=$s.daidentity.name}; if($s.pai.version){$ver=$s.pai.version} } catch {}
}
$model = if($payload -and $payload.model.display_name){$payload.model.display_name}else{'unknown'}
$ctx = if($payload -and $payload.context_window.used_percentage -ne $null){[int]$payload.context_window.used_percentage}else{0}
Write-Output ("$ai | PAI v$ver | model:$model | ctx:${ctx}%")
