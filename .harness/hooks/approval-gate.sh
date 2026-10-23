#!/bin/sh
# PreToolUse(Bash) 훅: 승인 게이트를 셸 명령에서 강제
#   1) 에이전트가 .harness/state/(승인 기록)를 만들거나 지우는 명령 차단
#   2) 30분 내 `커밋 승인` 기록 없는 git commit, `푸시 승인` 기록 없는 git push 차단
#   3) 보호 브랜치(main·master·통합 브랜치)에서의 git commit 차단

dir=$(dirname "$0")
. "$dir/lib.sh"

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0
exec_cmd=$(strip_cmd "$cmd")

if printf '%s' "$cmd" | grep -q '\.harness/state'; then
  printf '%s' "$exec_cmd" | grep -qE '^[[:space:]]*(ls|cat)[[:space:]]' \
    || deny ".harness/state/는 사용자 승인 문구로만 기록됨. 에이전트가 직접 만들거나 지우지 않음 (docs/rules/workflow.md 승인 게이트)"
fi

git_sub() {
  printf '%s' "$exec_cmd" | grep -qE "(^|[;&|(]|&&)[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+$1\\b"
}

approved() {
  f="$(state_dir)/git-approved"
  [ -f "$f" ] && [ -n "$(find "$f" -mmin -30 2>/dev/null)" ] && grep -qx "$1" "$f"
}

if git_sub commit; then
  branch=$(current_branch)
  is_protected_branch "$branch" && deny "보호 브랜치($branch)에 커밋 금지. 작업 브랜치(feat|fix|docs/ITD-####)에서 커밋 (docs/rules/git.md)"
  approved commit || deny "커밋 승인 기록 없음(또는 30분 경과). 커밋 메시지 미리보기를 보여주고 사용자에게 '커밋 승인' 입력을 요청할 것"
fi

if git_sub push; then
  approved push || deny "푸시 승인 기록 없음(또는 30분 경과). push 대상 브랜치를 알리고 사용자에게 '푸시 승인' 입력을 요청할 것"
fi

exit 0
