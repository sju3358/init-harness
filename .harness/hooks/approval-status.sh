#!/bin/sh
# 승인 상태 요약(읽기 전용). 새 세션이 이전 세션의 승인 기록을 확인하는 유일한 경로
# 에이전트는 .harness/state/를 직접 다루지 않고(approval-gate가 차단) 이 스크립트를 실행한다
# 사용법: sh .harness/hooks/approval-status.sh
# Claude는 SessionStart 훅(session-context.sh)이 작업 브랜치에서 자동으로 출력

dir=$(dirname "$0")
. "$dir/lib.sh"

state=$(state_dir)
branch=$(current_branch)

mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
}

# 30분 유효 기록의 남은 분. 만료면 빈 값
remaining() {
  m=$(mtime "$1")
  [ -n "$m" ] || return
  left=$(( (m + 1800 - $(date +%s)) / 60 ))
  [ "$left" -ge 0 ] && printf '%s' "$left"
}

echo "하네스 승인 상태 ($branch)"

if [ -f "$state/harness-off" ]; then
  echo "- 하네스: OFF ($(cat "$state/harness-off")부터). 승인 게이트·차단이 모두 꺼져 있음"
else
  echo "- 하네스: ON"
fi

if [ ! -f "$state/prd-approved" ]; then
  echo "- PRD 승인: 없음"
else
  hash=$(prd_hash)
  if [ -z "$hash" ]; then
    echo "- PRD 승인: 확인 불가 (해시 도구 없음)"
  elif [ "$(cat "$state/prd-approved")" = "$hash" ]; then
    echo "- PRD 승인: 유효 (현재 요구사항·PRD·API 문서와 일치)"
  else
    echo "- PRD 승인: 무효 (승인 뒤 문서가 바뀌었거나 다른 브랜치 문서 기준)"
  fi
fi

if is_work_branch "$branch"; then
  f="$state/plan-approved--$(branch_key "$branch")"
  if [ -f "$f" ]; then
    echo "- 계획 승인: 있음 ($(cat "$f"))"
  else
    echo "- 계획 승인: 없음"
  fi
else
  echo "- 계획 승인: 해당 없음 (작업 브랜치 아님)"
fi

f="$state/git-approved"
left=""
[ -f "$f" ] && left=$(remaining "$f")
if [ -n "$left" ]; then
  echo "- 커밋·푸시 승인: $(tr '\n' ' ' < "$f" | sed -e 's/commit/커밋/' -e 's/push/푸시/' -e 's/ *$//') (남은 시간 ${left}분)"
else
  echo "- 커밋·푸시 승인: 없음"
fi

f="$state/adopt-approved"
left=""
[ -f "$f" ] && left=$(remaining "$f")
[ -n "$left" ] && echo "- 하네스 도입·업데이트 승인: $(cat "$f") (남은 시간 ${left}분)"

exit 0
