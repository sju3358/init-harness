#!/bin/sh
# PreToolUse(Edit|Write) 훅: 역할 분리, 작업 브랜치, 계획 승인 게이트를 파일 편집에서 강제
# 사용법: edit-guard.sh claude|codex (stdin: 도구 입력 JSON)
#   공통: .harness/state/(승인 기록) 편집 차단
#   공통: 요구사항·PRD·API 문서·feature 산출물·소스·테스트는 작업 브랜치(feat|fix/ITD-####)에서만 편집. 통합 브랜치에서 차단
#   공통: 소스·빌드 파일·테스트는 계획 승인 기록이 있을 때만 편집
#   claude: 기획·문서·계획·구현 담당. 테스트 코드 편집 차단 (테스트는 Codex)
#   codex: 테스트·검증 담당. 요구사항·PRD·API 문서·PLAN.md·소스·빌드 파일 편집 차단

dir=$(dirname "$0")
. "$dir/lib.sh"

agent=$1
require_jq
path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null | tr -d '\r')
[ -n "$path" ] || exit 0

rel=$(rel_path "$path")
[ -n "$rel" ] || exit 0

case "$rel" in
  .harness/state/*) deny ".harness/state/는 사용자 승인 문구로만 기록됨 (docs/rules/workflow.md)" ;;
esac

kind=other
case "$rel" in
  src/test/*|*/src/test/*) kind=test ;;
  src/*|*/src/main/*|build.gradle|build.gradle.kts|*/build.gradle|*/build.gradle.kts|settings.gradle|settings.gradle.kts|pom.xml|*/pom.xml|gradle/*|gradlew|gradlew.bat) kind=code ;;
  docs/requirements.md|docs/prd/*|docs/api/*) kind=prd ;;
  artifacts/work/_template/*|artifacts/work/README.md) ;;
  artifacts/work/*/PLAN.md) kind=plan ;;
  artifacts/work/*) kind=work ;;
esac

if [ "$agent" = claude ]; then
  [ "$kind" = test ] && deny "테스트 코드($rel)는 Codex가 작성. 빌드를 위해 기존 테스트를 고쳐야 하면 HANDOFF.md 다음 행동에 적어 Codex에 넘길 것 (CLAUDE.md)"
else
  [ "$kind" = prd ] && deny "Codex는 요구사항·PRD·API 문서($rel)를 편집하지 않음. artifacts/work/<F-##>/HANDOFF.md의 'PRD 변경 요청'에 기록하고 멈출 것 (AGENTS.md)"
  [ "$kind" = plan ] && deny "PLAN.md는 Claude가 작성. 계획을 바꿔야 하면 HANDOFF.md의 '계획 변경 요청'에 기록하고 멈출 것 (AGENTS.md)"
  [ "$kind" = code ] && deny "Codex는 소스·빌드 파일($rel)을 편집하지 않음(구현은 Claude). 결함은 HANDOFF.md의 '구현 수정 요청'에 기록하고 멈출 것 (AGENTS.md)"
fi

[ "$kind" = other ] && exit 0

branch=$(current_branch)
is_work_branch "$branch" || deny "작업 브랜치(feat|fix/ITD-####)가 아님($branch). Claude work-start로 작업 브랜치를 만들어 전환한 뒤 작업 (docs/rules/git.md)"

case "$kind" in
  code|test)
    [ -f "$(state_dir)/plan-approved--$(branch_key "$branch")" ] \
      || deny "계획 승인 기록 없음($branch). Claude feature-plan으로 PLAN.md를 쓰고 사용자가 '계획 승인'을 입력해야 함 (docs/rules/workflow.md)" ;;
esac

exit 0
