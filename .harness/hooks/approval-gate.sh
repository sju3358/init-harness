#!/bin/sh
# PreToolUse(Bash) 훅: 승인 게이트를 셸 명령에서 강제
#   1) 에이전트가 .harness/state/(승인 기록)를 만들거나 지우는 명령 차단
#   2) 30분 내 `커밋 승인` 기록 없는 git commit, `푸시 승인` 기록 없는 git push 차단
#   3) 보호 브랜치(main·master·통합 브랜치)에서의 git commit 차단
#   예외: `하네스 도입 승인`(30분, 승인 브랜치 한정)이 있으면 보호 브랜치에서
#         .harness/paths 안의 파일만 staged된 git commit과 그 브랜치로의 git push 허용
#   4) codex 인자로 실행되면 Codex의 커밋·push·병합·rebase·브랜치 생성·전환 차단 (AGENTS.md)
# 사용법: approval-gate.sh [codex] (stdin: 도구 입력 JSON)

dir=$(dirname "$0")
. "$dir/lib.sh"

agent=${1:-claude}
require_jq
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null | tr -d '\r')
[ -n "$cmd" ] || exit 0
exec_cmd=$(strip_cmd "$cmd")

# 승인 상태는 훅 메시지와 prd-check.sh로 확인하므로 에이전트가 이 경로를 다룰 일이 없음. 읽기 명령도 차단
# PowerShell 명령은 경로를 역슬래시로 쓸 수 있음
printf '%s' "$cmd" | grep -q '\.harness[/\\]state' \
  && deny ".harness/state/는 사용자 승인 문구로만 기록됨. 에이전트는 읽거나 만들거나 지우지 않음. 승인 상태는 훅 메시지와 sh .harness/hooks/prd-check.sh로 확인 (docs/rules/workflow.md 승인 게이트)"

git_sub() {
  printf '%s' "$exec_cmd" | grep -qE "(^|[;&|(]|&&)[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+$1\\b"
}

if [ "$agent" = codex ]; then
  for sub in commit push merge rebase switch; do
    git_sub "$sub" && deny "Codex는 git ${sub} 명령을 실행하지 않음. 커밋·push는 Claude itd-commit, 브랜치 전환은 Claude work-start가 함. HANDOFF.md 다음 행동에 적고 사용자에게 알릴 것 (AGENTS.md)"
  done
  # git checkout은 파일 되돌리기(`--` 뒤 경로)만 허용. 브랜치 전환·생성 차단
  if git_sub checkout && ! printf '%s' "$exec_cmd" | grep -qE '\bcheckout\b[^;&|]*[[:space:]]--[[:space:]]'; then
    deny "Codex는 git checkout으로 브랜치를 바꾸지 않음(파일 되돌리기는 git restore <경로>). 브랜치 전환은 Claude work-start (AGENTS.md)"
  fi
  printf '%s' "$exec_cmd" | grep -qE '\bgit[[:space:]]+branch[[:space:]]+(-[dDmMcC]\b|--(delete|move|copy)\b|[^-[:space:]])' \
    && deny "Codex는 브랜치를 만들거나 바꾸거나 지우지 않음. 브랜치 작업은 Claude work-start (AGENTS.md)"
fi

approved() {
  f="$(state_dir)/git-approved"
  [ -f "$f" ] && [ -n "$(find "$f" -mmin -30 2>/dev/null)" ] && grep -qx "$1" "$f"
}

branch=$(current_branch)

# 하네스 도입 예외: staged 파일 검사가 정확하도록 add와 commit을 한 명령에 묶지 않게 함
check_adopt_commit() {
  git_sub add && deny "하네스 도입 커밋은 git add와 git commit을 따로 실행 (staged 파일 검사용)"
  printf '%s' "$exec_cmd" | grep -qE '\bcommit\b[^;&|]*[[:space:]](-a|--all|-[a-zA-Z]*a[a-zA-Z]*)\b' \
    && deny "하네스 도입 커밋에 -a/--all 사용 금지. 하네스 파일만 git add 후 커밋"
  staged=$(git diff --cached --name-only)
  [ -n "$staged" ] || deny "staged 파일 없음"
  outside=$(printf '%s\n' "$staged" | while IFS= read -r f; do is_harness_path "$f" || echo "$f"; done)
  [ -z "$outside" ] || deny "하네스 도입 커밋에 하네스 밖 파일 포함: $(printf '%s' "$outside" | tr '\n' ' ')- 이 파일은 git restore --staged로 빼고 일반 절차(작업 브랜치)로 처리"
}

if git_sub commit; then
  if is_protected_branch "$branch"; then
    adopt_approved "$branch" || deny "보호 브랜치($branch)에 커밋 금지. 작업 브랜치(feat|fix/ITD-####)로 전환해 커밋. 하네스 도입·업데이트 중이면 사용자에게 '하네스 도입 승인' 또는 '하네스 업데이트 승인' 입력을 요청 (docs/rules/git.md)"
    check_adopt_commit
  else
    approved commit || deny "커밋 승인 기록 없음(또는 30분 경과). 커밋 메시지 미리보기를 보여주고 사용자에게 '커밋 승인' 입력을 요청할 것"
  fi
fi

if git_sub push; then
  if is_protected_branch "$branch" && adopt_approved "$branch"; then
    git log --format= --name-only "origin/$branch..HEAD" 2>/dev/null | grep . | while IFS= read -r f; do
      is_harness_path "$f" || { echo "$f"; break; }
    done | grep -q . && deny "push할 커밋에 하네스 밖 파일이 있음. 하네스 도입 예외는 하네스 파일만 push 가능"
  else
    approved push || deny "푸시 승인 기록 없음(또는 30분 경과). push 대상 브랜치를 알리고 사용자에게 '푸시 승인' 입력을 요청할 것"
  fi
fi

exit 0
