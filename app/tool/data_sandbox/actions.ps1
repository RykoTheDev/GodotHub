function FlutterChanges($proc, [string]$dataset) {
  ClickAt $proc 140 182
  ClickAt $proc 900 330 1000
  ClickAt $proc 560 411
  Shot $proc "$dataset-b-flutter-9-pinned"
  ClickAt $proc 245 734
  ClickAt $proc 667 593
  Shot $proc "$dataset-b-flutter-10-light-theme"
  ClickAt $proc 371 574
  Shot $proc "$dataset-b-flutter-11-advanced"
  ClickAt $proc 1374 414 9000
  Shot $proc "$dataset-b-flutter-12-update-check"
  ClickAt $proc 60 60
  ClickAt $proc 378 484
  Shot $proc "$dataset-b-flutter-13-integrations"
  ClickAt $proc 140 182

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
