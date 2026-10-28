#!/bin/sh
# PreToolUse(Edit|Write) 훅: 역할 분리와 계획 승인 게이트를 파일 편집에서 강제
# 사용법: edit-guard.sh claude|codex (stdin: 도구 입력 JSON)
#   공통: .harness/state/(승인 기록) 편집 차단
#   claude: 소스·빌드 파일·PLAN.md 편집 차단 (기획·문서 전용, 대행 중에도 Codex 결과물 보호)
#   codex: 요구사항·PRD·API 문서 편집 차단, 소스·빌드 파일은 작업 브랜치 + 계획 승인 기록이 있을 때만 허용

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
  src/*|*/src/main/*|*/src/test/*|build.gradle|build.gradle.kts|*/build.gradle|*/build.gradle.kts|settings.gradle|settings.gradle.kts|pom.xml|*/pom.xml|gradle/*|gradlew|gradlew.bat) kind=code ;;
  docs/requirements.md|docs/prd/*|docs/api/*) kind=prd ;;
esac

case "$rel" in
  artifacts/work/*/PLAN.md) [ "$agent" = claude ] && kind=plan ;;
esac

if [ "$agent" = claude ]; then
  [ "$kind" = code ] && deny "Claude는 기획·문서 전용. 소스·빌드 파일($rel)은 Codex가 구현 (CLAUDE.md)"
  [ "$kind" = plan ] && deny "PLAN.md는 Codex 영역. 대행 중에도 계획은 바꾸지 않음. 필요한 내용은 HANDOFF.md에 기록 (docs/rules/workflow.md 대행 작업)"
  exit 0
fi

[ "$kind" = prd ] && deny "Codex는 요구사항·PRD·API 문서($rel)를 편집하지 않음. artifacts/work/<F-##>/HANDOFF.md의 'PRD 변경 요청'에 기록하고 멈출 것 (AGENTS.md)"

if [ "$kind" = code ]; then
  branch=$(current_branch)
  is_work_branch "$branch" || deny "작업 브랜치(feat|fix/ITD-####)가 아님($branch). feature-start로 브랜치를 만든 뒤 구현 (docs/rules/git.md)"
  [ -f "$(state_dir)/plan-approved--$(branch_key "$branch")" ] \
    || deny "계획 승인 기록 없음($branch). PLAN.md를 요약해 보여주고 사용자에게 '계획 승인' 입력을 요청할 것 (docs/rules/workflow.md)"
fi

exit 0
