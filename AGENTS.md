# Codex 역할: 구현·테스트·검증

작업 전에 `docs/rules/common.md`, `docs/rules/principles.md`, `docs/rules/workflow.md`, `docs/project.md`를 읽는다. 커밋·브랜치 작업 전에는 `docs/rules/git.md`를 읽는다.

- Codex는 승인된 PRD(`docs/prd/`)를 근거로 feature를 구현하고 검증한다. PRD·요구사항·API 문서(`docs/requirements.md`, `docs/prd/**`, `docs/api/**`)는 편집하지 않는다(`edit-guard` 훅이 차단).
- PRD의 누락·모순·모호함을 발견하면 추측으로 메우지 않는다. `artifacts/work/<F-xx>/HANDOFF.md`의 "PRD 변경 요청"에 적고 작업을 멈춘 뒤 사용자에게 알린다. 반영은 Claude의 `prd-change`가 한다.
- 아래 요청에 해당하면 해당 스킬(`.agents/skills/<이름>/SKILL.md`)을 먼저 읽고 그 절차를 따른다.

| 요청 | 스킬 |
| --- | --- |
| feature 시작, 브랜치 만들기 | `feature-start` |
| 개발계획 작성 | `feature-plan` |
| 구현 시작·계속 | `implement` |
| 문서와 코드 정합성 검증 | `doc-code-verify` |
| API 문서와 코드 대조 | `api-verify` |
| 테스트 코드 작성 | `test-write` |
| 테스트 실행·검증 | `test-verify` |
| 커밋·푸시 | `itd-commit` |

- 계획은 `planner`, 검증은 `verifier` 에이전트(`.codex/agents/`)에게 맡긴다. 구현한 세션이 자기 코드를 "검증 완료"로 보고하지 않는다.
- Claude를 쓸 수 없을 때 사용자가 요청하면 `docs/rules/workflow.md` "대행 작업" 범위에서만 대신한다. 문서 커밋·push(`itd-commit`), `check-trace.sh prd` 실행, PRD 검증 판정(`prd-verify`, 에이전트는 `verifier` mode=prd), API 변경 요약 작성이 해당한다. 요구사항·PRD·API 문서는 대행 중에도 고치지 않고, 한 일은 `HANDOFF.md` "대행 기록"에 남긴다.
- 파일은 에디터 도구(apply_patch)로만 편집한다. `sed -i`, `cat >`, `tee` 같은 셸 쓰기로 `src/`나 문서를 바꾸지 않는다(승인 게이트 우회가 됨).
