$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'README.md',
    'CURRICULUM.md',
    'lesson-01/README.md',
    'lesson-01/manifests/namespace.yaml',
    'lesson-01/manifests/pod.yaml',
    'lesson-01/scripts/check-environment.ps1'
)

function Assert-Match {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$Message
    )

    if ($Content -notmatch $Pattern) {
        throw $Message
    }
}

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "필수 파일이 없습니다: $relativePath"
    }
}
Write-Host '[PASS] 필수 파일 확인'

$namespaceManifest = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'lesson-01/manifests/namespace.yaml')
Assert-Match $namespaceManifest '(?m)^apiVersion:\s+v1\s*$' 'Namespace apiVersion은 v1이어야 합니다.'
Assert-Match $namespaceManifest '(?m)^kind:\s+Namespace\s*$' 'Namespace kind가 없습니다.'
Assert-Match $namespaceManifest '(?m)^\s{2}name:\s+k8s-study\s*$' 'Namespace 이름은 k8s-study여야 합니다.'
Write-Host '[PASS] Namespace 매니페스트 구조 확인'

$podManifest = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'lesson-01/manifests/pod.yaml')
Assert-Match $podManifest '(?m)^apiVersion:\s+v1\s*$' 'Pod apiVersion은 v1이어야 합니다.'
Assert-Match $podManifest '(?m)^kind:\s+Pod\s*$' 'Pod kind가 없습니다.'
Assert-Match $podManifest '(?m)^\s{2}name:\s+web\s*$' 'Pod 이름은 web이어야 합니다.'
Assert-Match $podManifest '(?m)^\s{2}namespace:\s+k8s-study\s*$' 'Pod namespace는 k8s-study여야 합니다.'
Assert-Match $podManifest '(?m)^\s{6}image:\s+nginx:[^\s]+\s*$' 'nginx 이미지 태그를 명시해야 합니다.'
Assert-Match $podManifest '(?m)^\s{10}containerPort:\s+80\s*$' '컨테이너 포트 80이 필요합니다.'
Write-Host '[PASS] Pod 매니페스트 구조 확인'

$lesson = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'lesson-01/README.md')
foreach ($commandText in @('kubectl apply', 'kubectl get', 'kubectl describe', 'kubectl logs', 'kubectl delete')) {
    if (-not $lesson.Contains($commandText)) {
        throw "1강 문서에 필수 명령이 없습니다: $commandText"
    }
}
Write-Host '[PASS] 1강 핵심 실습 흐름 확인'

$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue
if ($null -eq $kubectl) {
    Write-Host '[SKIP] kubectl 미설치: client dry-run은 환경 준비 후 실행됩니다.' -ForegroundColor Yellow
}
else {
    & kubectl apply --dry-run=client --validate=false -f (Join-Path $repositoryRoot 'lesson-01/manifests/namespace.yaml') *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Namespace kubectl client dry-run에 실패했습니다.' }

    & kubectl apply --dry-run=client --validate=false -f (Join-Path $repositoryRoot 'lesson-01/manifests/pod.yaml') *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Pod kubectl client dry-run에 실패했습니다.' }
    Write-Host '[PASS] kubectl client dry-run'
}

Write-Host '모든 실행 가능한 검증을 통과했습니다.' -ForegroundColor Green
