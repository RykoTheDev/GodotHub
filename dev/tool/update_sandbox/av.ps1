param([string]$Lab = 'C:\lab')

$ErrorActionPreference = 'Continue'
$results = Join-Path $Lab 'results'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$log = Join-Path $results 'av.txt'
Set-Content $log ''
function Note([string]$text) { Add-Content $log $text; Write-Host $text }

function DefenderState {
  $s = Get-MpComputerStatus -ErrorAction SilentlyContinue
  if (-not $s) { Note 'Defender: not available'; return }
  Note ("Defender: service={0} realtime={1} behavior={2} ioav={3} engine={4} signatures={5}" -f $s.AMServiceEnabled, $s.RealTimeProtectionEnabled, $s.BehaviorMonitorEnabled, $s.IoavProtectionEnabled, $s.AMEngineVersion, $s.AntivirusSignatureVersion)
  $p = Get-MpPreference -ErrorAction SilentlyContinue
  if ($p) { Note ("Defender: cloud={0} sampleSubmission={1} pua={2}" -f $p.MAPSReporting, $p.SubmitSamplesConsent, $p.PUAProtection) }
}

function SmartScreenState {
  $policy = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name SmartScreenEnabled -ErrorAction SilentlyContinue
  Note ("SmartScreen (Explorer): {0}" -f $(if ($policy) { $policy.SmartScreenEnabled } else { 'default (on)' }))
}

function Windows {
  Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle } | ForEach-Object { "$($_.ProcessName): $($_.MainWindowTitle)" }
}

function Downloaded([string]$source, [string]$name) {
  $downloads = Join-Path $env:USERPROFILE 'Downloads'
  New-Item -ItemType Directory -Force -Path $downloads | Out-Null
  $target = Join-Path $downloads $name
  Copy-Item $source $target -Force
  Set-Content -Path $target -Stream Zone.Identifier -Value "[ZoneTransfer]`r`nZoneId=3`r`nHostUrl=https://github.com/RykoTheDev/GodotHub/releases/download/v0/$name"
  $target
}

function Probe([string]$what, [string]$source, [string]$name) {
  Note "`n===== $what"
  $file = Downloaded $source $name
  $zone = Get-Content -Path $file -Stream Zone.Identifier -ErrorAction SilentlyContinue
  Note ("mark of the web: {0}" -f (($zone | Where-Object { $_ -like 'ZoneId*' }) -join ' '))
  $before = @(Windows)
  try { Start-Process -FilePath $file -ErrorAction Stop } catch { Note "launch error: $($_.Exception.Message)" }
  Start-Sleep 12
  $after = @(Windows) | Where-Object { $before -notcontains $_ }
  if ($after) { $after | ForEach-Object { Note "window: $_" } } else { Note 'window: none' }
  $smart = Get-Process smartscreen -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }
  Note ("SmartScreen prompt: {0}" -f $(if ($smart) { "shown ($($smart.MainWindowTitle))" } else { 'not shown' }))
  $base = [IO.Path]::GetFileNameWithoutExtension($name)
  $running = Get-Process | Where-Object { $_.ProcessName -like "$base*" -or $_.ProcessName -eq 'msiexec' -and $_.MainWindowHandle -ne 0 }
  Note ("installer UI reached: {0}" -f $(if ($running) { ($running.ProcessName | Sort-Object -Unique) -join ', ' } else { 'no' }))
  Get-Process smartscreen -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  $running | Stop-Process -Force -ErrorAction SilentlyContinue
  Get-Process msiexec -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep 2
}

function Detections([string]$when) {
  Note "`n===== Defender detections $when"
  $threats = @(Get-MpThreatDetection -ErrorAction SilentlyContinue)
  if ($threats.Count -eq 0) { Note 'threats: none' }
  foreach ($t in $threats) { Note ("threat: id={0} action={1} resources={2}" -f $t.ThreatID, $t.ActionSuccess, ($t.Resources -join '; ')) }
  $events = @(Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -ErrorAction SilentlyContinue | Where-Object { $_.Id -in 1006, 1007, 1008, 1015, 1116, 1117, 1118, 1119, 1121, 1122, 1123, 1124, 1125, 1126 })
  if ($events.Count -eq 0) { Note 'detection or block events: none' }
  foreach ($e in $events) { Note ("event {0} at {1}: {2}" -f $e.Id, $e.TimeCreated.ToString('s'), (($e.Message -split "`n")[0..3] -join ' | ')) }
  $smart = @(Get-WinEvent -LogName 'Microsoft-Windows-SmartScreen/Debug' -ErrorAction SilentlyContinue)
  Note ("SmartScreen debug events: {0}" -f $smart.Count)
}

DefenderState
SmartScreenState
Probe 'Flutter 1.9.1 setup.exe from the internet zone' (Join-Path $Lab 'dist\1.9.1\GodotHub-1.9.1-windows-x64-setup.exe') 'GodotHub-1.9.1-windows-x64-setup.exe'
Probe 'Flutter 1.9.1 MSI from the internet zone' (Join-Path $Lab 'dist\1.9.1\GodotHub-1.9.1-windows-x64.msi') 'GodotHub-1.9.1-windows-x64.msi'
Probe 'Tauri 1.5.9 setup.exe from the internet zone' (Join-Path $Lab 'tauri\tauri-setup.exe') 'GodotHub_1.5.9_x64-setup.exe'
Probe 'Tauri 1.5.9 MSI from the internet zone' (Join-Path $Lab 'tauri\tauri.msi') 'GodotHub_1.5.9_x64_en-US.msi'
Detections 'before the update run'

Note "`n===== install, launch, in-app update and rollback (run.ps1)"
& (Join-Path $Lab 'run.ps1') -Lab $Lab
Note ("run.ps1 failures: {0}" -f (Get-Content (Join-Path $results 'done.txt') -ErrorAction SilentlyContinue))
$staged = Join-Path $env:LOCALAPPDATA 'godothub-updates'
Note ("installer staging folder {0}: {1}" -f $staged, $(if (Test-Path $staged) { 'present' } else { 'absent' }))
$tempLeft = @(Get-ChildItem $env:TEMP -Directory -Filter 'godothub-*-updater-*' -ErrorAction SilentlyContinue)
Note ("updater folders left in %TEMP%: {0}" -f $tempLeft.Count)
Detections 'after the update run'
DefenderState
Set-Content (Join-Path $results 'av-done.txt') 'yes'
