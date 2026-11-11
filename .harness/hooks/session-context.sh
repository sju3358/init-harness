#!/bin/sh
# SessionStart 훅(Claude): 작업 브랜치에서 세션이 시작·재개·압축되면 인계 상태를 컨텍스트로 출력
# 계정 전환·사용량 한도 뒤 새 세션에서도 HANDOFF.md의 상태·진행 위치, 승인 상태, 미커밋 변경을 보고 바로 이어 가기 위함
# 출력만 하고 막지 않음

dir=$(dirname "$0")
. "$dir/lib.sh"

input=""
[ -t 0 ] || input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
if is_tester_session "$sid"; then
  echo "하네스: 이 세션은 Claude 테스터 세션이다(Codex 역할 대체). CLAUDE.md의 구현 역할이 아니라 AGENTS.md와 docs/rules/workflow.md 'Claude 테스터 세션'을 따른다. 판정은 code-verifier 에이전트."
  echo
fi

branch=$(current_branch)
is_work_branch "$branch" || exit 0
root=$(repo_root)

echo "하네스: 작업 브랜치($branch) 세션. 이전 세션의 인계 상태다. 이어서 작업하기 전에 확인하고, 필요하면 HANDOFF.md 전체와 PLAN.md를 읽을 것."
found=0
for f in "$root"/artifacts/work/F-*/HANDOFF.md; do
  [ -f "$f" ] || continue
  found=1
  echo
  echo "== ${f#"$root"/}"
  awk '/^## /{ p = ($0 == "## 상태" || $0 == "## 진행 위치") } p' "$f"
done
[ "$found" = 1 ] || echo "(artifacts/work/F-*/HANDOFF.md 없음: 아직 feature-plan 전 단계)"

echo
echo "== 승인 상태 (sh .harness/hooks/approval-status.sh)"
sh "$dir/approval-status.sh" | tail -n +2

echo
echo "== 미커밋 변경 (git status --short)"
git -C "$root" status --short | head -n 40
exit 0
