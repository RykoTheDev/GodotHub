param(
  [Parameter(Mandatory = $true)][string]$Setup,
  [Parameter(Mandatory = $true)][string]$DisplayName,
  [Parameter(Mandatory = $true)][string]$Identifier,
  [Parameter(Mandatory = $true)][string]$ExeName,
  [string]$ExpectedVersion = ''
)

$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]
function Check([bool]$ok, [string]$what) {
  if ($ok) { Write-Host "ok   $what" } else { Write-Host "FAIL $what"; $failures.Add($what) }
}

function RegistrySnapshot([string]$path) {
  if (-not (Test-Path $path)) { return '<absent>' }
  $item = Get-Item $path
  $lines = foreach ($name in ($item.GetValueNames() | Sort-Object)) { "$name=$($item.GetValue($name))" }
  $children = Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object { $_.PSChildName } | Sort-Object
  ($lines + $children) -join "`n"
}

function FolderSnapshot([string]$path) {
  if (-not (Test-Path $path)) { return '<absent>' }
  (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object { '{0}|{1}|{2}' -f $_.FullName.Substring($path.Length), $_.Length, $_.LastWriteTimeUtc.Ticks } |
    Sort-Object) -join "`n"
}

function FileHash([string]$path) {
  if (-not (Test-Path $path)) { return '<absent>' }
  (Get-FileHash $path -Algorithm SHA256).Hash
}

$uninstallRoot = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$stable = [ordered]@{
  'uninstall key GodotHub'       = { RegistrySnapshot "$uninstallRoot\GodotHub" }
  'uninstall key Ryko.GodotHub'  = { RegistrySnapshot "$uninstallRoot\Ryko.GodotHub" }
  'app key Software\Ryko\GodotHub' = { RegistrySnapshot 'HKCU:\Software\Ryko\GodotHub' }
  'machine uninstall entries'    = {
    (Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
      Where-Object { $_.GetValue('DisplayName') -like 'GodotHub*' } | ForEach-Object { "$($_.PSChildName)=$($_.GetValue('DisplayName'))=$($_.GetValue('DisplayVersion'))" } | Sort-Object) -join "`n"
  }
  'install folder'               = { FolderSnapshot (Join-Path $env:LOCALAPPDATA 'GodotHub') }
  'program files folder'         = { FolderSnapshot (Join-Path $env:ProgramFiles 'GodotHub') }
  'start menu shortcut'          = { FileHash (Join-Path $startMenu 'GodotHub.lnk') }
  'data folder listing'          = { FolderSnapshot (Join-Path $env:APPDATA 'Ryko.GodotHub') }
}
$before = @{}
foreach ($k in $stable.Keys) { $before[$k] = & $stable[$k] }
$betaData = Join-Path $env:APPDATA $Identifier
$betaDataBefore = FolderSnapshot $betaData

$installDir = Join-Path $env:LOCALAPPDATA $DisplayName
$uninstallKey = "$uninstallRoot\$Identifier"
$shortcut = Join-Path $startMenu "$DisplayName.lnk"
if ((Test-Path $installDir) -or (Test-Path $uninstallKey)) {
  throw "$DisplayName is already installed; uninstall it before running the smoke test"
}

$p = Start-Process -FilePath $Setup -ArgumentList '/S' -PassThru -Wait
Check ($p.ExitCode -eq 0) "silent install exits 0 (got $($p.ExitCode))"
$exe = Join-Path $installDir $ExeName
Check (Test-Path $exe) "installed to $installDir"
Check (Test-Path (Join-Path $installDir 'launcher.json')) 'launcher state written'
if ($ExpectedVersion) {
  Check (Test-Path (Join-Path $installDir "app-$ExpectedVersion\$ExeName")) "app installed into app-$ExpectedVersion"
  Check ((Get-Content (Join-Path $installDir 'launcher.json') -Raw | ConvertFrom-Json).current -eq $ExpectedVersion) "launcher starts $ExpectedVersion"
}
Check ((Get-ItemProperty $uninstallKey -ErrorAction SilentlyContinue).DisplayName -eq $DisplayName) "uninstall entry $Identifier named $DisplayName"
Check ((Get-ItemProperty $uninstallKey -ErrorAction SilentlyContinue).InstallLocation -eq $installDir) 'uninstall entry points at the beta folder'
Check (Test-Path $shortcut) "start menu shortcut $DisplayName.lnk"
$shell = New-Object -ComObject Shell.Application
$aumid = $shell.NameSpace($startMenu).ParseName("$DisplayName.lnk").ExtendedProperty('System.AppUserModel.ID')
Check ($aumid -eq $Identifier) "shortcut AppUserModelID is $Identifier (got '$aumid')"
if (Test-Path $exe) {
  $version = (& $exe --version | Out-String).Trim()
  Check ($version -like "$($ExeName -replace '\.exe$','') *") "installed binary answers --version ($version)"
  if ($ExpectedVersion) { Check ($version -eq "$($ExeName -replace '\.exe$','') $ExpectedVersion") "version is $ExpectedVersion" }
}

$uninstaller = Join-Path $installDir 'uninstall.exe'
$u = Start-Process -FilePath $uninstaller -ArgumentList '/S' -PassThru -Wait
Check ($u.ExitCode -eq 0) "silent uninstall exits 0 (got $($u.ExitCode))"
for ($i = 0; $i -lt 60 -and (Test-Path $installDir); $i++) { Start-Sleep -Milliseconds 500 }
Check (-not (Test-Path $installDir)) 'beta folder removed'
Check (-not (Test-Path $uninstallKey)) 'beta uninstall entry removed'
Check (-not (Test-Path "HKCU:\Software\Ryko\$Identifier")) 'beta app key removed'
Check (-not (Test-Path $shortcut)) 'beta shortcut removed'
Check ((FolderSnapshot $betaData) -eq $betaDataBefore) 'beta app data left as it was'

foreach ($k in $stable.Keys) {
  Check ((& $stable[$k]) -eq $before[$k]) "stable $k unchanged"
}

if ($failures.Count -gt 0) {
  Write-Host "`n$($failures.Count) check(s) failed"
  exit 1
}
Write-Host "`nall checks passed"
