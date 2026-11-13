param([string]$Lab = 'C:\lab')

$ErrorActionPreference = 'Continue'
$results = Join-Path $Lab 'results'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$log = Join-Path $results 'checks.txt'
Set-Content $log ''
$script:failures = 0
function Note([string]$text) { Add-Content $log $text; Write-Host $text }
function Check([bool]$ok, [string]$what) {
  if ($ok) { Note "ok   $what" } else { Note "FAIL $what"; $script:failures++ }
}

$config = Get-Content (Join-Path $Lab 'sandbox.json') -Raw | ConvertFrom-Json
$version = $config.version
$tauri = Join-Path $Lab 'tauri'
$dist = Join-Path $Lab 'dist'
$setup = Join-Path $dist "GodotHub-$version-windows-x64-setup.exe"
$msi = Join-Path $dist "GodotHub-$version-windows-x64.msi"
$portable = Join-Path $dist "GodotHub-$version-windows-x64-portable.zip"
$tauriSetup = Get-ChildItem $tauri -Filter 'GodotHub-*-windows-x64-setup.exe' | Select-Object -First 1
$tauriMsi = Get-ChildItem $tauri -Filter 'GodotHub-*-windows-x64.msi' | Select-Object -First 1
$installDir = Join-Path $env:LOCALAPPDATA 'GodotHub'
$data = Join-Path $env:APPDATA 'Ryko.GodotHub'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GodotHub'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$desktop = [Environment]::GetFolderPath('Desktop')

function Snapshot([string]$path) {
  if (-not (Test-Path $path)) { return '<absent>' }
  (Get-ChildItem $path -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\(logs?|cache|EBWebView)\\' } |
    ForEach-Object { '{0}|{1}' -f $_.FullName.Substring($path.Length), (Get-FileHash $_.FullName -Algorithm SHA256).Hash } |
    Sort-Object) -join "`n"
}

function Aumid([string]$folder, [string]$name) {
  $shell = New-Object -ComObject Shell.Application
  $item = $shell.NameSpace($folder).ParseName($name)
  if ($null -eq $item) { return '<missing>' }
  "$($item.ExtendedProperty('System.AppUserModel.ID'))"
}

function LinkTarget([string]$path) {
  if (-not (Test-Path $path)) { return '<missing>' }
  (New-Object -ComObject WScript.Shell).CreateShortcut($path).TargetPath
}

function StopApp { Get-Process godothub -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }

function WaitForWindow([string]$exe, [int]$seconds = 40) {
  $proc = Start-Process -FilePath $exe -PassThru
  for ($i = 0; $i -lt $seconds; $i++) {
    Start-Sleep 1
    $win = Get-Process godothub -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like 'GodotHub*' }
    if ($win) { return $true }
    if ($proc.HasExited -and -not (Get-Process godothub -ErrorAction SilentlyContinue)) { Note "     exited with $($proc.ExitCode)"; return $false }
  }
  return $false
}

Note "Flutter stable $version, Tauri $($tauriSetup.Name)"

Note "`n== Portable zip"
$portableDir = Join-Path $env:TEMP 'portable\GodotHub'
Expand-Archive $portable -DestinationPath $portableDir -Force
Check (Test-Path (Join-Path $portableDir 'godothub.exe')) 'godothub.exe at the top level of the portable zip'
Check (-not (Test-Path (Join-Path $portableDir 'launcher.json'))) 'portable zip has no launcher layout'
foreach ($dll in 'vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll') {
  Check (Test-Path (Join-Path $portableDir $dll)) "portable zip ships $dll"
}
$out = (& (Join-Path $portableDir 'godothub.exe') --version | Out-String).Trim()
Check ($out -eq "godothub $version") "portable binary answers --version ($out)"

Note "`n== Tauri NSIS install, then the Flutter setup as the Tauri updater runs it"
$p = Start-Process $tauriSetup.FullName -ArgumentList '/S' -PassThru -Wait
Check ($p.ExitCode -eq 0) "Tauri setup exits 0 (got $($p.ExitCode))"
Check (Test-Path (Join-Path $installDir 'godothub.exe')) 'Tauri installed godothub.exe'
$tauriStarted = WaitForWindow (Join-Path $installDir 'godothub.exe')
Check $tauriStarted 'Tauri app opens a window'
StopApp
New-Item -ItemType Directory -Force -Path $data | Out-Null
Set-Content (Join-Path $data 'sandbox-marker.txt') 'kept across the upgrade'
$dataBefore = Snapshot $data
Note "     data files before: $(((Get-ChildItem $data -Recurse -File).Count))"

$p = Start-Process $setup -ArgumentList '/P', '/R', '/UPDATE', '/ARGS' -PassThru
$p.WaitForExit()
Check ($p.ExitCode -eq 0) "Flutter setup exits 0 (got $($p.ExitCode))"
Start-Sleep 8
StopApp
$state = Get-Content (Join-Path $installDir 'launcher.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
Check ($state.current -eq $version) "launcher.json starts $version"
Check (Test-Path (Join-Path $installDir "app-$version\godothub.exe")) "app installed into app-$version"
Check ((Get-Item (Join-Path $installDir 'godothub.exe')).Length -lt 2MB) 'godothub.exe is now the launcher'
Check ((Get-ChildItem $installDir -File | Where-Object { $_.Extension -eq '.dll' }).Count -eq 0) 'no loose DLLs left at the top level'
foreach ($dll in 'vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll') {
  Check (Test-Path (Join-Path $installDir "app-$version\$dll")) "app folder ships $dll"
}
$entry = Get-ItemProperty $uninstallKey -ErrorAction SilentlyContinue
Check ($entry.DisplayVersion -eq $version) "uninstall entry GodotHub is $version (got $($entry.DisplayVersion))"
Check ($entry.Publisher -eq 'GodotHub') "publisher stays GodotHub (got $($entry.Publisher))"
Check ($entry.DisplayName -eq 'GodotHub') 'display name stays GodotHub'
$entries = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.GetValue('DisplayName') -like 'GodotHub*' })
Check ($entries.Count -eq 1) "one GodotHub entry in Apps (got $($entries.Count))"
Check ((Get-ItemProperty 'HKCU:\Software\GodotHub\GodotHub' -ErrorAction SilentlyContinue).'(default)' -eq $installDir) 'app key still points at the install folder'
Check ((Aumid $startMenu 'GodotHub.lnk') -eq 'Ryko.GodotHub') 'Start menu shortcut keeps AppUserModelID Ryko.GodotHub'
Check ((LinkTarget (Join-Path $startMenu 'GodotHub.lnk')) -eq (Join-Path $installDir 'godothub.exe')) 'Start menu shortcut targets the launcher'
Check ((LinkTarget (Join-Path $desktop 'GodotHub.lnk')) -eq (Join-Path $installDir 'godothub.exe')) 'desktop shortcut targets the launcher'
$out = (& (Join-Path $installDir 'godothub.exe') --version | Out-String).Trim()
Check ($out -eq "godothub $version") "launcher passes --version through ($out)"
Check (WaitForWindow (Join-Path $installDir 'godothub.exe')) 'Flutter app opens a window through the launcher'
Start-Sleep 5
StopApp
Check ((Get-Content (Join-Path $data 'sandbox-marker.txt') -ErrorAction SilentlyContinue) -eq 'kept across the upgrade') 'existing data kept'
Check ((Snapshot $data).Contains('sandbox-marker.txt')) 'data folder still holds the Tauri files'
Note "     data files after: $(((Get-ChildItem $data -Recurse -File).Count))"

$p = Start-Process (Join-Path $installDir 'uninstall.exe') -ArgumentList '/S' -PassThru -Wait
for ($i = 0; $i -lt 60 -and (Test-Path $installDir); $i++) { Start-Sleep -Milliseconds 500 }
Check (-not (Test-Path $installDir)) 'uninstall removes the install folder'
Check (-not (Test-Path $uninstallKey)) 'uninstall removes the Apps entry'
Check (-not (Test-Path (Join-Path $desktop 'GodotHub.lnk'))) 'uninstall removes the desktop shortcut'
Check (Test-Path (Join-Path $data 'sandbox-marker.txt')) 'uninstall keeps user data'

Note "`n== Tauri MSI, then the Flutter MSI"
$pf = Join-Path $env:ProgramFiles 'GodotHub'
$p = Start-Process msiexec.exe -ArgumentList '/i', "`"$($tauriMsi.FullName)`"", '/qn', '/norestart', '/l*v', "`"$results\tauri-msi.log`"" -PassThru -Wait
Check ($p.ExitCode -eq 0) "Tauri MSI installs (exit $($p.ExitCode))"
$p = Start-Process msiexec.exe -ArgumentList '/i', "`"$msi`"", '/qn', '/norestart', '/l*v', "`"$results\flutter-msi.log`"" -PassThru -Wait
Check ($p.ExitCode -eq 0) "Flutter MSI upgrades it (exit $($p.ExitCode))"
$machine = @(Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | Where-Object { $_.GetValue('DisplayName') -like 'GodotHub*' })
Check ($machine.Count -eq 1) "one GodotHub entry after the MSI upgrade (got $($machine.Count))"
Check (($machine | Select-Object -First 1).GetValue('DisplayVersion') -eq $version) 'the remaining entry is the Flutter version'
Check (Test-Path (Join-Path $pf 'godothub.exe')) 'Flutter MSI installs into Program Files\GodotHub'
Check (Test-Path (Join-Path $pf 'data\flutter_assets')) 'Flutter MSI installs the data folder'
$out = (& (Join-Path $pf 'godothub.exe') --version | Out-String).Trim()
Check ($out -eq "godothub $version") "MSI binary answers --version ($out)"
Check (WaitForWindow (Join-Path $pf 'godothub.exe')) 'Flutter app from the MSI opens a window'
StopApp
$p = Start-Process msiexec.exe -ArgumentList '/x', "`"$msi`"", '/qn', '/norestart' -PassThru -Wait
Check ($p.ExitCode -eq 0) "Flutter MSI uninstalls (exit $($p.ExitCode))"
Check (-not (Test-Path (Join-Path $pf 'godothub.exe'))) 'MSI uninstall removes the files'

Note "`n$script:failures failure(s)"
Set-Content (Join-Path $results 'done.txt') "$script:failures"
