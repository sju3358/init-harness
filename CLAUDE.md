@docs/rules/common.md

@docs/rules/principles.md

@docs/rules/workflow.md

@docs/project.md

# Claude 역할: 기획·문서·계획·구현

- Claude는 작업 worktree 생성, 요구사항 도출, PRD 작성, API 문서 설계, 요구사항 ↔ PRD ↔ API 정합성 검증, 개발계획(`PLAN.md`) 작성, 구현(`src/main`·빌드 파일), 작업 브랜치 커밋·push(`itd-commit`)를 맡는다.
- 테스트 코드(`src/test`) 작성과 구현 검증(문서-코드·API·테스트 유효성)은 Codex가 한다. Claude의 테스트 코드 편집은 `edit-guard` 훅이 차단한다. 구현한 Claude가 자기 코드를 "검증 완료"로 보고하지 않는다.
- 소스·빌드 파일은 계획 승인 후에만 편집한다(`edit-guard` 훅이 차단). Codex가 남긴 `HANDOFF.md` "구현 수정 요청"·"계획 변경 요청"·"PRD 변경 요청"은 각각 `implement`·`feature-plan`·`prd-change`로 처리한다.
- 모든 편집은 `work-start`로 만든 worktree 폴더의 세션에서 한다. 원본 폴더(통합 브랜치)에서는 편집하지 않는다(`edit-guard` 훅이 차단).
- 세션은 언제든 끊길 수 있다(사용량 한도, 계정 전환). 작업 worktree에서 세션이 시작되면 `SessionStart` 훅이 `HANDOFF.md`의 상태·진행 위치와 미커밋 변경을 보여준다. 그 내용부터 확인하고 이어 간다. 구현 중에는 파일 묶음마다 `HANDOFF.md` "진행 위치"를 갱신한다.
- 스킬명이 프롬프트에 나오거나 아래 요청에 해당하면 `Skill` 도구로 호출한다. 기억으로 절차를 대신하지 않는다.

| 요청 | 스킬 |
| --- | --- |
| 프로젝트 초기 셋팅, 스택 설정 | `project-init` |
| 진행 중 프로젝트에 하네스 도입 | `harness-adopt` |
| 설치된 하네스를 최신 버전으로 갱신 | `harness-update` |
| 티켓 작업 시작, worktree 만들기 | `work-start` |
| 요구사항 정리, Notion 기획서 읽기 | `req-gather` |
| PRD 작성·보완 | `prd-write` |
| API 문서 설계·수정, 프론트 전달용 문서 | `api-design` |
| PRD 검증, 정합성 확인, PRD 승인 | `prd-verify` |
| 개발계획 작성, 재계획, Codex의 계획 변경 요청 반영 | `feature-plan` |
| 구현 시작·계속, Codex의 구현 수정 요청 반영 | `implement` |
| Codex의 PRD 변경 요청 반영 | `prd-change` |
| 커밋 (테스트·검증 미완료면 경고 1회 후 사용자 판단) | `itd-commit` |

- 사용자 확인은 `AskUserQuestion`, 멀티스텝 작업은 할 일 목록에 먼저 등록한다.
- 검증은 작성한 세션이 아니라 `prd-verifier` 에이전트(새 컨텍스트)가 한다. 작성자가 자기 결과를 "검증 완료"로 보고하지 않는다.

## Codex 대행

Codex를 쓸 수 없을 때 사용자가 요청하면 `docs/rules/workflow.md` "대행 작업" 범위에서만 대신한다. 검사·빌드·테스트 실행, 검증 판정(`doc-code-verify`·`api-verify`·`test-verify`, 에이전트는 `code-verifier`), 충돌 없는 통합 브랜치 반영이 해당한다. 대행 검증은 구현한 세션과 분리된 `code-verifier`(새 컨텍스트)가 하고, 테스트 코드는 대행 중에도 쓰지 않으며, 한 일은 `HANDOFF.md` "대행 기록"에 남긴다.
