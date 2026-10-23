#!/bin/sh
# 요구사항 추적 누락을 기계적으로 검사. 판정(내용이 맞는지)은 하지 않고 ID 연결 여부만 확인
#
# 사용법:
#   sh scripts/check-trace.sh prd          요구사항 ↔ PRD·API 문서 ↔ feature 목록
#   sh scripts/check-trace.sh feature F-01 feature 명세·API ↔ PLAN.md ↔ 테스트 코드
#
# 문제가 하나라도 있으면 exit 1

set -u
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$root" || exit 2

problems=0
report() {
  echo "[$1] $2"
  problems=$((problems + 1))
}

ids_in() {
  # $1: 정규식, 나머지: 파일. 존재하는 파일에서 ID만 중복 없이 출력
  pattern=$1
  shift
  for f in "$@"; do [ -f "$f" ] && grep -ohE "$pattern" "$f"; done | LC_ALL=C sort -u
}

contains() {
  printf '%s\n' "$1" | grep -qx "$2"
}

prd_files() {
  find docs/prd docs/api -name '*.md' ! -name '_template.md' 2>/dev/null | LC_ALL=C sort
}

# docs/api 엔드포인트 색인: "API-ID|feature|REQ 인용 여부(1/0)" 한 줄씩
api_index() {
  for file in docs/api/*.md; do
    [ -f "$file" ] || continue
    [ "$(basename "$file")" = _template.md ] && continue
    awk '
      function flush() { if (id != "") print id "|" feat "|" req }
      /^#{2,4}[ \t]+API-[0-9]+[ \t]/ { flush(); id = $2; feat = ""; req = 0; next }
      /^#{1,4}[ \t]/ { flush(); id = ""; next }
      id != "" && /^- feature:/ { if (match($0, /F-[0-9]+/)) feat = substr($0, RSTART, RLENGTH) }
      id != "" && /^- 요구사항:/ && /REQ-[0-9]+/ { req = 1 }
      END { flush() }' "$file"
  done
}

check_prd() {
  req_file=docs/requirements.md
  [ -f "$req_file" ] || { echo "docs/requirements.md 없음"; exit 2; }

  # 요구사항 표의 첫 칸 ID. 마지막 칸(상태)이 `삭제`인 행은 삭제로 분류
  defined=$(grep -E '^\| *REQ-[0-9]+ *\|' "$req_file" | sed -E 's/^\| *(REQ-[0-9]+).*/\1/' | LC_ALL=C sort -u)
  deleted=$(grep -E '^\| *REQ-[0-9]+ *\|' "$req_file" | grep -E '\| *삭제 *\| *$' | sed -E 's/^\| *(REQ-[0-9]+).*/\1/' | LC_ALL=C sort -u)
  active=$(for id in $defined; do contains "$deleted" "$id" || echo "$id"; done)

  # shellcheck disable=SC2046
  used=$(ids_in 'REQ-[0-9]+' $(prd_files))

  for id in $active; do
    contains "$used" "$id" || report "PRD 미반영" "$id: docs/prd/·docs/api/ 어디에도 없음"
  done
  for id in $used; do
    contains "$defined" "$id" || report "정의 없음" "$id: PRD에서 인용하지만 requirements.md에 없음"
    contains "$deleted" "$id" && report "삭제된 요구사항" "$id: 삭제 상태인데 PRD에서 인용"
  done

  features=$(grep -E '^\| *F-[0-9]+ *\|' docs/prd/00-overview.md 2>/dev/null | sed -E 's/^\| *(F-[0-9]+).*/\1/' | LC_ALL=C sort -u)
  [ -n "$features" ] || report "feature 없음" "docs/prd/00-overview.md feature 목록이 비어 있음"
  for f in $features; do
    [ -f "docs/prd/features/$f.md" ] || report "명세 없음" "$f: docs/prd/features/$f.md 없음"
  done
  for file in docs/prd/features/F-*.md; do
    [ -f "$file" ] || continue
    f=$(basename "$file" .md)
    contains "$features" "$f" || report "목록 누락" "$f: 명세 파일은 있으나 00-overview.md feature 목록에 없음"
    grep -qE 'REQ-[0-9]+' "$file" || report "근거 없음" "$f: 명세에 REQ 인용이 없음"
  done

  apis=$(api_index)
  api_ids=$(printf '%s\n' "$apis" | cut -d'|' -f1 | grep . | LC_ALL=C sort)
  for id in $(printf '%s\n' "$api_ids" | uniq -d); do
    report "API ID 중복" "$id: docs/api/에 두 번 이상 정의"
  done
  for line in $apis; do
    id=${line%%|*}
    rest=${line#*|}
    feat=${rest%%|*}
    req=${rest#*|}
    if [ -z "$feat" ]; then
      report "API feature 없음" "$id: '- feature:' 줄이 없음"
    elif ! contains "$features" "$feat"; then
      report "API feature 오류" "$id: ${feat}가 feature 목록에 없음"
    elif ! grep -q "$id" "docs/prd/features/$feat.md" 2>/dev/null; then
      report "명세 미연결" "$id: docs/prd/features/$feat.md API 표에 없음"
    fi
    [ "$req" = 1 ] || report "API 근거 없음" "$id: '- 요구사항:' REQ 인용이 없음"
  done
  # shellcheck disable=SC2046
  for id in $(ids_in 'API-[0-9]+' $(find docs/prd/features -name 'F-*.md' 2>/dev/null)); do
    contains "$api_ids" "$id" || report "API 문서 없음" "$id: feature 명세에서 인용하지만 docs/api/에 없음"
  done

  echo "요구사항 $(printf '%s\n' "$active" | grep -c .)건(삭제 제외), PRD·API 인용 $(printf '%s\n' "$used" | grep -c .)건, feature $(printf '%s\n' "$features" | grep -c .)건, API $(printf '%s\n' "$api_ids" | grep -c .)건"
}

check_feature() {
  f=$1
  spec="docs/prd/features/$f.md"
  plan="artifacts/work/$f/PLAN.md"
  [ -f "$spec" ] || { echo "$spec 없음"; exit 2; }
  [ -f "$plan" ] || { echo "$plan 없음"; exit 2; }
  num=${f#F-}

  spec_reqs=$(ids_in 'REQ-[0-9]+' "$spec")
  plan_reqs=$(ids_in 'REQ-[0-9]+' "$plan")
  plan_tcs=$(grep -E "^\| *TC-F$num-[0-9]+ *\|" "$plan" | sed -E 's/^\| *(TC-F[0-9]+-[0-9]+).*/\1/' | LC_ALL=C sort -u)

  test_dirs=$(find . -type d -path '*/src/test' ! -path './waveness/*' 2>/dev/null)
  if [ -n "$test_dirs" ]; then
    # shellcheck disable=SC2086
    test_ids=$(grep -rhoE "REQ-[0-9]+|TC-F$num-[0-9]+" $test_dirs 2>/dev/null | LC_ALL=C sort -u)
  else
    test_ids=""
    report "테스트 없음" "src/test 디렉터리 없음"
  fi

  for id in $spec_reqs; do
    contains "$plan_reqs" "$id" || report "계획 미반영" "$id: ${spec}에 있으나 PLAN.md에 없음"
    contains "$test_ids" "$id" || report "테스트 미연결" "$id: 테스트 코드에 인용 없음"
  done
  for id in $plan_reqs; do
    contains "$spec_reqs" "$id" || report "범위 밖" "$id: PLAN.md에 있으나 ${spec}에 없음"
  done
  for line in $(api_index); do
    id=${line%%|*}
    rest=${line#*|}
    [ "${rest%%|*}" = "$f" ] || continue
    grep -q "$id" "$plan" || report "계획 미반영" "$id: docs/api/의 $f API인데 PLAN.md에 없음"
  done
  [ -n "$plan_tcs" ] || report "TC 없음" "PLAN.md 테스트 케이스 표가 비어 있음"
  for tc in $plan_tcs; do
    contains "$test_ids" "$tc" || report "TC 미구현" "$tc: 테스트 코드에 없음"
  done
  for tc in $(printf '%s\n' "$test_ids" | grep -E '^TC-'); do
    contains "$plan_tcs" "$tc" || report "TC 정의 없음" "$tc: 테스트에 있으나 PLAN.md에 없음"
  done

  echo "$f: 요구사항 $(printf '%s\n' "$spec_reqs" | grep -c .)건, TC $(printf '%s\n' "$plan_tcs" | grep -c .)건"
}

case "${1:-}" in
  prd) check_prd ;;
  feature)
    [ -n "${2:-}" ] || { echo "사용법: sh scripts/check-trace.sh feature F-01"; exit 2; }
    check_feature "$2"
    ;;
  *)
    echo "사용법: sh scripts/check-trace.sh prd | feature F-01"
    exit 2
    ;;
esac

if [ "$problems" -gt 0 ]; then
  echo "문제 ${problems}건"
  exit 1
fi
echo "문제 없음"
