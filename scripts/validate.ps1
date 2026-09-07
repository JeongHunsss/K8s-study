$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'README.md',
    'CONTRIBUTING.md',
    '.github/pull_request_template.md',
    '.github/workflows/validate.yml',
    'tracks/beginner/README.md',
    'tracks/beginner/CURRICULUM.md',
    'tracks/beginner/lessons/01-first-pod/README.md',
    'tracks/beginner/lessons/01-first-pod/manifests/namespace.yaml',
    'tracks/beginner/lessons/01-first-pod/manifests/pod.yaml',
    'tracks/beginner/lessons/01-first-pod/scripts/check-environment.ps1'
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

$tracksRoot = Join-Path $repositoryRoot 'tracks'
$trackDirectories = @(Get-ChildItem -LiteralPath $tracksRoot -Directory)
if ($trackDirectories.Count -eq 0) {
    throw 'tracks 아래에 하나 이상의 트랙이 필요합니다.'
}

foreach ($trackDirectory in $trackDirectories) {
    foreach ($trackFile in @('README.md', 'CURRICULUM.md')) {
        $trackFilePath = Join-Path $trackDirectory.FullName $trackFile
        if (-not (Test-Path -LiteralPath $trackFilePath -PathType Leaf)) {
            throw "트랙 필수 파일이 없습니다: tracks/$($trackDirectory.Name)/$trackFile"
        }
    }

    $lessonsRoot = Join-Path $trackDirectory.FullName 'lessons'
    if (-not (Test-Path -LiteralPath $lessonsRoot -PathType Container)) {
        throw "트랙에 lessons 디렉터리가 없습니다: tracks/$($trackDirectory.Name)"
    }

    $lessonDirectories = @(Get-ChildItem -LiteralPath $lessonsRoot -Directory)
    if ($lessonDirectories.Count -eq 0) {
        throw "트랙에 하나 이상의 강의가 필요합니다: tracks/$($trackDirectory.Name)"
    }

    foreach ($lessonDirectory in $lessonDirectories) {
        if ($lessonDirectory.Name -notmatch '^\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*$') {
            throw "강의 디렉터리 이름은 NN-kebab-case 형식이어야 합니다: $($lessonDirectory.Name)"
        }

        $lessonReadme = Join-Path $lessonDirectory.FullName 'README.md'
        if (-not (Test-Path -LiteralPath $lessonReadme -PathType Leaf)) {
            throw "강의 README가 없습니다: $($lessonDirectory.FullName)"
        }
    }
}
Write-Host '[PASS] 트랙/강의 디렉터리 규칙 확인'

$namespaceManifest = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'tracks/beginner/lessons/01-first-pod/manifests/namespace.yaml')
Assert-Match $namespaceManifest '(?m)^apiVersion:\s+v1\s*$' 'Namespace apiVersion은 v1이어야 합니다.'
Assert-Match $namespaceManifest '(?m)^kind:\s+Namespace\s*$' 'Namespace kind가 없습니다.'
Assert-Match $namespaceManifest '(?m)^\s{2}name:\s+k8s-study\s*$' 'Namespace 이름은 k8s-study여야 합니다.'
Write-Host '[PASS] Namespace 매니페스트 구조 확인'

$podManifest = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'tracks/beginner/lessons/01-first-pod/manifests/pod.yaml')
Assert-Match $podManifest '(?m)^apiVersion:\s+v1\s*$' 'Pod apiVersion은 v1이어야 합니다.'
Assert-Match $podManifest '(?m)^kind:\s+Pod\s*$' 'Pod kind가 없습니다.'
Assert-Match $podManifest '(?m)^\s{2}name:\s+web\s*$' 'Pod 이름은 web이어야 합니다.'
Assert-Match $podManifest '(?m)^\s{2}namespace:\s+k8s-study\s*$' 'Pod namespace는 k8s-study여야 합니다.'
Assert-Match $podManifest '(?m)^\s{6}image:\s+nginx:[^\s]+\s*$' 'nginx 이미지 태그를 명시해야 합니다.'
Assert-Match $podManifest '(?m)^\s{10}containerPort:\s+80\s*$' '컨테이너 포트 80이 필요합니다.'
Write-Host '[PASS] Pod 매니페스트 구조 확인'

$lesson = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot 'tracks/beginner/lessons/01-first-pod/README.md')
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
    $kubectlContext = & kubectl config current-context 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($kubectlContext)) {
        Write-Host '[SKIP] kubectl 컨텍스트 없음: 클러스터 준비 후 client dry-run을 실행합니다.' -ForegroundColor Yellow
    }
    else {
        & kubectl apply --dry-run=client --validate=false -f (Join-Path $repositoryRoot 'tracks/beginner/lessons/01-first-pod/manifests/namespace.yaml') *> $null
        if ($LASTEXITCODE -ne 0) { throw 'Namespace kubectl client dry-run에 실패했습니다.' }

        & kubectl apply --dry-run=client --validate=false -f (Join-Path $repositoryRoot 'tracks/beginner/lessons/01-first-pod/manifests/pod.yaml') *> $null
        if ($LASTEXITCODE -ne 0) { throw 'Pod kubectl client dry-run에 실패했습니다.' }
        Write-Host "[PASS] kubectl client dry-run ($kubectlContext)"
    }
}

Write-Host '모든 실행 가능한 검증을 통과했습니다.' -ForegroundColor Green
