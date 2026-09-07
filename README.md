# Kubernetes 실습 스터디

로컬 클러스터에서 직접 실행하며 익히는 트랙 기반 Kubernetes 실습 저장소입니다. 각 트랙은 독립적인 목표와 선수 지식을 가지며, 강의는 **개념 확인 → 실행 → 관찰 → 고장 내기/복구 → 정리** 순서로 진행합니다.

## 학습 트랙

| 트랙 | 대상 | 상태 | 시작하기 |
|---|---|---|---|
| Beginner | Kubernetes 입문자 | 진행 중 | [트랙 안내](tracks/beginner/README.md) |

향후 `cka`, `operations`, `platform-engineering` 등의 트랙을 `tracks/<track-name>` 아래에 서로 독립적으로 추가할 수 있습니다.

## 저장소 운영 방식

- `main`에는 검증과 PR을 통과한 강의만 둡니다.
- 트랙은 `tracks/<track-name>`으로, 강의는 그 아래 `lessons/<번호>-<주제>`로 구분합니다.
- 새 강의는 최신 `main`에서 짧은 작업 브랜치를 만든 뒤 PR로 추가합니다.
- 학습자의 개인 진도는 저장소 파일 대신 GitHub Issue 또는 Project에서 관리합니다.
- 강의 추가 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md)를 따릅니다.

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

검사는 트랙 인덱스, 필수 강의 파일, 매니페스트의 핵심 구조를 확인합니다. `kubectl`이 설치되어 있으면 클라이언트 dry-run 검사도 추가로 수행합니다.
