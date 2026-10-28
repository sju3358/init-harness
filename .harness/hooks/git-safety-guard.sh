#!/bin/sh
# PreToolUse(Bash) 훅: docs/rules/git.md의 금지 명령을 기계적으로 차단
# 우회가 필요한 정당한 사유가 있으면 사용자가 터미널에서 직접 실행

dir=$(dirname "$0")
. "$dir/lib.sh"

require_jq
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null | tr -d '\r')
[ -n "$cmd" ] || exit 0
exec_cmd=$(strip_cmd "$cmd")

# 이름 패턴 종료는 사용자가 띄운 서버 등 다른 프로세스까지 종료함
if printf '%s' "$exec_cmd" | grep -qE '(^|[;&|(][[:space:]]*)(pkill|killall)\b'; then
  deny "pkill/killall 금지. 직접 띄운 서버는 포트로 지정해 종료: kill \$(lsof -ti tcp:<port>)"
fi
# Windows의 이름 지정 종료(taskkill /IM, Stop-Process -Name)도 같음
if printf '%s' "$exec_cmd" | grep -qiE '(^|[;&|(][[:space:]]*)(taskkill[^;&|]*[[:space:]][/-]im\b|(stop-process|spps)[^;&|]*[[:space:]]-n(ame)?\b)'; then
  deny "taskkill /IM, Stop-Process -Name 금지. 직접 띄운 서버는 포트로 지정해 종료: Stop-Process -Id (Get-NetTCPConnection -LocalPort <port>).OwningProcess"
fi

printf '%s' "$exec_cmd" | grep -qE '(^|[;&|(][[:space:]]*)git\b' || exit 0

has() {
  printf '%s' "$exec_cmd" | grep -qE "$1"
}

has '\bgit[[:space:]]+reset[[:space:]]+--hard\b' && deny "git reset --hard 금지. 상황을 보고하고 사용자 승인 후 사용자가 직접 실행 (docs/rules/git.md)"
has '\bgit[[:space:]]+clean\b[^|;&]*-[a-zA-Z]*[fdx]' && deny "git clean -f/-d/-x 금지. 미커밋 변경을 지울 수 있음 (docs/rules/git.md)"
has '\bgit[[:space:]]+branch[[:space:]]+(-D|--delete[[:space:]]+--force)\b' && deny "git branch -D 금지 (docs/rules/git.md)"
has '\bgit[[:space:]]+checkout[[:space:]]+(--[[:space:]]+)?\.[[:space:]]*($|[;&|])' && deny "경로 없는 git checkout -- . 금지. 되돌릴 파일 경로를 지정 (docs/rules/git.md)"
has '\bgit[[:space:]]+push\b[^;&|]*([[:space:]]-f\b|--force)' && deny "강제 push 금지 (docs/rules/git.md)"
has '\bgit[[:space:]]+push\b[^;&|]*[[:space:]]\+' && deny "+refspec 강제 push 금지 (docs/rules/git.md)"
has '\bgit[[:space:]]+stash[[:space:]]*($|[;&|])' && deny "bare git stash 금지. 'git stash push -u -m \"<태그>\"' 사용 (docs/rules/git.md)"
if has '\bgit[[:space:]]+stash[[:space:]]+push\b' && ! has '[[:space:]]-m([[:space:]]|$)'; then
  deny "태그 없는 git stash push 금지. -m \"<태그>\" 추가 (docs/rules/git.md)"
fi
has '\bgit[[:space:]]+stash[[:space:]]+pop\b' && deny "git stash pop 금지. 'git stash apply <sha>' 후 확인하고 drop (docs/rules/git.md)"

exit 0
