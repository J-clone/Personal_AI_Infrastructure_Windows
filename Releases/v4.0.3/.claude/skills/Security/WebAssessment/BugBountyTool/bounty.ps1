param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Args.Count -eq 0) { $Args = @('help') }
$cmd = $Args[0]
$rest = if($Args.Count -gt 1){ $Args[1..($Args.Count-1)] } else { @() }
switch($cmd){
  {$_ -in @('init','initialize')} { & bun run (Join-Path $ScriptDir 'src/init.ts'); break }
  'update' { & bun run (Join-Path $ScriptDir 'src/update.ts'); break }
  {$_ -in @('show','list')} { & bun run (Join-Path $ScriptDir 'src/show.ts') @rest; break }
  'search' { & bun run (Join-Path $ScriptDir 'src/show.ts') '--search' @rest; break }
  {$_ -in @('recon','initiate-recon')} { & bun run (Join-Path $ScriptDir 'src/recon.ts') @rest; break }
  default { Write-Host 'Usage: bounty.ps1 <init|update|show|search|recon>' }
}
