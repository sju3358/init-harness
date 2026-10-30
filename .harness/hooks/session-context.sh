#!/bin/sh
# SessionStart 훅(Claude): 작업 worktree에서 세션이 시작·재개·압축되면 인계 상태를 컨텍스트로 출력
# 계정 전환·사용량 한도 뒤 새 세션에서도 HANDOFF.md의 상태·진행 위치와 미커밋 변경을 보고 바로 이어 가기 위함
# 출력만 하고 막지 않음

dir=$(dirname "$0")
. "$dir/lib.sh"

branch=$(current_branch)
is_work_branch "$branch" || exit 0
root=$(repo_root)

echo "하네스: 작업 worktree($branch) 세션. 이전 세션의 인계 상태다. 이어서 작업하기 전에 확인하고, 필요하면 HANDOFF.md 전체와 PLAN.md를 읽을 것."
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
echo "== 미커밋 변경 (git status --short)"
git -C "$root" status --short | head -n 40
exit 0
