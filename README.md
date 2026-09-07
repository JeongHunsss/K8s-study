# Kubernetes 실습 스터디

쿠버네티스를 처음 접하는 학습자가 로컬 클러스터에서 직접 실행하며 익히는 실습형 저장소입니다. 각 강의는 **개념 확인 → 실행 → 관찰 → 고장 내기/복구 → 정리** 순서로 진행합니다.

## 학습 순서

- 전체 과정과 권장 진도: [CURRICULUM.md](CURRICULUM.md)
- 1강 실습: [첫 Pod 실행하기](lesson-01/README.md)

## 기본 실습 환경

- Windows 11 + PowerShell 7 기준으로 명령 예시 제공
- Docker Desktop
- kubectl
- kind
- Git

macOS와 Linux에서도 동일한 `kubectl`, `kind` 명령을 사용할 수 있습니다. 설치 방법은 각 도구의 공식 문서를 따릅니다.

## 저장소 검증

PowerShell에서 다음 명령을 실행합니다.

```powershell
./scripts/validate.ps1
```

검사는 필수 파일과 1강 매니페스트의 핵심 구조를 확인합니다. `kubectl`이 설치되어 있으면 클라이언트 dry-run 검사도 추가로 수행합니다.
