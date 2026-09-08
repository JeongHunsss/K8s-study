#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lesson_root="$repository_root/tracks/beginner/lessons/01-first-pod"

required_files=(
  README.md
  CONTRIBUTING.md
  .gitattributes
  .github/pull_request_template.md
  .github/workflows/validate.yml
  tracks/beginner/README.md
  tracks/beginner/CURRICULUM.md
  tracks/beginner/lessons/01-first-pod/README.md
  tracks/beginner/lessons/01-first-pod/manifests/namespace.yaml
  tracks/beginner/lessons/01-first-pod/manifests/pod.yaml
  tracks/beginner/lessons/01-first-pod/scripts/check-environment.sh
)

for relative_path in "${required_files[@]}"; do
  [[ -f "$repository_root/$relative_path" ]] || {
    printf '필수 파일이 없습니다: %s\n' "$relative_path" >&2
    exit 1
  }
done
printf '[PASS] 필수 파일 확인\n'

shopt -s nullglob
track_directories=("$repository_root"/tracks/*/)
((${#track_directories[@]} > 0)) || {
  printf 'tracks 아래에 하나 이상의 트랙이 필요합니다.\n' >&2
  exit 1
}

for track_directory in "${track_directories[@]}"; do
  [[ -f "$track_directory/README.md" ]] || {
    printf '트랙 README가 없습니다: %s\n' "$track_directory" >&2
    exit 1
  }
  [[ -f "$track_directory/CURRICULUM.md" ]] || {
    printf '트랙 커리큘럼이 없습니다: %s\n' "$track_directory" >&2
    exit 1
  }
  [[ -d "$track_directory/lessons" ]] || {
    printf '트랙에 lessons 디렉터리가 없습니다: %s\n' "$track_directory" >&2
    exit 1
  }

  lesson_directories=("$track_directory"/lessons/*/)
  ((${#lesson_directories[@]} > 0)) || {
    printf '트랙에 하나 이상의 강의가 필요합니다: %s\n' "$track_directory" >&2
    exit 1
  }

  for lesson_directory in "${lesson_directories[@]}"; do
    lesson_name="$(basename "$lesson_directory")"
    [[ "$lesson_name" =~ ^[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$ ]] || {
      printf '강의 디렉터리 이름은 NN-kebab-case 형식이어야 합니다: %s\n' "$lesson_name" >&2
      exit 1
    }
    [[ -f "$lesson_directory/README.md" ]] || {
      printf '강의 README가 없습니다: %s\n' "$lesson_directory" >&2
      exit 1
    }
  done
done
printf '[PASS] 트랙/강의 디렉터리 규칙 확인\n'

namespace_manifest="$lesson_root/manifests/namespace.yaml"
grep -Eq '^apiVersion:[[:space:]]+v1[[:space:]]*$' "$namespace_manifest"
grep -Eq '^kind:[[:space:]]+Namespace[[:space:]]*$' "$namespace_manifest"
grep -Eq '^  name:[[:space:]]+k8s-study[[:space:]]*$' "$namespace_manifest"
printf '[PASS] Namespace 매니페스트 구조 확인\n'

pod_manifest="$lesson_root/manifests/pod.yaml"
grep -Eq '^apiVersion:[[:space:]]+v1[[:space:]]*$' "$pod_manifest"
grep -Eq '^kind:[[:space:]]+Pod[[:space:]]*$' "$pod_manifest"
grep -Eq '^  name:[[:space:]]+web[[:space:]]*$' "$pod_manifest"
grep -Eq '^  namespace:[[:space:]]+k8s-study[[:space:]]*$' "$pod_manifest"
grep -Eq '^      image:[[:space:]]+nginx:[^[:space:]]+[[:space:]]*$' "$pod_manifest"
grep -Eq '^          containerPort:[[:space:]]+80[[:space:]]*$' "$pod_manifest"
printf '[PASS] Pod 매니페스트 구조 확인\n'

lesson_readme="$lesson_root/README.md"
for command_text in 'kubectl apply' 'kubectl get' 'kubectl describe' 'kubectl logs' 'kubectl delete'; do
  grep -Fq "$command_text" "$lesson_readme" || {
    printf '1강 문서에 필수 명령이 없습니다: %s\n' "$command_text" >&2
    exit 1
  }
done
printf '[PASS] 1강 핵심 실습 흐름 확인\n'

if ! command -v kubectl >/dev/null 2>&1; then
  printf '[SKIP] kubectl 미설치: client dry-run은 환경 준비 후 실행됩니다.\n'
elif ! kubectl_context="$(kubectl config current-context 2>/dev/null)" || [[ -z "$kubectl_context" ]]; then
  printf '[SKIP] kubectl 컨텍스트 없음: 클러스터 준비 후 client dry-run을 실행합니다.\n'
else
  kubectl apply --dry-run=client --validate=false -f "$namespace_manifest" >/dev/null
  kubectl apply --dry-run=client --validate=false -f "$pod_manifest" >/dev/null
  printf '[PASS] kubectl client dry-run (%s)\n' "$kubectl_context"
fi

printf '모든 실행 가능한 검증을 통과했습니다.\n'
