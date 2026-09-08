#!/usr/bin/env bash

set -uo pipefail

required_commands=(docker kubectl kind curl)
has_failure=0

for command_name in "${required_commands[@]}"; do
  if command_path="$(command -v "$command_name" 2>/dev/null)"; then
    printf '[OK] %s - %s\n' "$command_name" "$command_path"
  else
    printf '[MISSING] %s\n' "$command_name" >&2
    has_failure=1
  fi
done

if ((has_failure)); then
  printf '\n필수 도구를 설치한 뒤 새 Git Bash 창에서 다시 실행하세요.\n' >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  printf '[FAILED] Docker Desktop을 시작하고 엔진이 준비될 때까지 기다리세요.\n' >&2
  exit 1
fi

printf '[OK] Docker engine is running\n\n'
printf 'Git Bash 실습 환경이 준비되었습니다.\n'
