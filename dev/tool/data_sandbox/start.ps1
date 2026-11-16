param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string[]]$Datasets = @('backup', 'current'),
  [switch]$Dump,
  [switch]$Direct,
  [string]$Lab
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Lab) { $Lab = Join-Path $here '..\..\build\data_lab' }
$Lab = (Resolve-Path $Lab).Path
foreach ($need in 'tauri', 'dist', 'datasets') {
  if (-not (Test-Path (Join-Path $Lab $need))) { throw "missing $Lab\$need" }
}
Copy-Item (Join-Path $here 'run.ps1') (Join-Path $Lab 'run.ps1') -Force
Copy-Item (Join-Path $here 'UiaCom.cs') (Join-Path $Lab 'UiaCom.cs') -Force
$actions = Join-Path $here 'actions.ps1'
if (Test-Path $actions) { Copy-Item $actions (Join-Path $Lab 'actions.ps1') -Force } else { Remove-Item (Join-Path $Lab 'actions.ps1') -ErrorAction SilentlyContinue }
@{ version = $Version; datasets = $Datasets; dump = [bool]$Dump; mode = $(if ($Direct) { 'direct' } else { 'upgrade' }) } | ConvertTo-Json | Set-Content (Join-Path $Lab 'sandbox.json')
Remove-Item (Join-Path $Lab 'results') -Recurse -Force -ErrorAction SilentlyContinue

$wsb = @"
<Configuration>
  <MemoryInMB>8192</MemoryInMB>
  <MappedFolders>
    <MappedFolder>
      <HostFolder>$Lab</HostFolder>
      <SandboxFolder>C:\lab</SandboxFolder>
      <ReadOnly>false</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <Command>cmd /c "powershell -NoProfile -ExecutionPolicy Bypass -File C:\lab\run.ps1 &gt; C:\lab\transcript.txt 2&gt;&amp;1 &amp; shutdown /s /t 5"</Command>
  </LogonCommand>
</Configuration>
"@
$config = Join-Path $Lab 'data.wsb'
Set-Content $config $wsb
Start-Process (Join-Path $env:SystemRoot 'System32\WindowsSandbox.exe') -ArgumentList "`"$config`""
Write-Host "Windows Sandbox started; results land in $Lab\results"
