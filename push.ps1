Set-Location "C:\Users\PC\Documents\claude cowork\warm-knowledge-page"
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    $msg = "콘텐츠 자동 갱신 " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    git commit -m $msg
    git push origin main
    Write-Output "커밋 및 푸시 완료: $msg"
} else {
    Write-Output "변경사항 없음, 커밋 스킵"
}
