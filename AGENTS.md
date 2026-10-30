# Codex 역할: 구현·테스트·검증

작업 전에 `docs/rules/common.md`, `docs/rules/principles.md`, `docs/rules/workflow.md`, `docs/project.md`를 읽는다. 커밋·브랜치 작업 전에는 `docs/rules/git.md`를 읽는다.

- Codex는 승인된 PRD(`docs/prd/`)와 Claude가 쓰고 사용자가 승인한 개발계획(`artifacts/work/<F-xx>/PLAN.md`)을 근거로 구현·테스트·검증만 한다. 요구사항·PRD·API 문서·계획(`docs/requirements.md`, `docs/prd/**`, `docs/api/**`, `PLAN.md`)은 편집하지 않는다(`edit-guard` 훅이 차단).
- 세션은 Claude가 `work-start`로 만든 worktree 폴더(`../<원본 폴더명>-ITD-####`)에서 연다. Codex는 worktree를 만들거나 브랜치를 바꾸지 않는다. 원본 폴더(통합 브랜치)에서는 구현하지 않는다.
- PRD의 누락·모순·모호함을 발견하면 추측으로 메우지 않는다. `artifacts/work/<F-xx>/HANDOFF.md`의 "PRD 변경 요청"에 적고 작업을 멈춘 뒤 사용자에게 알린다. 반영은 Claude의 `prd-change`가 한다.
- 계획에서 벗어나야 하면 `HANDOFF.md`의 "계획 변경 요청"에 적는다. `재승인 필요` 유형이면 멈추고 사용자에게 Claude `feature-plan`(재계획)을 안내한다.
- 아래 요청에 해당하면 해당 스킬(`.agents/skills/<이름>/SKILL.md`)을 먼저 읽고 그 절차를 따른다.

| 요청 | 스킬 |
| --- | --- |
| 구현 시작·계속 | `implement` |
| 문서와 코드 정합성 검증 | `doc-code-verify` |
| API 문서와 코드 대조 | `api-verify` |
| 테스트 코드 작성 | `test-write` |
| 테스트 실행·검증 | `test-verify` |
| 커밋·푸시 | `itd-commit` |

- 검증은 `verifier` 에이전트(`.codex/agents/`)에게 맡긴다. 구현한 세션이 자기 코드를 "검증 완료"로 보고하지 않는다.
- 에이전트는 `fork_turns: "none"`으로 실행하고 필요한 입력은 프롬프트로만 준다. 실행 뒤에는 `wait_agent`를 `timeout_ms: 1800000`으로 호출해 완료를 기다리고, 시간이 초과되면 같은 값으로 다시 기다린다. 대기 중에 짧은 timeout으로 반복 확인하거나 `send_message`로 진행 상황을 묻지 않는다(호출마다 메인 세션 컨텍스트 전체가 다시 전송됨).
- 한 feature는 한 세션에서 `implement`부터 `test-verify`까지 이어서 진행한다. 스킬을 마칠 때마다 `HANDOFF.md` 다음 행동을 갱신하고 다음 스킬로 넘어간다. 멈추는 곳은 사용자 판단이 필요한 지점(계획 변경 요청·PRD 변경 요청, 사람 승인 필요 항목, 커밋·푸시 승인)뿐이다. 세션이 끊겨 새로 열면 `artifacts/work/<F-xx>/HANDOFF.md`를 먼저 읽고 이어서 진행한다.
- Claude를 쓸 수 없을 때 사용자가 요청하면 `docs/rules/workflow.md` "대행 작업" 범위에서만 대신한다. 문서 커밋·push(`itd-commit`), `check-trace.sh prd` 실행, PRD 검증 판정(`prd-verify`, 에이전트는 `verifier` mode=prd), API 변경 요약 작성이 해당한다. 요구사항·PRD·API 문서는 대행 중에도 고치지 않고, 한 일은 `HANDOFF.md` "대행 기록"에 남긴다.
- 파일은 에디터 도구(apply_patch)로만 편집한다. `sed -i`, `cat >`, `tee` 같은 셸 쓰기로 `src/`나 문서를 바꾸지 않는다(승인 게이트 우회가 됨).
