# warm-knowledge-page auto-deploy watcher
# When index.html changes, run push.ps1 (git add/commit/push) automatically.
# Event-driven: deploys the moment the file changes, regardless of what/when generated it.
# Runs continuously via the WarmKnowledgeAutoDeploy scheduled task (at logon).
# (Log messages kept ASCII on purpose: PS 5.1 mangles non-ASCII in BOM-less .ps1.)

$ErrorActionPreference = 'Continue'
$dir  = 'C:\Users\PC\Documents\claude cowork\warm-knowledge-page'
$file = 'index.html'
$push = Join-Path $dir 'push.ps1'
$log  = Join-Path $dir 'auto-deploy.log'

function Log([string]$m) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File -FilePath $log -Append -Encoding utf8
}

function Deploy([string]$reason) {
    Log "deploy triggered ($reason)"
    try {
        $out = & $push 2>&1 | Out-String
        Log ("push.ps1 -> " + ($out.Trim() -replace '\s*\r?\n\s*', ' | '))
    } catch {
        Log ("ERROR: " + $_.Exception.Message)
    }
}

Log "=== watcher started ==="
# On startup: deploy once to catch any pending (uncommitted) change made while the watcher was down.
Deploy "startup catch-up"

$w = New-Object System.IO.FileSystemWatcher
$w.Path   = $dir
$w.Filter = $file
$w.NotifyFilter = [System.IO.NotifyFilters]'LastWrite,Size,FileName,CreationTime'
$w.IncludeSubdirectories = $false
$w.EnableRaisingEvents = $true

while ($true) {
    # Wait up to 30 min for an index.html change (re-arm on timeout).
    $r = $w.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1800000)
    if ($r.TimedOut) { continue }

    # Debounce: let the generator finish writing, then deploy once it's quiet.
    Start-Sleep -Seconds 15
    do {
        $r2 = $w.WaitForChanged([System.IO.WatcherChangeTypes]::All, 4000)
    } while (-not $r2.TimedOut)

    Deploy "index.html changed"
}
