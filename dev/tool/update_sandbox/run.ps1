param([string]$Lab = 'C:\lab')

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Path (Join-Path $Lab 'UiaCom.cs') -ReferencedAssemblies Accessibility
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Disk {
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool GetDiskFreeSpaceEx(string path, out ulong free, out ulong total, out ulong totalFree);
  public static long Free(string path) { ulong f, t, tf; return GetDiskFreeSpaceEx(path, out f, out t, out tf) ? (long)f : -1; }
  public static long Total(string path) { ulong f, t, tf; return GetDiskFreeSpaceEx(path, out f, out t, out tf) ? (long)t : -1; }
}
public static class Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
  public static string ClassOf(IntPtr h) { var s = new System.Text.StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
}
'@

$results = Join-Path $Lab 'results'
New-Item -ItemType Directory -Force -Path $results | Out-Null
$log = Join-Path $results 'checks.txt'
Set-Content $log ''
$script:failures = 0
function Note([string]$text) { Add-Content $log $text; Write-Host $text }
function Check([bool]$ok, [string]$what) { if ($ok) { Note "ok   $what" } else { Note "FAIL $what"; $script:failures++ } }

$roaming = Join-Path $env:APPDATA 'Ryko.GodotHub'
$webview = Join-Path $env:LOCALAPPDATA 'Ryko.GodotHub\EBWebView\Default'
$userDir = Join-Path $env:LOCALAPPDATA 'GodotHub'
$machineDir = Join-Path $env:ProgramFiles 'GodotHub'
$serve = Join-Path $Lab 'serve'
New-Item -ItemType Directory -Force -Path $serve | Out-Null

Start-Process powershell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Lab 'server.ps1'), '-Lab', $Lab -WindowStyle Hidden
Start-Sleep 3

function Serve([string]$manifest, [string]$mode = 'normal') {
  Copy-Item (Join-Path $Lab "manifests\$manifest.json") (Join-Path $serve 'latest-v2.json') -Force
  Set-Content (Join-Path $serve 'mode.txt') $mode
  Note "     serving $manifest ($mode)"
}

function AppWindow([int]$seconds = 60) {
  for ($i = 0; $i -lt $seconds; $i++) {
    $w = Get-Process godothub -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq 'GodotHub' } | Select-Object -First 1
    if ($w) { return $w }
    Start-Sleep 1
  }
  return $null
}

function IsFlutter($proc) { $proc -and [Win]::ClassOf($proc.MainWindowHandle) -eq 'FLUTTER_RUNNER_WIN32_WINDOW' }

function WaitName($proc, [string]$name, [int]$seconds = 30) {
  for ($i = 0; $i -lt $seconds * 2; $i++) {
    if ([UiaCom]::Exists($proc.MainWindowHandle, $name)) { return $true }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Press($proc, [string]$name, [int]$seconds = 30) {
  [Win]::SetForegroundWindow($proc.MainWindowHandle) | Out-Null
  if ((WaitName $proc $name $seconds) -and [UiaCom]::Invoke($proc.MainWindowHandle, $name)) { Start-Sleep 2; return $true }
  Note "     '$name' not found"
  return $false
}

function Shot($proc, [string]$name) {
  if (-not $proc) { return }
  $r = New-Object Win+RECT
  [Win]::GetWindowRect($proc.MainWindowHandle, [ref]$r) | Out-Null
  $w = $r.Right - $r.Left; $h = $r.Bottom - $r.Top
  if ($w -le 0 -or $h -le 0) { return }
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
  $bmp.Save((Join-Path $results "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Set-Content (Join-Path $results "$name-tree.txt") ([UiaCom]::Dump($proc.MainWindowHandle, 2000))
}

function CloseApp {
  Get-Process godothub -ErrorAction SilentlyContinue | ForEach-Object { $_.CloseMainWindow() | Out-Null }
  Start-Sleep 3
  Get-Process godothub, msiexec -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq 'godothub' } | Stop-Process -Force
  Start-Sleep 2
}

function UninstallAll {
  CloseApp
  $uninstaller = Join-Path $userDir 'uninstall.exe'
  if (Test-Path $uninstaller) { $p = Start-Process $uninstaller -ArgumentList '/S' -PassThru; $p.WaitForExit(); Start-Sleep 3 }
  foreach ($key in Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue) {
    if ($key.GetValue('DisplayName') -like 'GodotHub*' -and $key.PSChildName -match '^\{') {
      $p = Start-Process msiexec -ArgumentList '/x', $key.PSChildName, '/qn' -PassThru; $p.WaitForExit()
    }
  }
  Remove-Item $userDir, $machineDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Seed {
  Remove-Item $roaming, (Join-Path $env:LOCALAPPDATA 'Ryko.GodotHub') -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item -Recurse (Join-Path $Lab 'backup\Roaming\Ryko.GodotHub') $roaming
  New-Item -ItemType Directory -Force -Path $webview | Out-Null
  Copy-Item -Recurse (Join-Path $Lab 'backup\WebView\*') $webview
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
      if (-not (Test-Path (Join-Path $p.path 'project.godot'))) {
        New-Item -ItemType Directory -Force -Path $p.path | Out-Null
        Set-Content (Join-Path $p.path 'project.godot') "config_version=5`n`n[application]`n`nconfig/name=`"$($p.name)`"`n"
      }
    }
  }
}

function Run([string]$file, [string[]]$arguments) {
  $p = Start-Process $file -ArgumentList $arguments -PassThru
  $p.WaitForExit()
  return $p.ExitCode
}

function LauncherState {
  $file = Join-Path $userDir 'launcher.json'
  if (Test-Path $file) { return Get-Content $file -Raw | ConvertFrom-Json }
  return $null
}

function FileVersion([string]$exe) { if (Test-Path $exe) { (Get-Item $exe).VersionInfo.ProductVersion } else { 'missing' } }

function OpenUpdate($proc) {
  if (-not (Press $proc 'Update available' 60)) { return $false }
  return WaitName $proc 'Install' 60
}

function WaitFlutterAfterUpdate([int]$seconds = 240) {
  for ($i = 0; $i -lt $seconds; $i += 2) {
    $w = AppWindow 1
    if ($w -and (IsFlutter $w)) { return $w }
    Start-Sleep 1
  }
  return $null
}

function TauriToFlutter([string]$kind) {
  Note "`n===== Tauri 1.5.9 $kind to Flutter stable through the Tauri updater"
  UninstallAll
  Seed
  if ($kind -eq 'nsis') { $code = Run (Join-Path $Lab 'tauri\tauri-setup.exe') @('/S'); $exe = Join-Path $userDir 'godothub.exe' }
  else { $code = Run msiexec @('/i', (Join-Path $Lab 'tauri\tauri.msi'), '/qn'); $exe = Join-Path $machineDir 'godothub.exe' }
  Check ($code -eq 0) "Tauri $kind installs (exit $code)"
  Serve '1.9.1'
  Start-Process $exe
  $w = AppWindow
  Check ($w -and -not (IsFlutter $w)) 'Tauri opens'
  if (-not $w) { return }
  Check (OpenUpdate $w) 'Tauri shows the 1.9.1 update'
  Shot $w "tauri-$kind-1-update"
  Check (Press $w 'Install') 'Tauri starts the install'
  $f = WaitFlutterAfterUpdate
  Check ($null -ne $f) 'the Flutter app starts after the Tauri updater ran the installer'
  if ($f) {
    Check (WaitName $f 'Projects' 30) 'Flutter shows its shell'
    Start-Sleep 3
    Check ([UiaCom]::Dump($f.MainWindowHandle, 3000) -match 'Barely a Driver') 'Flutter shows the existing projects'
    Shot $f "tauri-$kind-2-flutter"
  }
  if ($kind -eq 'nsis') { $state = LauncherState; Check ($state -and $state.current -eq '1.9.1') "launcher current is 1.9.1 ($($state.current))" }
  else { $v = FileVersion (Join-Path $machineDir 'godothub.exe'); Check ($v -like '1.9.1*') "installed exe is 1.9.1 ($v)" }
}

function ExpectFailure($proc, [string]$manifest, [string]$mode, [string]$what, [string]$version) {
  CloseApp
  Serve $manifest $mode
  Start-Process (Join-Path $userDir 'godothub.exe')
  $w = AppWindow
  if (-not $w) { Check $false "$what : app opens"; return }
  if (-not (OpenUpdate $w)) { Check $false "$what : update offered"; return }
  Press $w 'Install' | Out-Null
  Start-Sleep 25
  Shot $w "fail-$($what -replace ' ', '-')"
  Check (-not [UiaCom]::Exists($w.MainWindowHandle, 'Restart Now')) "$what : no restart offered"
  Check ([UiaCom]::Dump($w.MainWindowHandle, 3000) -notmatch 'Signature verified') "$what : not reported as verified"
  $state = LauncherState
  Check ($state.current -eq $version) "$what : still on $version ($($state.current))"
  Check ((Get-Process godothub -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }).Count -ge 1) "$what : app still running"
}

function UpdateInApp([string]$manifest, [string]$what) {
  CloseApp
  Serve $manifest
  Start-Process (Join-Path $userDir 'godothub.exe')
  $w = AppWindow
  if (-not $w) { Check $false "$what : app opens"; return $null }
  Check (OpenUpdate $w) "$what : update offered"
  Press $w 'Install' | Out-Null
  Check (WaitName $w 'Restart Now' 120) "$what : download finishes"
  Shot $w "inapp-$($what -replace ' ', '-')-downloaded"
  Press $w 'Restart Now' | Out-Null
  Start-Sleep 5
  return WaitFlutterAfterUpdate 120
}

function ProjectsFile {
  $active = (Get-Content (Join-Path $roaming 'workspaces.json') -Raw | ConvertFrom-Json).active_id
  Get-Item (Join-Path $roaming "workspaces\$active\projects.json")
}

function ProjectSession([string]$id) {
  $data = Get-Content (ProjectsFile).FullName -Raw | ConvertFrom-Json
  ($data.projects | Where-Object { $_.id -eq $id }).session_started_at_ms
}

function DiskFull {
  Note "`n===== Disk full while staging 1.9.1 (launcher layout)"
  UninstallAll
  Seed
  $vhd = 'C:\godothub-small.vhdx'
  Remove-Item $vhd -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $userDir | Out-Null
  $script = Join-Path $env:TEMP 'small-disk.txt'
  Set-Content $script "create vdisk file=$vhd maximum=160 type=fixed`nselect vdisk file=$vhd`nattach vdisk`ncreate partition primary`nformat fs=ntfs quick label=small`nassign mount=$userDir"
  diskpart /s $script | Out-File (Join-Path $results 'diskpart.txt')
  $total = [Disk]::Total($userDir)
  Note "     small disk mounted at the install folder: $([int]($total / 1MB)) MB"
  if ($total -le 0 -or $total -gt 400MB) { Note '     skipped: could not attach a small virtual disk'; return }
  Check ((Run (Join-Path $Lab 'dist\1.9.0\GodotHub-1.9.0-windows-x64-setup.exe') @('/S')) -eq 0) '1.9.0 installs onto the small disk'
  $free = [Disk]::Free($userDir)
  $filler = Join-Path $userDir 'filler.bin'
  fsutil file createnew $filler ([int64]($free - 8MB)) | Out-Null
  Note "     free space left: $([int]([Disk]::Free($userDir) / 1MB)) MB"
  CloseApp
  Serve '1.9.1'
  Start-Process (Join-Path $userDir 'godothub.exe')
  $w = AppWindow
  if (-not $w) { Check $false 'disk full : app opens'; return }
  Check (OpenUpdate $w) 'disk full : update offered'
  Press $w 'Install' | Out-Null
  Start-Sleep 30
  Shot $w 'disk-full'
  Check (-not [UiaCom]::Exists($w.MainWindowHandle, 'Restart Now')) 'disk full : no restart offered'
  $state = LauncherState
  Check ($state.current -eq '1.9.0') "disk full : still on 1.9.0 ($($state.current))"
  Check (-not (Test-Path (Join-Path $userDir 'app-1.9.1'))) 'disk full : the partial 1.9.1 folder was removed'
  Check (-not $state.trial) 'disk full : nothing was activated'
  Check ((Get-Process godothub -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }).Count -ge 1) 'disk full : app still running'
  Remove-Item $filler -Force
  $f = UpdateInApp '1.9.1' 'after freeing space'
  Check ($null -ne $f) 'after freeing space : 1.9.1 starts'
  Check ((LauncherState).current -eq '1.9.1') "after freeing space : launcher current is 1.9.1 ($((LauncherState).current))"
  UninstallAll
  Set-Content $script "select vdisk file=$vhd`ndetach vdisk"
  diskpart /s $script | Out-Null
}

function GodotRunning {
  Note "`n===== Update while a Godot project is running"
  UninstallAll
  Seed
  Check ((Run (Join-Path $Lab 'dist\1.9.0\GodotHub-1.9.0-windows-x64-setup.exe') @('/S')) -eq 0) 'Flutter 1.9.0 installs'
  $fake = 'C:\fakegodot\Godot_v4.4-stable_win64.exe'
  New-Item -ItemType Directory -Force -Path (Split-Path $fake) | Out-Null
  Add-Type -TypeDefinition 'public static class FakeGodot { public static void Main() { System.Threading.Thread.Sleep(900000); } }' -OutputAssembly $fake -OutputType ConsoleApplication
  $file = ProjectsFile
  $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
  $project = $data.projects | Where-Object { $_.path -and (Test-Path (Join-Path $_.path 'project.godot')) } | Select-Object -First 1
  $before = [int64]$project.total_time_seconds
  $project.session_started_at_ms = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - 120000)
  Set-Content $file.FullName ($data | ConvertTo-Json -Depth 20)
  Start-Process $fake -ArgumentList '--editor', '--path', "`"$($project.path)`"" -WindowStyle Hidden
  Start-Sleep 2
  $godotPid = (Get-CimInstance Win32_Process -Filter "Name='Godot_v4.4-stable_win64.exe'" | Select-Object -First 1).ProcessId
  Note "     running $($project.name) in a stand-in Godot (pid $godotPid)"
  $f = UpdateInApp '1.9.1' 'with Godot running'
  Check ($null -ne $f) 'with Godot running : 1.9.1 starts'
  Check ((LauncherState).current -eq '1.9.1') "with Godot running : launcher current is 1.9.1 ($((LauncherState).current))"
  Start-Sleep 15
  Check ($null -ne (Get-Process -Id $godotPid -ErrorAction SilentlyContinue)) 'the Godot editor kept running through the update'
  Check ($null -ne (ProjectSession $project.id)) 'its play session is still tracked after the restart'
  taskkill /PID $godotPid /F | Out-Null
  for ($i = 0; $i -lt 30 -and $null -ne (ProjectSession $project.id); $i++) { Start-Sleep 2 }
  $after = (Get-Content (ProjectsFile).FullName -Raw | ConvertFrom-Json).projects | Where-Object { $_.id -eq $project.id }
  Check ($null -eq $after.session_started_at_ms) 'the session closes when Godot exits'
  Check ([int64]$after.total_time_seconds -ge $before + 100) "the time across the update was counted ($before s to $($after.total_time_seconds) s)"
  CloseApp
}

if (Test-Path (Join-Path $Lab 'extra-only.txt')) {
  DiskFull
  GodotRunning
  Note "`n$script:failures failure(s)"
  Set-Content (Join-Path $results 'done.txt') "$script:failures"
  return
}

TauriToFlutter 'nsis'
TauriToFlutter 'msi'

Note "`n===== Flutter stable 1.9.0 (launcher layout): failure cases, update, rollback"
UninstallAll
Seed
Check ((Run (Join-Path $Lab 'dist\1.9.0\GodotHub-1.9.0-windows-x64-setup.exe') @('/S')) -eq 0) 'Flutter 1.9.0 installs'
ExpectFailure $null '1.9.1' 'tamper' 'tampered package' '1.9.0'
ExpectFailure $null '1.9.1-wrong-key' 'normal' 'wrong signing key' '1.9.0'
ExpectFailure $null '1.9.1' 'drop' 'dropped download' '1.9.0'
$f = UpdateInApp '1.9.1' '1.9.0 to 1.9.1'
Check ($null -ne $f) '1.9.1 starts after restart'
Start-Sleep 10
$state = LauncherState
Check ($state.current -eq '1.9.1') "launcher current is 1.9.1 ($($state.current))"
Check (-not $state.trial) "the update was confirmed ($($state.trial))"
$kept = @((Get-ChildItem $userDir -Directory -Filter 'app-*').Name | Sort-Object)
Check (($kept -join ',') -eq 'app-1.9.0,app-1.9.1' -and $state.previous -eq '1.9.0') "only the current and previous versions are kept ($($kept -join ', '); previous $($state.previous))"
Set-Content (Join-Path $results 'launcher-after-update.json') ($state | ConvertTo-Json)

$f = UpdateInApp '1.9.2-crash' '1.9.1 to crashing 1.9.2'
Start-Sleep 15
$state = LauncherState
Set-Content (Join-Path $results 'launcher-after-rollback.json') ($state | ConvertTo-Json)
Check ($state.current -eq '1.9.1') "rolled back to 1.9.1 ($($state.current), failed $($state.failed))"
$w = AppWindow 60
Check ($w -and (IsFlutter $w)) 'a working GodotHub window is open after the rollback'
if (-not $w) {
  Start-Process (Join-Path $userDir 'godothub.exe')
  $w = AppWindow
  Check ($w -and (IsFlutter $w)) 'GodotHub opens on the next launch after the rollback'
}
if ($w) { Shot $w 'rollback-flutter' }

Note "`n===== Flutter stable 1.9.0 MSI to 1.9.1 through msiexec"
UninstallAll
Seed
Check ((Run msiexec @('/i', (Join-Path $Lab 'dist\1.9.0\GodotHub-1.9.0-windows-x64.msi'), '/qn')) -eq 0) 'Flutter 1.9.0 MSI installs'
CloseApp
Serve '1.9.1'
Start-Process (Join-Path $machineDir 'godothub.exe')
$w = AppWindow
if ($w) {
  Check (OpenUpdate $w) 'MSI install is offered 1.9.1'
  Press $w 'Install' | Out-Null
  Check (WaitName $w 'Restart Now' 120) 'MSI download finishes'
  Press $w 'Restart Now' | Out-Null
  for ($i = 0; $i -lt 90 -and (FileVersion (Join-Path $machineDir 'godothub.exe')) -notlike '1.9.1*'; $i++) { Start-Sleep 2 }
  Start-Sleep 5
  $f = WaitFlutterAfterUpdate 240
  Check ($null -ne $f) 'GodotHub starts again after msiexec'
  $v = FileVersion (Join-Path $machineDir 'godothub.exe')
  Check ($v -like '1.9.1*') "installed exe is 1.9.1 ($v)"
  if ($f) { Shot $f 'msi-after' }
} else { Check $false 'Flutter MSI opens' }

DiskFull
GodotRunning

Get-Content (Join-Path $results 'server.log') -ErrorAction SilentlyContinue | Select-Object -Last 40 | ForEach-Object { Note "     server: $_" }
Note "`n$script:failures failure(s)"
Set-Content (Join-Path $results 'done.txt') "$script:failures"
