# 작업 흐름과 승인 게이트

이 문서가 절차의 단일 원본이다. 스킬은 이 문서의 단계를 실행하는 방법을 적는다.

## ID 체계

| ID | 형식 | 정의 위치 | 예 |
| --- | --- | --- | --- |
| 요구사항 | `REQ-###` | `docs/requirements.md` 표 | `REQ-001` |
| feature | `F-##` | `docs/prd/00-overview.md` feature 목록 | `F-01` |
| API | `API-###` | `docs/api/<도메인>.md` 엔드포인트 제목 | `API-007` |
| 테스트 케이스 | `TC-F##-##` | `artifacts/work/F-##/PLAN.md` | `TC-F01-03` |

- ID는 한번 정하면 바꾸거나 재사용하지 않는다. 삭제된 요구사항은 행을 지우지 않고 상태를 `삭제`로 바꾼다.
- PRD의 모든 규정 문장은 근거 REQ를 함께 적는다. REQ 없이 PRD에 들어간 내용은 "출처 없음"으로 검증에서 걸린다.
- 테스트는 `@DisplayName` 또는 주석에 `TC-F##-##`와 `REQ-###`를 적어 추적한다.
- 누락 검사는 `sh scripts/check-trace.sh prd`, `sh scripts/check-trace.sh feature F-##`로 기계적으로 한다.
- API 문서와 코드의 엔드포인트 목록 비교는 `node scripts/check-api.mjs [F-##]`로 한다.

## 단계

### Claude: 기획·문서

| 단계 | 스킬 | 산출물 | 완료 기준 |
| --- | --- | --- | --- |
| C0 초기 셋팅 | `project-init` | `docs/project.md`, Git 훅 등록 | 스택·DB·MQ·검증 명령을 사용자에게 확인받음 |
| C1 요구사항 | `req-gather` | `docs/requirements.md` | 요구사항마다 REQ ID·출처·인수 기준, 미결 질문 분리 |
| C2 PRD | `prd-write` | `docs/prd/**` | 범위의 모든 REQ가 PRD 어딘가에 반영, feature 목록 확정 |
| C2b API 문서 | `api-design` | `docs/api/**` | PRD의 모든 API가 필드·에러까지 문서화, 프론트 전달용 요약 |
| C3 검증 | `prd-verify` | `docs/verification/prd-verify.md` | `prd-verifier`(새 컨텍스트) 판정표(요구사항 ↔ PRD ↔ API), `check-trace.sh prd` 통과 |
| ✋ PRD 승인 | `prd-verify` | `00-overview.md`·`docs/api/README.md` 상태 `승인 vX.Y` | 사용자가 `PRD 승인` 입력. API 문서도 함께 승인됨 |

### Codex: 구현·검증 (feature 단위)

| 단계 | 스킬 | 산출물 | 완료 기준 |
| --- | --- | --- | --- |
| X1 feature 시작 | `feature-start` | `feat/ITD-####` 브랜치, `artifacts/work/F-##/` | PRD 승인 상태 확인, 티켓 번호 사용자 확인 |
| X2 개발계획 | `feature-plan` | `PLAN.md` | REQ ↔ 변경 파일 ↔ TC 매핑, 확인 필요 항목 분리 |
| ✋ 계획 승인 | `feature-plan` | 승인 기록 | 사용자가 `계획 승인` 입력 |
| X3 구현 | `implement` | 소스, `PLAN.md` "구현 중 변경" | 빌드 통과, 계획 이탈은 사용자 승인 |
| X4 문서-코드 검증 | `doc-code-verify` | `VERIFY.md` | `verifier` 판정표, REQ마다 `파일:줄` 근거 |
| X4b API 검증 | `api-verify` | `API-VERIFY.md` | `check-api.mjs` 통과, `verifier`(mode=api) 엔드포인트·항목별 판정 |
| X5 테스트 작성 | `test-write` | 테스트 코드 | `PLAN.md`의 TC 전부 구현 |
| X6 테스트 검증 | `test-verify` | `TEST-REPORT.md`, `docs/traceability.md` | 테스트 실행 결과 원문, `check-trace.sh feature` 통과, `verifier`의 테스트 유효성 판정 |
| ✋ 커밋·푸시 승인 | `itd-commit` | 커밋, feature 브랜치 push | 사용자가 `커밋 승인`·`푸시 승인` 입력 |

PR 생성과 병합은 사람이 직접 한다. 에이전트는 PR을 만들지 않는다.

## 승인 게이트

| 게이트 | 입력 문구 | 기록 | 막는 동작 |
| --- | --- | --- | --- |
| PRD 승인 | `PRD 승인` | `.harness/state/prd-approved` (요구사항·PRD·API 문서 해시) | Codex `feature-start`·`feature-plan` 진행 |
| 계획 승인 | `계획 승인` | `.harness/state/plan-approved--<브랜치>` | `src/`·빌드 파일 편집 |
| 커밋 승인 | `커밋 승인` | `.harness/state/git-approved`(30분) | `git commit` |
| 푸시 승인 | `푸시 승인` | `.harness/state/git-approved`(30분) | `git push` |
| 하네스 도입 (예외) | `하네스 도입 승인` | `.harness/state/adopt-approved`(30분, 승인 브랜치 한정, push 1회 후 삭제) | 보호 브랜치 커밋·push. 하네스 파일만 허용 |
| 취소 | `승인 취소` | 현재 브랜치 계획 승인·git 승인·도입 승인 삭제 | - |

- 기록은 `.harness/hooks/record-approval.sh`(UserPromptSubmit)가 사용자 문장에서만 만든다. 에이전트는 `.harness/state/`를 직접 만들거나 지우지 않는다(`approval-gate` 훅이 차단).
- 에이전트는 승인이 필요한 시점에 멈추고, 무엇을 승인하는지 요약한 뒤 입력할 문구를 안내한다. "진행해", "ㄱㄱ" 같은 일반 응답은 승인 문구가 아니므로 문구를 다시 안내한다.
- 계획 승인 후 계획이 바뀌면(파일 추가, 범위 변경, 신규 라이브러리) 구현을 멈추고 `PLAN.md`를 고친 뒤 다시 `계획 승인`을 받는다.

## 예외: 진행 중 프로젝트에 하네스 도입

하네스가 없는 프로젝트에 중간 도입할 때만 `harness-adopt` 스킬로 위 절차를 건너뛴다.

- 건너뛰는 것: PRD 승인, 작업 브랜치, ITD 커밋 형식, 보호 브랜치 커밋·push 차단
- 지키는 것: 사용자 승인(`하네스 도입 승인`), 하네스 파일(`.harness/paths`)만 커밋, git 안전 규칙
- 훅이 강제: 보호 브랜치 커밋 시 staged 파일이 모두 `.harness/paths` 안에 있어야 하고, `git add`와 `git commit`을 한 명령에 묶을 수 없다. push할 커밋에 하네스 밖 파일이 있으면 막는다.
- 도입 커밋 이후의 모든 작업(요구사항, PRD, 기존 규약 추출, 기능 구현)은 일반 절차를 따른다.

## 되돌림

- 구현·검증 중 PRD 문제 발견 → Codex가 `HANDOFF.md` "PRD 변경 요청"에 기록하고 멈춤 → 사용자가 Claude에서 `prd-change` 실행 → PRD 버전 증가, 재검증, `PRD 승인` → Codex가 `PLAN.md`를 다시 맞추고 `계획 승인`부터 재개.
- API 문서와 코드가 다르면 코드를 문서에 맞추는 것이 기본이다. 문서를 바꿔야 하면 위와 같이 "PRD 변경 요청"으로 처리하고 `prd-change`에서 `api-design` 3단계(변경 이력·프론트 영향)를 거친다.
- 검증(X4·X4b·X6)에서 "수정 필요"가 나오면 X3으로 돌아가 고친 뒤 해당 검증을 다시 실행한다. 고친 범위만 재검증하지 않고 같은 REQ에 걸린 항목을 모두 다시 본다.

## 검증 원칙

- 작성자와 검증자를 분리한다. 검증은 새 컨텍스트의 에이전트가 원문(요구사항·PRD·코드·테스트 결과)을 직접 읽고 판정한다.
- 검증 에이전트의 결과를 그대로 사용자에게 넘기지 않는다. 메인 세션이 위험이 큰 항목(사람이 바로 승인할 항목, 구체적이지만 주관적인 "일치" 주장, "변경 없음" 단정)을 골라 직접 재현해 본 뒤 보고한다. 재현 결과가 다르면 나머지 "통과" 항목도 다시 확인한다.
- "확인 못한 부분"은 "통과"와 같은 비중으로 생략 없이 보고한다.
- 테스트 통과 주장에는 실제 실행 명령과 결과 요약(성공·실패 수)을 붙인다. 실행하지 않은 테스트를 통과로 쓰지 않는다.
