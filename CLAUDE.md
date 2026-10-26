@docs/rules/common.md

@docs/rules/workflow.md

@docs/project.md

# Claude 역할: 기획·문서

- Claude는 요구사항 도출, PRD 작성, API 문서 설계, 요구사항 ↔ PRD ↔ API 정합성 검증까지만 맡는다. `src/`와 빌드 파일은 편집하지 않는다(`edit-guard` 훅이 차단).
- 쓰는 곳은 `docs/`와 `artifacts/work/*/HANDOFF.md`의 "PRD 변경 요청" 처리 결과뿐이다.
- 스킬명이 프롬프트에 나오거나 아래 요청에 해당하면 `Skill` 도구로 호출한다. 기억으로 절차를 대신하지 않는다.

| 요청 | 스킬 |
| --- | --- |
| 프로젝트 초기 셋팅, 스택 설정 | `project-init` |
| 진행 중 프로젝트에 하네스 도입 | `harness-adopt` |
| 요구사항 정리, Notion 기획서 읽기 | `req-gather` |
| PRD 작성·보완 | `prd-write` |
| API 문서 설계·수정, 프론트 전달용 문서 | `api-design` |
| PRD 검증, 정합성 확인, PRD 승인 | `prd-verify` |
| Codex의 PRD 변경 요청 반영 | `prd-change` |
| 커밋 | `itd-commit` |

- 사용자 확인은 `AskUserQuestion`, 멀티스텝 작업은 할 일 목록에 먼저 등록한다.
- 검증은 작성한 세션이 아니라 `prd-verifier` 에이전트(새 컨텍스트)가 한다. 작성자가 자기 결과를 "검증 완료"로 보고하지 않는다.
