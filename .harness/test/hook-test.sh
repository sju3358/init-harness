#!/bin/sh
# 하네스 훅 자동 검사. setup.sh로 만든 샌드박스에서만 실행 (사용자 승인 문구 입력을 흉내 내 .harness/state/를 직접 바꾸기 때문)
# 사용법 (샌드박스 루트에서): sh .harness/test/hook-test.sh
# 각 훅에 도구 입력 JSON을 넣어 통과(0)·차단(2)을 확인하고, 끝나면 시작 전 승인 기록으로 되돌리고 처음 브랜치로 돌아감
# 실패가 하나라도 있으면 exit 1

set -u
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "git 저장소에서 실행"; exit 2; }
cd "$root" || exit 2
[ -f "$(git rev-parse --git-dir)/harness-sandbox" ] \
  || { echo "샌드박스가 아님. 하네스 저장소에서 sh .harness/test/setup.sh <폴더>로 만든 뒤 그 폴더에서 실행"; exit 2; }
[ -z "$(git status --porcelain)" ] || { echo "미커밋 변경이 있음. 브랜치를 바꾸며 검사하므로 깨끗한 상태에서 실행"; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "jq 필요"; exit 2; }
command -v node >/dev/null 2>&1 || { echo "node 필요"; exit 2; }

H=.harness/hooks
S=.harness/state
start_branch=$(git rev-parse --abbrev-ref HEAD)
pass=0
fail=0

check() {
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1))
    echo "PASS  $1"
  else
    fail=$((fail + 1))
    echo "FAIL  $1 (기대 $2, 실제 $3)"
  fi
}

# Claude 훅 입력으로 파일 편집 → 종료 코드
edit() {
  jq -nc --arg p "$2" '{tool_name:"Write",tool_input:{file_path:$p}}' | sh "$H/edit-guard.sh" "$1" >/dev/null 2>&1
  echo $?
}

# Codex apply_patch 입력을 어댑터로 → 차단이면 2
patch_codex() {
  p=$(printf '*** Begin Patch\n*** Update File: %s\n@@\n-a\n+b\n*** End Patch' "$1")
  out=$(jq -nc --arg c "$p" '{tool_name:"apply_patch",tool_input:{command:$c}}' \
    | node "$H/codex-tool-adapter.mjs" edit-guard codex 2>/dev/null)
  case "$out" in *'"deny"'*) echo 2 ;; *) echo 0 ;; esac
}

# Codex 셸 명령을 어댑터로 → 차단이면 2
bash_codex() {
  out=$(jq -nc --arg c "$1" '{tool_name:"shell",tool_input:{command:$c}}' \
    | node "$H/codex-tool-adapter.mjs" approval-gate codex 2>/dev/null)
  case "$out" in *'"deny"'*) echo 2 ;; *) echo 0 ;; esac
}

bash_hook() {
  jq -nc --arg c "$2" '{tool_name:"Bash",tool_input:{command:$c}}' | sh "$H/$1.sh" >/dev/null 2>&1
  echo $?
}

# 사용자 프롬프트 입력 흉내
say() {
  jq -nc --arg p "$1" '{prompt:$p}' | sh "$H/record-approval.sh" >/dev/null 2>&1
}

exists() {
  [ -f "$S/$1" ] && echo 있음 || echo 없음
}

reset_state() {
  rm -f "$S"/prd-approved "$S"/plan-approved--* "$S"/git-approved "$S"/adopt-approved "$S"/harness-off
}

bak=$(mktemp -d)
cp -p "$S"/* "$bak"/ 2>/dev/null
cleanup() {
  reset_state
  cp -p "$bak"/* "$S"/ 2>/dev/null
  rm -rf "$bak"
  git restore docs/requirements.md 2>/dev/null
  git switch -q "$start_branch" 2>/dev/null
}
trap cleanup EXIT

mkdir -p "$S"
reset_state

echo "== 통합 브랜치(main)"
git switch -q main
check "main: Claude 요구사항 편집 차단" 2 "$(edit claude docs/requirements.md)"
check "main: Claude PRD 편집 차단(절대 경로)" 2 "$(edit claude "$root/docs/prd/00-overview.md")"
check "main: Claude 소스 편집 차단" 2 "$(edit claude src/main/java/demo/DemoApplication.java)"
check "main: 규칙 밖 파일(README 등) 편집 허용" 0 "$(edit claude notes.md)"
check "main: git commit 차단(보호 브랜치)" 2 "$(bash_hook approval-gate 'git commit -m x')"
say "계획 승인"
check "main: '계획 승인' 기록 안 됨" 없음 "$(exists plan-approved--main)"

echo "== 작업 브랜치(feat/ITD-9001)"
git switch -q feat/ITD-9001
key=plan-approved--feat_ITD-9001
check "feat: Claude 요구사항 편집 허용" 0 "$(edit claude docs/requirements.md)"
check "feat: Claude PLAN.md 편집 허용" 0 "$(edit claude artifacts/work/F-01/PLAN.md)"
check "feat: Claude 테스트 코드 편집 차단" 2 "$(edit claude src/test/java/demo/DemoTest.java)"
check "feat: 계획 승인 전 Claude 소스 편집 차단" 2 "$(edit claude src/main/java/demo/DemoApplication.java)"
check "feat: 계획 승인 전 Claude 빌드 파일 편집 차단" 2 "$(edit claude build.gradle)"
check "feat: 계획 승인 전 Codex 테스트 편집 차단" 2 "$(patch_codex src/test/java/demo/DemoTest.java)"
check "feat: Codex PRD 편집 차단" 2 "$(patch_codex docs/prd/00-overview.md)"
check "feat: Codex API 문서 편집 차단" 2 "$(patch_codex docs/api/README.md)"
check "feat: Codex PLAN.md 편집 차단" 2 "$(patch_codex artifacts/work/F-01/PLAN.md)"
check "feat: Codex 소스 편집 차단" 2 "$(patch_codex src/main/java/demo/DemoApplication.java)"
check "feat: Codex 빌드 파일 편집 차단" 2 "$(patch_codex build.gradle)"
check "feat: Codex HANDOFF.md 편집 허용" 0 "$(patch_codex artifacts/work/F-01/HANDOFF.md)"
check "feat: Codex VERIFY.md 편집 허용" 0 "$(patch_codex artifacts/work/F-01/VERIFY.md)"
check "feat: Codex 추적표 편집 허용" 0 "$(patch_codex docs/traceability.md)"
check "승인 기록 파일 편집 차단(Claude)" 2 "$(edit claude .harness/state/$key)"
check "승인 기록 셸 생성 차단" 2 "$(bash_hook approval-gate "touch .harness/state/$key")"

echo "== 승인 문구"
say "계획 승인 전에 뭐 해야 해?"
check "문장 속 '계획 승인'은 기록 안 됨" 없음 "$(exists "$key")"
say "계획 승인"
check "'계획 승인' 기록" 있음 "$(exists "$key")"
check "계획 승인 후 Claude 소스 편집 허용" 0 "$(edit claude src/main/java/demo/DemoApplication.java)"
check "계획 승인 후 Claude 빌드 파일 편집 허용" 0 "$(edit claude build.gradle)"
check "계획 승인 후 Codex 테스트 편집 허용" 0 "$(patch_codex src/test/java/demo/DemoTest.java)"
check "계획 승인 후에도 Claude 테스트 편집 차단" 2 "$(edit claude src/test/java/demo/DemoTest.java)"
check "계획 승인 후에도 Codex 소스 편집 차단" 2 "$(patch_codex src/main/java/demo/DemoApplication.java)"

check "커밋 승인 전 git commit 차단" 2 "$(bash_hook approval-gate 'git commit -m x')"
check "푸시 승인 전 git push 차단" 2 "$(bash_hook approval-gate 'git push')"
say "커밋 승인"
check "커밋 승인 후 git commit 허용" 0 "$(bash_hook approval-gate 'git commit -m x')"
check "커밋 승인만으로 git push 차단" 2 "$(bash_hook approval-gate 'git push')"
say "커밋 푸시 승인"
check "커밋 푸시 승인 후 git push 허용" 0 "$(bash_hook approval-gate 'git push -u origin HEAD')"

say "PRD 승인"
sh "$H/prd-check.sh" >/dev/null 2>&1
check "'PRD 승인' 후 prd-check 유효" 0 $?
printf '\n변경\n' >> docs/requirements.md
sh "$H/prd-check.sh" >/dev/null 2>&1
check "요구사항 변경 후 prd-check 무효" 1 $?
git restore docs/requirements.md
sh "$H/prd-check.sh" >/dev/null 2>&1
check "되돌리면 prd-check 다시 유효" 0 $?

say "승인 취소"
check "'승인 취소'로 계획 승인 삭제" 없음 "$(exists "$key")"
check "'승인 취소'로 커밋·푸시 승인 삭제" 없음 "$(exists git-approved)"

echo "== git 안전"
check "git reset --hard 차단" 2 "$(bash_hook git-safety-guard 'git reset --hard')"
check "git clean -fd 차단" 2 "$(bash_hook git-safety-guard 'git clean -fd')"
check "git branch -D 차단" 2 "$(bash_hook git-safety-guard 'git branch -D feat/ITD-9001')"
check "git checkout -- . 차단" 2 "$(bash_hook git-safety-guard 'git checkout -- .')"
check "git push --force 차단" 2 "$(bash_hook git-safety-guard 'git push --force')"
check "bare git stash 차단" 2 "$(bash_hook git-safety-guard 'git stash')"
check "git stash pop 차단" 2 "$(bash_hook git-safety-guard 'git stash pop')"
check "pkill 차단" 2 "$(bash_hook git-safety-guard 'pkill java')"
check "git status 허용" 0 "$(bash_hook git-safety-guard 'git status')"
check "git switch -c 허용" 0 "$(bash_hook git-safety-guard 'git switch -c feat/ITD-9002')"
check "따옴표 안의 금지 명령 문자열은 명령으로 보지 않음" 0 "$(bash_hook git-safety-guard "git status && echo 'git reset --hard'")"

echo "== Codex git 제한 (승인 기록과 무관)"
say "커밋 푸시 승인"
check "Codex git commit 차단(커밋 승인 있어도)" 2 "$(bash_codex 'git commit -m x')"
check "Codex git push 차단" 2 "$(bash_codex 'git push -u origin HEAD')"
check "Codex git merge 차단" 2 "$(bash_codex 'git merge main')"
check "Codex git rebase 차단" 2 "$(bash_codex 'git rebase main')"
check "Codex git switch 차단" 2 "$(bash_codex 'git switch main')"
check "Codex git checkout 브랜치 전환 차단" 2 "$(bash_codex 'git checkout main')"
check "Codex git checkout -b 차단" 2 "$(bash_codex 'git checkout -b feat/ITD-9999')"
check "Codex git branch 생성 차단" 2 "$(bash_codex 'git branch feat/ITD-9999')"
check "Codex git checkout -- <경로> 허용" 0 "$(bash_codex 'git checkout -- src/test/java/demo/DemoTest.java')"
check "Codex git branch --show-current 허용" 0 "$(bash_codex 'git branch --show-current')"
check "Codex git status·diff·log 허용" 0 "$(bash_codex 'git status --short && git diff && git log --oneline -3')"
check "Claude git switch -c 허용(approval-gate)" 0 "$(bash_hook approval-gate 'git switch -c feat/ITD-9002')"

echo "== 승인 기록 보호와 상태 확인"
check "승인 기록 읽기 명령(ls) 차단" 2 "$(bash_hook approval-gate 'ls .harness/state')"
check "cat으로 시작해 뒤에서 지우는 명령 차단" 2 "$(bash_hook approval-gate "cat README.md; rm .harness/state/$key")"
check "PowerShell 역슬래시 경로 차단" 2 "$(bash_hook approval-gate 'Get-Content .harness\state\git-approved')"
check "상태 스크립트 실행은 허용" 0 "$(bash_hook approval-gate 'sh .harness/hooks/approval-status.sh')"
out=$(sh "$H/approval-status.sh")
case "$out" in *"커밋·푸시 승인: 커밋 푸시 (남은 시간"*) r=0 ;; *) r=1 ;; esac
check "approval-status: 커밋·푸시 승인과 남은 시간 표시" 0 $r
say "계획 승인"
case "$(sh "$H/approval-status.sh")" in *"계획 승인: 있음"*) r=0 ;; *) r=1 ;; esac
check "approval-status: 계획 승인 있음 표시" 0 $r
say "승인 취소"
case "$(sh "$H/approval-status.sh")" in *"계획 승인: 없음"*"커밋·푸시 승인: 없음"*) r=0 ;; *) r=1 ;; esac
check "approval-status: 승인 취소 후 없음 표시" 0 $r

echo "== Git 훅"
msg=$(mktemp)
printf 'feat/ITD-9001 제목\n\n- 내용\n' > "$msg"
sh .githooks/commit-msg "$msg" >/dev/null 2>&1
check "commit-msg: 브랜치와 같은 ITD 제목 허용" 0 $?
printf 'feat/ITD-9999 제목\n' > "$msg"
sh .githooks/commit-msg "$msg" >/dev/null 2>&1
check "commit-msg: 다른 티켓 제목 차단" 1 $?
printf '주문 API 추가\n' > "$msg"
sh .githooks/commit-msg "$msg" >/dev/null 2>&1
check "commit-msg: 형식 없는 제목 차단" 1 $?
rm -f "$msg"
printf 'refs/heads/main 0 refs/heads/main 0\n' | sh .githooks/pre-push origin x >/dev/null 2>&1
check "pre-push: main push 차단" 1 $?
printf 'refs/heads/feat/ITD-9001 0 refs/heads/feat/ITD-9001 0\n' | sh .githooks/pre-push origin x >/dev/null 2>&1
check "pre-push: 작업 브랜치 push 허용" 0 $?

echo "== 세션 인계"
out=$(sh "$H/session-context.sh" 2>/dev/null)
case "$out" in *"artifacts/work/F-01/HANDOFF.md"*"## 진행 위치"*) r=0 ;; *) r=1 ;; esac
check "session-context: 작업 브랜치에서 HANDOFF 상태·진행 위치 출력" 0 $r
case "$out" in *"== 승인 상태"*"계획 승인:"*) r=0 ;; *) r=1 ;; esac
check "session-context: 승인 상태 출력" 0 $r
git switch -q main
out=$(sh "$H/session-context.sh" 2>/dev/null)
check "session-context: main에서는 출력 없음" "" "$out"
git switch -q feat/ITD-9001

echo "== 하네스 OFF/ON"
say "하네스 OFF"
check "OFF 중 Claude 테스트 편집 통과" 0 "$(edit claude src/test/java/demo/DemoTest.java)"
case "$(sh "$H/approval-status.sh")" in *"하네스: OFF"*) r=0 ;; *) r=1 ;; esac
check "approval-status: OFF 중에도 OFF 상태 표시" 0 $r
say "하네스 ON"
check "ON 후 Claude 테스트 편집 다시 차단" 2 "$(edit claude src/test/java/demo/DemoTest.java)"

echo
echo "결과: 통과 $pass, 실패 $fail"
[ "$fail" = 0 ]
