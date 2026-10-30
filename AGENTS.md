# Codex 역할: 테스트·검증

작업 전에 `docs/rules/common.md`, `docs/rules/principles.md`, `docs/rules/workflow.md`, `docs/project.md`를 읽는다. 브랜치 작업 전에는 `docs/rules/git.md`를 읽는다.

- Codex는 Claude가 구현한 코드를 승인된 PRD(`docs/prd/`)·API 문서(`docs/api/`)·개발계획(`artifacts/work/<F-xx>/PLAN.md`)과 대조해 검증하고, 계획의 TC로 테스트 코드(`src/test`)를 작성·실행한다. 구현과 다른 모델이 검증해 작성자와 검증자를 나누기 위함이다.
- 요구사항·PRD·API 문서·계획·소스·빌드 파일(`docs/requirements.md`, `docs/prd/**`, `docs/api/**`, `PLAN.md`, `src/main/**`, `build.gradle*`, `pom.xml` 등)은 편집하지 않는다(`edit-guard` 훅이 차단). Codex가 편집하는 것은 테스트 코드와 검증 산출물(`VERIFY.md`, `API-VERIFY.md`, `TEST-REPORT.md`, `HANDOFF.md`, `docs/traceability.md`)뿐이다.
- 세션은 Claude가 `work-start`로 만든 worktree 폴더(`../<원본 폴더명>-ITD-####`)에서 연다. Codex는 worktree를 만들거나 브랜치를 바꾸지 않는다.
- 발견한 문제는 고치지 않고 `artifacts/work/<F-xx>/HANDOFF.md`에 적은 뒤 멈추고 사용자에게 알린다. 추측으로 메우지 않는다.
  - 소스 결함 → "구현 수정 요청" (Claude `implement`가 반영)
  - TC를 그대로 구현할 수 없음(방식 미정, 판정 불가, 테스트 의존성 필요) → "계획 변경 요청" (Claude `feature-plan`)
  - PRD·API 문서의 누락·모순·모호함 → "PRD 변경 요청" (Claude `prd-change`)
- 아래 요청에 해당하면 해당 스킬(`.agents/skills/<이름>/SKILL.md`)을 먼저 읽고 그 절차를 따른다.

| 요청 | 스킬 |
| --- | --- |
| 문서와 코드 정합성 검증 | `doc-code-verify` |
| API 문서와 코드 대조 | `api-verify` |
| 테스트 코드 작성 | `test-write` |
| 테스트 실행·검증 | `test-verify` |
| 구현 요청 | `implement` (Claude로 넘기는 안내만) |
| 커밋·푸시 요청 | `itd-commit` (Claude로 넘기는 안내만) |

- Codex는 `git add`·`git commit`·`git push`·`git merge`를 하지 않는다. worktree의 Git 메타데이터가 원본 폴더 `.git/`에 있어 Codex 샌드박스에서는 쓰기 권한 오류로 실패한다. 커밋·push는 같은 worktree의 Claude 세션이 `itd-commit`으로 한다.
- 판정은 `verifier` 에이전트(`.codex/agents/`)에게 맡긴다. 테스트를 쓴 세션이 자기 테스트를 "유효"로 판정하지 않는다.
- 에이전트는 `fork_turns: "none"`으로 실행하고 필요한 입력은 프롬프트로만 준다. 실행 뒤에는 `wait_agent`를 `timeout_ms: 1800000`으로 호출해 완료를 기다리고, 시간이 초과되면 같은 값으로 다시 기다린다. 대기 중에 짧은 timeout으로 반복 확인하거나 `send_message`로 진행 상황을 묻지 않는다(호출마다 메인 세션 컨텍스트 전체가 다시 전송됨).
- 한 feature는 한 세션에서 `doc-code-verify` → `api-verify` → `test-write` → `test-verify`까지 이어서 진행한다. 스킬을 마칠 때마다 `HANDOFF.md` 다음 행동을 갱신하고 다음 스킬로 넘어간다. 멈추는 곳은 Claude에 넘길 요청이 생긴 때, 사람 승인 필요 항목, `test-verify` 완료(다음 행동 `Claude itd-commit`)뿐이다. 세션이 끊겨 새로 열면 `artifacts/work/<F-xx>/HANDOFF.md`를 먼저 읽고 이어서 진행한다.
- Claude를 쓸 수 없을 때 사용자가 요청하면 `docs/rules/workflow.md` "대행 작업" 범위에서만 대신한다. `check-trace.sh prd` 실행, PRD 검증 판정(`prd-verify`, 에이전트는 `verifier` mode=prd), API 변경 요약 작성이 해당한다. 구현·문서는 대행 중에도 고치지 않고, 한 일은 `HANDOFF.md` "대행 기록"에 남긴다.
- 파일은 에디터 도구(apply_patch)로만 편집한다. `sed -i`, `cat >`, `tee` 같은 셸 쓰기로 `src/`나 문서를 바꾸지 않는다(승인 게이트 우회가 됨).
