function FlutterChanges($proc, [string]$dataset) {
  Press $proc 'Projects' 140 182
  ClickAt $proc 900 330 1000
  ClickAt $proc 560 411
  Shot $proc "$dataset-b-flutter-9-pinned"
  Press $proc 'Settings' 245 734
  Press $proc 'Light' 667 593
  Shot $proc "$dataset-b-flutter-10-light-theme"
  Press $proc 'Advanced' 371 574
  Shot $proc "$dataset-b-flutter-11-advanced"
  Press $proc 'Check for Updates' 1374 414 9000
  Shot $proc "$dataset-b-flutter-12-update-check"
  Keys $proc '{ESC}'
  Press $proc 'Integrations' 378 484
  Shot $proc "$dataset-b-flutter-13-integrations"
  Press $proc 'Projects' 140 182

  $before = @(Get-Process godothub -ErrorAction SilentlyContinue).Count
  $second = Start-Process $exe -PassThru
  $second.WaitForExit(15000) | Out-Null
  Check $second.HasExited "a second launch exits (single instance), code $($second.ExitCode)"
  Check ((AppWindows).Count -eq 1) "still one window after the second launch (got $((AppWindows).Count))"
  Note "     godothub processes before/after: $before/$(@(Get-Process godothub -ErrorAction SilentlyContinue).Count)"

  $tray = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
    [System.Windows.Automation.TreeScope]::Descendants,
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
  $names = @($tray | ForEach-Object { $_.Current.Name } | Where-Object { $_ -like '*GodotHub*' })
  Note "     buttons named GodotHub on the desktop: $($names -join ' ; ')"
}
