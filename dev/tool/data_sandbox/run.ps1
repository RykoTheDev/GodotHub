param([string]$Lab = 'C:\lab')

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, UIAutomationClient, UIAutomationTypes
Add-Type -Path (Join-Path $Lab 'UiaCom.cs') -ReferencedAssemblies Accessibility
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
  public static void Click(int x, int y) { SetCursorPos(x, y); mouse_event(2, 0, 0, 0, UIntPtr.Zero); mouse_event(4, 0, 0, 0, UIntPtr.Zero); }
}
'@

$config = Get-Content (Join-Path $Lab 'sandbox.json') -Raw | ConvertFrom-Json
$results = Join-Path $Lab 'results'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$log = Join-Path $results 'checks.txt'
Set-Content $log ''
$script:failures = 0
function Note([string]$text) { Add-Content $log $text; Write-Host $text }
function Check([bool]$ok, [string]$what) { if ($ok) { Note "ok   $what" } else { Note "FAIL $what"; $script:failures++ } }

$roaming = Join-Path $env:APPDATA 'Ryko.GodotHub'
$roamingBeta = Join-Path $env:APPDATA 'Ryko.GodotHub.Beta'
$webview = Join-Path $env:LOCALAPPDATA 'Ryko.GodotHub\EBWebView\Default'
$gistDir = Join-Path $env:USERPROFILE '.godothub'
$installDir = Join-Path $env:LOCALAPPDATA 'GodotHub'
$exe = Join-Path $installDir 'godothub.exe'
$tauriSetup = (Get-ChildItem (Join-Path $Lab 'tauri') -Filter 'GodotHub-*-windows-x64-setup.exe' | Select-Object -First 1).FullName
$flutterSetup = Join-Path $Lab "dist\GodotHub-$($config.version)-windows-x64-setup.exe"
$betaSetup = (Get-ChildItem (Join-Path $Lab 'beta') -Filter '*-setup.exe' -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
$secret = 'git-credentials|git_auth\.json'

function AppWindows {
  @(Get-Process godothub, godothub-beta -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like 'GodotHub*' })
}

function WaitWindow([string]$title = 'GodotHub', [int]$seconds = 60) {
  for ($i = 0; $i -lt $seconds; $i++) {
    $w = AppWindows | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
    if ($w) { Start-Sleep 4; return $w }
    Start-Sleep 1
  }
  return $null
}

function Shot($proc, [string]$name) {
  $h = $proc.MainWindowHandle
  [Win]::ShowWindow($h, 3) | Out-Null
  [Win]::SetForegroundWindow($h) | Out-Null
  Start-Sleep -Milliseconds 1500
  $r = New-Object Win+RECT
  [Win]::GetWindowRect($h, [ref]$r) | Out-Null
  $w = $r.Right - $r.Left; $hgt = $r.Bottom - $r.Top
  if ($w -le 0 -or $hgt -le 0) { return }
  $bmp = New-Object System.Drawing.Bitmap $w, $hgt
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
  $bmp.Save((Join-Path $results "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

function Focus($proc) {
  $h = $proc.MainWindowHandle
  [Win]::SetForegroundWindow($h) | Out-Null
  $r = New-Object Win+RECT
  [Win]::GetWindowRect($h, [ref]$r) | Out-Null
  [Win]::Click([int](($r.Left + $r.Right) / 2), $r.Top + 16)
  Start-Sleep -Milliseconds 400
}

function Keys($proc, [string]$keys) {
  Focus $proc
  [System.Windows.Forms.SendKeys]::SendWait($keys)
  Start-Sleep -Milliseconds 2500
}

function ClickAt($proc, [int]$x, [int]$y, [int]$wait = 2500) {
  $h = $proc.MainWindowHandle
  [Win]::SetForegroundWindow($h) | Out-Null
  $r = New-Object Win+RECT
  [Win]::GetWindowRect($h, [ref]$r) | Out-Null
  [Win]::SetCursorPos($r.Left + $x, $r.Top + $y) | Out-Null
  Start-Sleep -Milliseconds 700
  [Win]::Click($r.Left + $x, $r.Top + $y)
  Start-Sleep -Milliseconds $wait
}

$sidebar = [ordered]@{ '1-projects' = @('Projects', 182); '2-versions' = @('Versions', 223); '3-templates' = @('Templates', 264); '4-vault' = @('Vault', 356); '5-storage' = @('Storage', 397); '6-assets' = @('Asset Store', 490); '7-news' = @('Godot News', 530) }

function WaitUia($proc, [string]$name, [int]$seconds = 15) {
  for ($i = 0; $i -lt $seconds * 2; $i++) {
    if ([UiaCom]::Exists($proc.MainWindowHandle, $name)) { return $true }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Press($proc, [string]$name, [int]$x = -1, [int]$y = -1, [int]$wait = 2500) {
  [Win]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
  if ((WaitUia $proc $name 5) -and [UiaCom]::Invoke($proc.MainWindowHandle, $name)) {
    $script:pressed[[UiaCom]::LastPath]++
    Start-Sleep -Milliseconds $wait
    return
  }
  $script:pressed['position']++
  Note "     '$name' not found through accessibility, $(if ($x -ge 0) { 'clicking by position' } else { 'skipped' })"
  if ($x -ge 0) { ClickAt $proc $x $y $wait }
}

$script:pressed = @{ uia = 0; msaa = 0; position = 0 }

function Tour($proc, [string]$prefix) {
  $found = WaitUia $proc 'Projects'
  Note "     accessibility tree ready: $found (MSAA nodes: $([UiaCom]::MsaaCount($proc.MainWindowHandle)))"
  Shot $proc "$prefix-0-start"
  foreach ($entry in $sidebar.GetEnumerator()) { Press $proc $entry.Value[0] 140 $entry.Value[1]; Shot $proc "$prefix-$($entry.Key)" }
  Press $proc 'Settings' 245 734; Shot $proc "$prefix-8-settings"
  Press $proc 'Projects' 140 182
}

function DumpTree($proc, [string]$name, [int]$max = 2500) {
  WaitUia $proc 'Projects' | Out-Null
  Set-Content (Join-Path $results "$name.txt") ([UiaCom]::Dump($proc.MainWindowHandle, $max))
}

function CloseApp([string]$title = 'GodotHub') {
  foreach ($w in AppWindows | Where-Object { $_.MainWindowTitle -eq $title }) { $w.CloseMainWindow() | Out-Null }
  for ($i = 0; $i -lt 20 -and (AppWindows | Where-Object { $_.MainWindowTitle -eq $title }); $i++) { Start-Sleep 1 }
  $name = if ($title -eq 'GodotHub Beta') { 'godothub-beta' } else { 'godothub' }
  Get-Process $name -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep 2
}

function Snapshot([string]$name) {
  $dest = Join-Path $results "data-$name"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $rows = foreach ($f in Get-ChildItem $roaming -Recurse -File -Force -ErrorAction SilentlyContinue) {
    $rel = $f.FullName.Substring($roaming.Length + 1)
    if ($rel -match $secret) { "$rel|secret|$($f.Length)"; continue }
    '{0}|{1}|{2}' -f $rel, (Get-FileHash $f.FullName -Algorithm SHA256).Hash, $f.Length
    $target = Join-Path $dest $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item $f.FullName $target
  }
  Set-Content (Join-Path $results "hashes-$name.txt") ($rows | Sort-Object)
}

function Seed([string]$dataset) {
  $src = Join-Path $Lab "datasets\$dataset"
  Remove-Item $roaming, $webview, $gistDir -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item -Recurse (Join-Path $src 'Roaming\Ryko.GodotHub') $roaming
  if (Test-Path (Join-Path $src 'WebView')) {
    New-Item -ItemType Directory -Force -Path $webview | Out-Null
    Copy-Item -Recurse (Join-Path $src 'WebView\*') $webview
  }
  if (Test-Path (Join-Path $src 'dot-godothub')) { Copy-Item -Recurse (Join-Path $src 'dot-godothub') $gistDir }
  $made = 0
  foreach ($file in Get-ChildItem (Join-Path $roaming 'workspaces') -Recurse -Filter 'projects.json') {
    $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $list = if ($data.projects) { $data.projects } else { $data }
    foreach ($p in $list) {
      if (-not $p.path) { continue }
      $drive = $p.path.Substring(0, 1).ToUpper()
      if (-not (Test-Path "${drive}:\")) {
        $root = Join-Path 'C:\fakedrives' $drive
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        subst "${drive}:" $root
      }
      if (-not (Test-Path $p.path)) {
        New-Item -ItemType Directory -Force -Path $p.path | Out-Null
        Set-Content (Join-Path $p.path 'project.godot') "config_version=5`n`n[application]`n`nconfig/name=`"$($p.name)`"`n"
        $made++
      }
    }
  }
  Note "     placeholder project folders: $made"
}

function InstallTauri {
  $p = Start-Process $tauriSetup -ArgumentList '/S' -PassThru; $p.WaitForExit()
  return $p.ExitCode
}

function InstallFlutter {
  $p = Start-Process $flutterSetup -ArgumentList '/P', '/UPDATE' -PassThru; $p.WaitForExit()
  return $p.ExitCode
}

function UninstallAll {
  CloseApp
  if (Test-Path (Join-Path $installDir 'uninstall.exe')) {
    $p = Start-Process (Join-Path $installDir 'uninstall.exe') -ArgumentList '/S' -PassThru; $p.WaitForExit()
    for ($i = 0; $i -lt 40 -and (Test-Path $installDir); $i++) { Start-Sleep -Milliseconds 500 }
  }
  Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
}

function WebViewHashes {
  @(Get-ChildItem $webview -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    '{0}|{1}' -f $_.FullName.Substring($webview.Length + 1), (Get-FileHash $_.FullName -Algorithm SHA256).Hash
  } | Sort-Object)
}

function SavePrefs([string]$name) {
  $file = Join-Path $roaming 'ui_prefs.json'
  if (Test-Path $file) { Copy-Item $file (Join-Path $results "prefs-$name.json") }
  return (Test-Path $file)
}

function ComparePrefs([string]$left, [string]$right) {
  $a = (Get-Content (Join-Path $results "prefs-$left.json") -Raw | ConvertFrom-Json).values
  $b = (Get-Content (Join-Path $results "prefs-$right.json") -Raw | ConvertFrom-Json).values
  $same = 0
  $keys = @($a.PSObject.Properties.Name) + @($b.PSObject.Properties.Name) | Sort-Object -Unique
  foreach ($key in $keys) {
    $x = $a.$key; $y = $b.$key
    if ($x -eq $y) { $same++ } else { Note ("     differs {0} | {1}={2} | {3}={4}" -f $key, $left, "$x".Substring(0, [Math]::Min(80, "$x".Length)), $right, "$y".Substring(0, [Math]::Min(80, "$y".Length))) }
  }
  Note "     $same of $($keys.Count) keys match between $left and $right"
}

function DirectRun([string]$dataset) {
  Note "`n===== dataset $dataset, Flutter installed directly"
  UninstallAll
  Seed $dataset
  Check (-not (Test-Path (Join-Path $roaming 'ui_prefs.json'))) 'the seeded data has no ui_prefs.json'
  $before = WebViewHashes
  Check ($before.Count -gt 0) "the seeded WebView storage has $($before.Count) files"
  Check ((InstallFlutter) -eq 0) 'Flutter installs with no Tauri run first'
  Start-Process $exe
  $w = WaitWindow
  Check ($null -ne $w) 'Flutter opens'
  if ($w) { Tour $w "$dataset-direct-a-flutter" }
  CloseApp
  Check (((WebViewHashes) -join "`n") -eq ($before -join "`n")) 'the WebView storage is unchanged'
  Check (SavePrefs 'direct-flutter') 'Flutter wrote ui_prefs.json'
  Snapshot "$dataset-direct-flutter"

  Note '-- Tauri 1.5.9 on a fresh copy of the same data'
  UninstallAll
  Seed $dataset
  Check ((InstallTauri) -eq 0) 'Tauri installs'
  Start-Process $exe
  $w = WaitWindow
  Check ($null -ne $w) 'Tauri opens'
  if ($w) { Tour $w "$dataset-direct-b-tauri" }
  CloseApp
  Check (SavePrefs 'direct-tauri') 'Tauri wrote ui_prefs.json'
  if ((Test-Path (Join-Path $results 'prefs-direct-flutter.json')) -and (Test-Path (Join-Path $results 'prefs-direct-tauri.json'))) {
    ComparePrefs 'direct-flutter' 'direct-tauri'
  }
}

if ($config.mode -eq 'direct') {
  foreach ($dataset in $config.datasets) { DirectRun $dataset }
  Note "`nsteps through UI Automation: $($script:pressed.uia), MSAA: $($script:pressed.msaa), screen position: $($script:pressed.position)"
  Note "$script:failures failure(s)"
  Set-Content (Join-Path $results 'done.txt') "$script:failures"
  return
}

foreach ($dataset in $config.datasets) {
  Note "`n===== dataset $dataset"
  UninstallAll
  Seed $dataset
  Snapshot "$dataset-0-seed"

  Note '-- Tauri 1.5.9 on the copied data'
  Check ((InstallTauri) -eq 0) 'Tauri installs'
  Start-Process $exe
  $w = WaitWindow
  Check ($null -ne $w) 'Tauri opens'
  if ($w) { Tour $w "$dataset-a-tauri"; if ($config.dump) { DumpTree $w "$dataset-a-tauri-tree" } }
  CloseApp
  Snapshot "$dataset-1-tauri"

  Note '-- Flutter stable over it'
  Check ((InstallFlutter) -eq 0) 'Flutter setup installs over Tauri'
  Start-Process $exe
  $w = WaitWindow
  Check ($null -ne $w) 'Flutter opens on the Tauri data'
  if ($w) {
    Tour $w "$dataset-b-flutter"
    if ($config.dump) { DumpTree $w "$dataset-b-flutter-tree" }
    $actions = Join-Path $Lab 'actions.ps1'
    if (Test-Path $actions) { . $actions; FlutterChanges $w $dataset }
  }
  CloseApp
  Snapshot "$dataset-2-flutter"

  Note '-- Rollback: Tauri 1.5.9 again on the data Flutter wrote'
  UninstallAll
  Check ((InstallTauri) -eq 0) 'Tauri reinstalls'
  Start-Process $exe
  $w = WaitWindow
  Check ($null -ne $w) 'Tauri opens on the data Flutter wrote'
  if ($w) { Tour $w "$dataset-c-tauri-again" }
  CloseApp
  Snapshot "$dataset-3-tauri-again"
}

if ($betaSetup) {
  Note "`n===== stable and beta side by side"
  UninstallAll
  Remove-Item $roamingBeta -Recurse -Force -ErrorAction SilentlyContinue
  Check ((InstallFlutter) -eq 0) 'stable installs'
  $p = Start-Process $betaSetup -ArgumentList '/S' -PassThru; $p.WaitForExit()
  Check ($p.ExitCode -eq 0) 'beta installs'
  $betaExe = Join-Path $env:LOCALAPPDATA 'GodotHub Beta\godothub-beta.exe'
  Start-Process $exe; $stable = WaitWindow 'GodotHub'
  Start-Process $betaExe; $beta = WaitWindow 'GodotHub Beta'
  Check ($null -ne $stable -and $null -ne $beta) 'both windows are open at the same time'
  Check ((AppWindows).Count -eq 2) "two app windows (got $((AppWindows).Count))"
  Check (Test-Path $roamingBeta) 'beta uses its own data folder'
  $keys = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object { $_.GetValue('DisplayName') -like 'GodotHub*' } | ForEach-Object { $_.GetValue('DisplayName') })
  Check (($keys -contains 'GodotHub') -and ($keys -contains 'GodotHub Beta')) "both Apps entries ($($keys -join ', '))"
  if ($stable) { Shot $stable 'side-by-side-stable' }
  if ($beta) { Shot $beta 'side-by-side-beta' }
  CloseApp 'GodotHub Beta'
  CloseApp
}

Note "`nsteps through UI Automation: $($script:pressed.uia), MSAA: $($script:pressed.msaa), screen position: $($script:pressed.position)"
Note "$script:failures failure(s)"
Set-Content (Join-Path $results 'done.txt') "$script:failures"
