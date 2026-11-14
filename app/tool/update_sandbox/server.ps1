param([string]$Lab = 'C:\lab', [int]$Port = 47821)

$serve = Join-Path $Lab 'serve'
$log = Join-Path $Lab 'results\server.log'
New-Item -ItemType Directory -Force -Path $serve, (Split-Path $log) | Out-Null
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Add-Content $log "listening on $Port"

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
  $modeFile = Join-Path $serve 'mode.txt'
  $mode = if (Test-Path $modeFile) { (Get-Content $modeFile -Raw).Trim() } else { 'normal' }
  $file = if ($path -eq 'latest-v2.json') { Join-Path $serve 'latest-v2.json' } else { Join-Path (Join-Path $Lab 'dist') ($path -replace '/', '\') }
  $response = $context.Response
  try {
    if (-not (Test-Path $file -PathType Leaf)) {
      $response.StatusCode = 404
      Add-Content $log "404 $path"
      $response.Close()
      continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $package = $path -ne 'latest-v2.json'
    if ($package -and $mode -eq 'tamper') { $bytes[[int]($bytes.Length / 2)] = $bytes[[int]($bytes.Length / 2)] -bxor 0xFF }
    $response.ContentLength64 = $bytes.Length
    if ($package -and $mode -eq 'drop') {
      $response.OutputStream.Write($bytes, 0, [int]($bytes.Length / 2))
      $response.OutputStream.Flush()
      $response.Abort()
      Add-Content $log "dropped $path at half"
      continue
    }
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.Close()
    Add-Content $log "200 $path ($mode, $($bytes.Length) bytes)"
  } catch {
    Add-Content $log "error $path $_"
    try { $response.Abort() } catch {}
  }
}
