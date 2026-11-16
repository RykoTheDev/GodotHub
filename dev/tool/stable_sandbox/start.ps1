param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$Lab
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Lab) { $Lab = Join-Path $here '..\..\build\stable_lab' }
$Lab = (Resolve-Path $Lab).Path
foreach ($need in 'tauri', 'dist') {
  if (-not (Test-Path (Join-Path $Lab $need))) { throw "missing $Lab\$need" }
}
Copy-Item (Join-Path $here 'run.ps1') (Join-Path $Lab 'run.ps1') -Force
@{ version = $Version } | ConvertTo-Json | Set-Content (Join-Path $Lab 'sandbox.json')
Remove-Item (Join-Path $Lab 'results') -Recurse -Force -ErrorAction SilentlyContinue

$wsb = @"
<Configuration>
  <Networking>Disable</Networking>
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
$config = Join-Path $Lab 'stable.wsb'
Set-Content $config $wsb
Start-Process (Join-Path $env:SystemRoot 'System32\WindowsSandbox.exe') -ArgumentList "`"$config`""
Write-Host "Windows Sandbox started; results land in $Lab\results"
