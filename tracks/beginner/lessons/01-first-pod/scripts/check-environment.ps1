$ErrorActionPreference = 'Stop'

$requiredCommands = @('docker', 'kubectl', 'kind')
$hasFailure = $false

foreach ($commandName in $requiredCommands) {
    $command = Get-Command $commandName -ErrorAction SilentlyContinue

    if ($null -eq $command) {
        Write-Host "[MISSING] $commandName" -ForegroundColor Red
        $hasFailure = $true
    }
    else {
        Write-Host "[OK] $commandName - $($command.Source)" -ForegroundColor Green
    }
}

if ($hasFailure) {
    Write-Host ''
    Write-Host '필수 도구를 설치한 뒤 새 PowerShell 창에서 다시 실행하세요.' -ForegroundColor Yellow
    exit 1
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host '[FAILED] Docker Desktop을 시작하고 엔진이 준비될 때까지 기다리세요.' -ForegroundColor Red
    exit 1
}
Write-Host '[OK] Docker engine is running' -ForegroundColor Green

Write-Host ''
Write-Host '실습 환경이 준비되었습니다.' -ForegroundColor Green
