#!/bin/sh
# 공용 훅 도우미. 각 훅에서 `. "$(dirname "$0")/lib.sh"`로 불러 사용

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

state_dir() {
  printf '%s/.harness/state' "$(repo_root)"
}

# 브랜치명의 `/`를 파일명에 쓸 수 있게 `_`로 치환
branch_key() {
  printf '%s' "$1" | tr '/' '_'
}

# docs/project.md의 "- 통합 브랜치: X" 값, 없으면 develop
integration_branch() {
  b=$(sed -n 's/^- 통합 브랜치:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$(repo_root)/docs/project.md" 2>/dev/null | head -n 1)
  printf '%s' "${b:-develop}"
}

is_protected_branch() {
  case "$1" in
    main|master) return 0 ;;
  esac
  [ "$1" = "$(integration_branch)" ]
}

is_work_branch() {
  printf '%s' "$1" | grep -qE '^(feat|fix|docs)/ITD-[0-9]+$'
}

# 커밋 메시지·heredoc 본문을 명령으로 오인하지 않도록 heredoc 본문과 따옴표 문자열을 지운 실행 구문
# sh -c "..." 안의 명령도 함께 지워져 통과하지만 실수 방지용 훅이라 허용
strip_cmd() {
  printf '%s\n' "$1" | awk '
    in_doc { if ($0 ~ "^[ \t]*" delim "[ \t]*$") in_doc = 0; next }
    {
      print
      if (match($0, /<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/)) {
        d = substr($0, RSTART, RLENGTH)
        sub(/^<<-?[ \t]*["\047]?/, "", d); sub(/["\047]$/, "", d)
        delim = d; in_doc = 1
      }
    }' | tr '\n' '\036' | sed -e 's/"[^"]*"//g' -e "s/'[^']*'//g" | tr '\036' '\n'
}

# 요구사항·PRD·API 문서 내용 해시. 상태 줄은 승인 후 갱신되므로 제외
prd_hash() {
  root=$(repo_root)
  find "$root/docs/requirements.md" "$root/docs/prd" "$root/docs/api" -name '*.md' ! -name '_template.md' 2>/dev/null \
    | LC_ALL=C sort \
    | while read -r f; do printf '%s\n' "${f#"$root"/}"; grep -v '^- 상태:' "$f"; done \
    | shasum -a 256 | cut -d' ' -f1
}

# .harness/paths 목록에 속한 경로인지
is_harness_path() {
  while IFS= read -r p; do
    case "$p" in
      ''|'#'*) continue ;;
      */) case "$1" in "$p"*) return 0 ;; esac ;;
      *) [ "$1" = "$p" ] && return 0 ;;
    esac
  done < "$(repo_root)/.harness/paths"
  return 1
}

# `하네스 도입 승인` 기록이 30분 내이고 승인 시점 브랜치가 지금 브랜치와 같은지
adopt_approved() {
  f="$(state_dir)/adopt-approved"
  [ -f "$f" ] && [ -n "$(find "$f" -mmin -30 2>/dev/null)" ] && [ "$(cat "$f")" = "$1" ]
}

deny() {
  echo "차단: $1" >&2
  exit 2
}

# `하네스 OFF` 기록이 있으면 이 파일을 불러온 훅 전체 통과. `하네스 ON`으로 해제
# record-approval.sh는 OFF 중에도 `하네스 ON`을 받아야 하므로 제외
[ "${0##*/}" != record-approval.sh ] && [ -f "$(state_dir)/harness-off" ] && exit 0
