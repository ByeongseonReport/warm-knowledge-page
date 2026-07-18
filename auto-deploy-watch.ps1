# warm-knowledge-page 자동 배포 워처
# index.html이 바뀌면 push.ps1(git add/commit/push)을 자동 실행한다.
# 생성기가 무엇이든/언제든 상관없이 "파일이 바뀌는 순간" 배포되게 하는 이벤트 기반 방식.
# WarmKnowledgeAutoDeploy 예약 작업(로그온 시 시작)으로 상시 구동됨.

$ErrorActionPreference = 'Continue'
$dir  = 'C:\Users\PC\Documents\claude cowork\warm-knowledge-page'
$file = 'index.html'
$push = Join-Path $dir 'push.ps1'
$log  = Join-Path $dir 'auto-deploy.log'

function Log([string]$m) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Out-File -FilePath $log -Append -Encoding utf8
}

function Deploy([string]$reason) {
    Log "deploy 트리거 ($reason)"
    try {
        $out = & $push 2>&1 | Out-String
        Log ("push.ps1 결과: " + ($out.Trim() -replace '\s*\r?\n\s*', ' | '))
    } catch {
        Log ("ERROR: " + $_.Exception.Message)
    }
}

Log "=== 워처 시작 ==="
# 시작 시 1회: PC가 꺼져있던 사이 생성된(미커밋) 변경분을 즉시 반영
Deploy "startup catch-up"

$w = New-Object System.IO.FileSystemWatcher
$w.Path   = $dir
$w.Filter = $file
$w.NotifyFilter = [System.IO.NotifyFilters]'LastWrite,Size,FileName,CreationTime'
$w.IncludeSubdirectories = $false
$w.EnableRaisingEvents = $true

while ($true) {
    # index.html 변경을 최대 30분 대기 (타임아웃되면 재무장)
    $r = $w.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1800000)
    if ($r.TimedOut) { continue }

    # 디바운스: 생성기가 여러 번 쓰는 동안 기다렸다가, 조용해지면 배포
    Start-Sleep -Seconds 15
    do {
        $r2 = $w.WaitForChanged([System.IO.WatcherChangeTypes]::All, 4000)
    } while (-not $r2.TimedOut)

    Deploy "index.html 변경 감지"
}
