#!/bin/sh
# UserPromptSubmit 훅: 사용자가 한 줄로 단독 입력한 승인 문구만 .harness/state/에 기록
# 승인 기록은 사용자 프롬프트에서만 생기므로 에이전트가 스스로 게이트를 통과할 수 없음
# 문장 속 언급("계획 승인 전에 뭐 해?")은 오탐이라 줄 전체가 문구일 때만 인정
#
# 문구: PRD 승인 · 계획 승인 · 커밋 승인 · 푸시 승인 · 커밋 푸시 승인 · 승인 취소

dir=$(dirname "$0")
. "$dir/lib.sh"

prompt=$(sh "$dir/user-prompt-text.sh")
[ -n "$prompt" ] || exit 0

lines=$(printf '%s\n' "$prompt" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*[.!]*[[:space:]]*$//')
has() {
  printf '%s\n' "$lines" | grep -qixE "$1"
}

state=$(state_dir)
branch=$(current_branch)
key=$(branch_key "$branch")
mkdir -p "$state"

if has '승인 취소'; then
  rm -f "$state/plan-approved--$key" "$state/git-approved" "$state/adopt-approved"
  echo "승인 기록 삭제: 계획 승인($branch), 커밋·푸시 승인, 하네스 도입 승인"
fi

if has '하네스 도입 승인'; then
  if is_protected_branch "$branch"; then
    printf '%s' "$branch" > "$state/adopt-approved"
    echo "승인 기록: 하네스 도입 승인 ($branch, 30분 유효). .harness/paths 안의 파일만 커밋하고 ${branch}에 push 가능. git add와 git commit은 따로 실행할 것."
  else
    echo "하네스 도입 승인 기록 실패: 현재 브랜치($branch)가 보호 브랜치가 아님. 작업 브랜치에서는 일반 '커밋 승인'·'푸시 승인'을 사용."
  fi
fi

if has 'PRD 승인'; then
  prd_hash > "$state/prd-approved"
  echo "승인 기록: PRD 승인 (요구사항·PRD·API 문서 해시 저장). 이후 docs/requirements.md·docs/prd/·docs/api/ 내용이 바뀌면 다시 승인 필요."
fi

if has '계획 승인'; then
  if is_work_branch "$branch"; then
    date '+%Y-%m-%dT%H:%M:%S' > "$state/plan-approved--$key"
    echo "승인 기록: 계획 승인 ($branch). PLAN.md 상태를 '승인됨'으로 갱신하고 구현을 시작할 것."
  else
    echo "계획 승인 기록 실패: 현재 브랜치($branch)가 작업 브랜치(feat|fix/ITD-####)가 아님. 사용자에게 알릴 것."
  fi
fi

actions=""
has '커밋 승인|커밋 푸시 승인|커밋/푸시 승인|커밋,? ?푸시 승인' && actions="commit"
has '푸시 승인|커밋 푸시 승인|커밋/푸시 승인|커밋,? ?푸시 승인' && actions="$actions push"
if [ -n "$actions" ]; then
  printf '%s\n' $actions > "$state/git-approved"
  echo "승인 기록:$(printf ' %s' $actions | sed -e 's/commit/커밋/' -e 's/push/푸시/') 승인 ($branch, 30분 유효)"
fi

exit 0
