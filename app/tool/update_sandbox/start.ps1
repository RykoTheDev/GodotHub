param([string]$Lab)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Lab) { $Lab = Join-Path $here '..\..\build\update_lab' }
$Lab = (Resolve-Path $Lab).Path
foreach ($need in 'dist\1.9.0', 'dist\1.9.1', 'dist\1.9.2', 'manifests', 'tauri', 'backup') {
  if (-not (Test-Path (Join-Path $Lab $need))) { throw "missing $Lab\$need; run prepare.sh first" }
}
Copy-Item (Join-Path $here 'run.ps1'), (Join-Path $here 'server.ps1') $Lab -Force
Copy-Item (Join-Path $here '..\data_sandbox\UiaCom.cs') $Lab -Force
Remove-Item (Join-Path $Lab 'results'), (Join-Path $Lab 'serve') -Recurse -Force -ErrorAction SilentlyContinue

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
$config = Join-Path $Lab 'update.wsb'
Set-Content $config $wsb
Start-Process (Join-Path $env:SystemRoot 'System32\WindowsSandbox.exe') -ArgumentList "`"$config`""
Write-Host "Windows Sandbox started; results land in $Lab\results"
