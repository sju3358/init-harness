#!/bin/sh
# 공용 훅 도우미. 각 훅에서 `. "$(dirname "$0")/lib.sh"`로 불러 사용

# Windows Git sh를 비로그인으로 실행하면(Claude Code 훅) PATH에서 C:\Windows\System32의 find·sort가 /usr/bin보다 먼저 잡힘
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) PATH="/usr/bin:$PATH" ;;
esac

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# 도구 입력 경로를 저장소 기준 상대 경로로 출력. 저장소 밖 절대 경로면 빈 값
# Windows는 역슬래시·드라이브 문자 대소문자·/d/ 형식이 섞여 들어오므로 cygpath로 맞춘 뒤 대소문자 무시로 비교
rel_path() {
  p=$1
  root=$(repo_root)
  if command -v cygpath >/dev/null 2>&1; then
    p=$(cygpath -m "$p")
    root=$(cygpath -m "$root")
  fi
  case "$p" in
    /*|[A-Za-z]:/*)
      printf '%s\n%s\n' "$root" "$p" | awk '
        NR == 1 { r = tolower($0) "/"; next }
        index(tolower($0), r) == 1 { print substr($0, length(r) + 1) }' ;;
    *) printf '%s' "${p#./}" ;;
  esac
}

# 훅 입력 JSON 해석에 jq가 필요. 없으면 입력을 빈 값으로 읽어 모든 게이트가 조용히 통과하므로 차단
require_jq() {
  command -v jq >/dev/null 2>&1 \
    || deny "jq 미설치로 하네스 훅이 동작하지 않음. 사용자가 설치 후 세션 재시작 (Windows: winget install jqlang.jq, macOS: brew install jq)"
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

# 표준 입력의 SHA-256. Windows Git sh는 비로그인 셸이면 shasum(/usr/bin/core_perl)이 PATH에 없어 sha256sum으로 대체
# 둘 다 없으면 빈 값
sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi 2>/dev/null | cut -d' ' -f1
}

# 요구사항·PRD·API 문서 내용 해시. 상태 줄은 승인 후 갱신되므로 제외
prd_hash() {
  root=$(repo_root)
  find "$root/docs/requirements.md" "$root/docs/prd" "$root/docs/api" -name '*.md' ! -name '_template.md' 2>/dev/null \
    | LC_ALL=C sort \
    | while read -r f; do printf '%s\n' "${f#"$root"/}"; grep -v '^- 상태:' "$f"; done \
    | sha256
}

# .harness/paths 목록에 속한 경로인지
is_harness_path() {
  while IFS= read -r p; do
    p=${p%"$(printf '\r')"}
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
