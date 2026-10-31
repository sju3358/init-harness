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
- 티켓마다 브랜치가 따로라서, 새 ID(`REQ`·`Q`·`F`·`API`)는 `git fetch` 후 통합 브랜치(`origin/main`)와 아직 병합되지 않은 다른 작업 브랜치(`git branch -a --no-merged origin/main`)의 문서에서 쓰인 최댓값 다음 번호로 정한다.
- PRD의 모든 규정 문장은 근거 REQ를 함께 적는다. REQ 없이 PRD에 들어간 내용은 "출처 없음"으로 검증에서 걸린다.
- 테스트는 `@DisplayName` 또는 주석에 `TC-F##-##`와 `REQ-###`를 적어 추적한다.
- 누락 검사는 `sh scripts/check-trace.sh prd`, `sh scripts/check-trace.sh feature F-##`로 기계적으로 한다.
- API 문서와 코드의 엔드포인트 목록 비교는 `node scripts/check-api.mjs [F-##]`로 한다.

## 작업 단위와 브랜치

- 티켓 하나 = feature 하나 = 브랜치(`feat|fix/ITD-####`) 하나. 그 feature의 요구사항·PRD·API 문서·개발계획·구현(Claude)과 테스트·검증(Codex)을 같은 브랜치에서 진행한다.
- worktree를 만들지 않는다. 프로젝트 폴더 하나에서 `work-start`가 통합 브랜치(`main`)로부터 작업 브랜치를 만들어 전환(`git switch -c`)하고, 그 세션에서 바로 이어 간다. Codex도 같은 폴더에서 세션을 연다.
- 통합 브랜치에서는 `project-init`, `work-start`, 하네스 도입·업데이트만 하고 문서·계획·코드를 편집하지 않는다(`edit-guard` 훅이 차단).
- 한 폴더를 Claude와 Codex가 함께 쓰므로 Claude → Codex 순서로 이어 받고, 두 세션이 동시에 편집하지 않는다. 한 번에 티켓 하나만 진행한다. 다른 티켓으로 전환하려면 지금 브랜치의 변경을 커밋한 뒤 `work-start`를 다시 한다.
- `docs/requirements.md`에는 이 티켓 범위의 REQ만 적는다(`check-trace.sh prd`는 모든 REQ가 PRD에 반영됐는지 본다). 다른 feature의 요구는 별도 티켓 후보로 보고한다.

## 단계

| 단계 | 담당 | 스킬 | 산출물 | 완료 기준 |
| --- | --- | --- | --- | --- |
| C0 초기 셋팅 | Claude | `project-init` | `docs/project.md`, Git 훅 등록 | 통합 브랜치에서 프로젝트당 1회. 스택·DB·MQ·검증 명령을 사용자에게 확인받음 |
| W 작업 시작 | Claude | `work-start` | `feat/ITD-####` 브랜치로 전환 | 통합 브랜치에서 실행. 티켓 번호 사용자 확인 |
| C1 요구사항 | Claude | `req-gather` | `docs/requirements.md` | 이 티켓의 요구사항마다 REQ ID·출처·인수 기준, 미결 질문 분리 |
| C2 PRD | Claude | `prd-write` | `docs/prd/**` | 이 티켓의 모든 REQ가 PRD 어딘가에 반영, feature 명세 확정 |
| C2b API 문서 | Claude | `api-design` | `docs/api/**` | PRD의 모든 API가 필드·에러까지 문서화, 프론트 전달용 요약 |
| C3 검증 | Claude | `prd-verify` | `docs/verification/prd-verify.md` | `prd-verifier`(새 컨텍스트) 판정표(요구사항 ↔ PRD ↔ API), `check-trace.sh prd` 통과 |
| ✋ PRD 승인 | Claude | `prd-verify` | `00-overview.md`·`docs/api/README.md` 상태 `승인 vX.Y` | 사용자가 `PRD 승인` 입력. API 문서도 함께 승인됨 |
| C4 개발계획 | Claude | `feature-plan` | `artifacts/work/F-##/PLAN.md` | REQ ↔ 변경 파일 ↔ TC 매핑, 확인 필요 항목 답변 완료 |
| ✋ 계획 승인 | Claude | `feature-plan` | 승인 기록 | 사용자가 `계획 승인` 입력 |
| C5 구현 | Claude | `implement` | 소스·빌드 파일 | 컴파일 통과. 파일 묶음마다 `HANDOFF.md` "진행 위치" 갱신. 계획 이탈은 `PLAN.md` "계획 변경 이력"과 재승인 |
| X1 문서-코드 검증 | Codex | `doc-code-verify` | `VERIFY.md` | `verifier` 판정표, REQ마다 `파일:줄` 근거 |
| X1b API 검증 | Codex | `api-verify` | `API-VERIFY.md` | `check-api.mjs` 통과, `verifier`(mode=api) 엔드포인트·항목별 판정 |
| X2 테스트 작성 | Codex | `test-write` | 테스트 코드 | `PLAN.md`의 TC 전부 구현 |
| X3 테스트 검증 | Codex | `test-verify` | `TEST-REPORT.md`, `test-status.md`, `docs/traceability.md` | 모든 TC `PASS`(실행 결과 원문), `check-trace.sh feature` 통과, `verifier`의 테스트 유효성 판정. 첫 실패에서 멈춰 버그 리포트. 완료는 전체 회귀 실패 0건(이후 소스·테스트 변경 없음)일 때만 |
| ✋ 커밋·푸시 승인 | Claude | `itd-commit` | 커밋, 작업 브랜치 push | 테스트·검증 미완료면 경고 1회 후 사용자 판단. 사용자가 `커밋 승인`·`푸시 승인` 입력 |

- 구현은 Claude만 한다. 한 티켓의 코드를 한 모델이 써서 스타일을 일관되게 유지하기 위함이다. Codex의 소스·빌드 파일 편집은 `edit-guard` 훅이 차단한다.
- 테스트 작성과 검증은 Codex가 한다. 구현과 다른 모델이 보게 해서 작성자와 검증자를 나눈다. Claude의 테스트 코드(`src/test`) 편집은 훅이 차단한다.
- 테스트 기대값은 문서(요구사항·PRD·API·`PLAN.md`)에서만 가져온다. 구현 코드는 인터페이스·실행 방법 확인용이고, 문서와 다르면 버그, 문서가 침묵하면 명세 누락으로 기록한다.
- 테스트는 첫 실패에서 멈춘다. 구현 결함이면 Codex가 버그 리포트(`HANDOFF.md` "구현 수정 요청")를 쓰고 멈추고, Claude `implement`가 고친 뒤 Codex가 다시 검증한다. Codex는 구현 코드를 고치지 않는다.
- 중간 재실행은 `test-status.md` 기준으로 `FAIL`·`미실행`과 수정 파일에 관련된 `PASS` TC만 한다. 최종 완료 판정은 전체 회귀(전체 테스트) 통과가 필수다. Codex는 모든 TC가 `PASS`가 되면 전체 회귀를 실행하고, 실패 0건이며 그 뒤 소스·테스트 변경이 없을 때만 `HANDOFF.md` 상태를 `완료`로 쓴다. 충족하지 않은 채 커밋하면 `itd-commit`이 경고하고 `- 미검증: 전체 회귀`를 남긴다.
- 커밋·push는 Claude만 한다. 미검증 경고, ITD 커밋 메시지, 승인 확인을 `itd-commit` 한 곳에서 처리하기 위함이다. Codex는 `test-verify`를 마치면 `HANDOFF.md` 다음 행동을 `Claude itd-commit`으로 적고 멈춘다.
- 테스트·검증이 끝나지 않아도 커밋·push를 막지 않는다. `itd-commit`이 미충족 항목을 근거와 함께 1회 경고하고, 사용자가 진행 여부를 정한다. 진행하면 커밋 본문에 `- 미검증: <항목>`을 남긴다.

### 세션 끊김 대비

Claude는 사용량 한도나 계정 전환으로 세션이 끊길 수 있다. 맥락은 대화가 아니라 파일로 이어 간다.

- 구현 중 파일 묶음마다 `HANDOFF.md` "진행 위치"(끝난 것, 진행 중, 다음 할 일, 결정)를 갱신한다. 작업 결과 파일은 작업 브랜치의 폴더에 남는다.
- Claude 세션이 작업 브랜치에서 시작·재개·압축되면 `SessionStart` 훅(`.harness/hooks/session-context.sh`)이 `HANDOFF.md`의 상태·진행 위치, 승인 상태, `git status`를 컨텍스트로 넣는다.
- Codex 세션은 시작할 때 `HANDOFF.md`를 먼저 읽고 `approval-status.sh`로 승인 상태를 확인한다(`AGENTS.md`).

PR 생성과 병합은 사람이 직접 한다. 에이전트는 PR을 만들지 않는다. 병합 후 정리(`git switch main`, `git pull`, `git branch -d`)는 사용자가 한다.

## 승인 게이트

| 게이트 | 입력 문구 | 기록 | 막는 동작 |
| --- | --- | --- | --- |
| PRD 승인 | `PRD 승인` | `.harness/state/prd-approved` (요구사항·PRD·API 문서 해시) | `feature-plan` 진행 |
| 계획 승인 | `계획 승인` | `.harness/state/plan-approved--<브랜치>` | 소스·빌드 파일 편집(Claude), 테스트 코드 편집(Codex) |
| 커밋 승인 | `커밋 승인` | `.harness/state/git-approved`(30분) | `git commit` |
| 푸시 승인 | `푸시 승인` | `.harness/state/git-approved`(30분) | `git push` |
| 하네스 도입 (예외) | `하네스 도입 승인` | `.harness/state/adopt-approved`(30분, 승인 브랜치 한정, push 1회 후 삭제) | 보호 브랜치 커밋·push. 하네스 파일만 허용 |
| 취소 | `승인 취소` | 현재 브랜치 계획 승인·git 승인·도입 승인 삭제 | - |
| 하네스 끄기·켜기 | `하네스 OFF` / `하네스 ON` | `.harness/state/harness-off` (`하네스 ON`까지 유지) | OFF 중에는 위 게이트와 훅 차단 전부 해제 |

- 기록은 `.harness/hooks/record-approval.sh`(UserPromptSubmit)가 사용자 문장에서만 만든다. 에이전트는 `.harness/state/`를 읽기를 포함해 직접 다루지 않는다(`approval-gate` 훅이 차단).
- 승인 상태는 `sh .harness/hooks/approval-status.sh`로 확인한다. Claude는 작업 브랜치 세션이 시작·재개·압축될 때 `SessionStart` 훅이 이 요약을 자동으로 넣고, Codex는 세션 시작 때 직접 실행한다.
- 기록은 프로젝트 폴더의 `.harness/state/`에 남고 Claude·Codex가 함께 본다. 승인 문구는 해당 티켓 브랜치로 전환된 상태에서 입력한다. 계획 승인은 브랜치별로 남고, PRD 승인은 문서 해시라 다른 티켓 브랜치로 전환하거나 통합 브랜치를 반영해 문서가 바뀌면 다시 승인한다.
- 에이전트는 승인이 필요한 시점에 멈추고, 무엇을 승인하는지 요약한 뒤 입력할 문구를 안내한다. "진행해", "ㄱㄱ" 같은 일반 응답은 승인 문구가 아니므로 문구를 다시 안내한다.
- 계획 승인 후 계획이 바뀌어야 하면(파일 추가, 범위 변경, 신규 라이브러리) Claude는 구현을 멈추고 사용자가 `승인 취소`를 입력한 뒤 `PLAN.md`를 고쳐 `계획 승인`을 다시 받는다. Codex가 테스트 작성 중 TC를 바꿔야 하면 `HANDOFF.md` "계획 변경 요청"에 적고 멈춘다.

## 대행 작업

원래 담당 도구가 토큰 한도 등으로 쓸 수 없을 때, 사용자가 요청하면 다른 도구가 아래 작업을 대신한다. 기준은 **상대가 만든 결과물(문서 내용·코드·계획)을 바꾸지 않고 실행·검증·기록만 대신하는 것**이다.

| # | 작업 | Claude가 대행 (Codex 영역) | Codex가 대행 (Claude 영역) | 조건 |
| --- | --- | --- | --- | --- |
| 1 | 기계 검사 | `check-trace.sh feature`, `check-api.mjs` | `check-trace.sh prd` | 결과 보고만. 수정은 원래 담당 |
| 2 | 빌드·테스트 실행 | `docs/project.md` 명령 실행, `TEST-REPORT.md` "실행" 기록 | - | 실행 중에는 코드 수정 안 함 |
| 3 | 검증 대행 | `doc-code-verify`, `api-verify`, `test-verify` 판정 (`code-verifier`, 구현 세션과 분리된 새 컨텍스트) | `prd-verify` 판정 (`verifier` mode=prd) | 검증 산출물에만 씀. 소스 결함은 "구현 수정 요청"으로 Claude `implement`, 테스트 결함은 Codex에 넘김 |
| 4 | 인계 정리 | `HANDOFF.md` 상태·다음 행동·대행 기록 | 같음 | - |
| 5 | 통합 브랜치 반영 | 작업 브랜치에 통합 브랜치 병합 | - | 충돌 없을 때만. 충돌 시 `git merge --abort` 후 원래 담당에게 넘김 |
| 6 | 프론트 전달 요약 | - | `docs/api/CHANGELOG.md` 기반 요약 텍스트 | 파일 수정 없음 |
| 7 | 승인 요청 준비 | 구현 검증 결과 요약 보고 | PRD 검증 결과 요약 보고 | 승인 판단·답변란 채우기 금지 |

커밋·push는 대행 대상이 아니다(원래 Claude 담당).

계속 금지:

- Claude의 테스트 코드 편집, Codex의 요구사항·PRD·API 문서·`PLAN.md`·소스·빌드 파일 편집 (`edit-guard` 훅이 차단)
- Codex의 작업 브랜치 생성·전환(`work-start`), 개발계획 작성, 구현, 커밋·push·병합
- 병합 충돌 해결, rebase
- 사람 승인 필요 답변란 채우기, 상태를 `승인`으로 바꾸기
- 상대가 하던 구현·문서·테스트 작성을 이어서 하는 것. 원래 담당의 한도가 돌아오면 그쪽에서 이어 간다.

대행한 작업은 `HANDOFF.md` "대행 기록"에 남긴다. 대행 검증에서 `수정 필요`가 나오면 대행자는 고치지 않고, 원래 담당이 다음 세션에서 `HANDOFF.md`를 읽고 처리한다.

## 예외: 진행 중 프로젝트에 하네스 도입

하네스가 없는 프로젝트에 중간 도입할 때만 `harness-adopt` 스킬로 위 절차를 건너뛴다.

- 건너뛰는 것: PRD 승인, 작업 브랜치, ITD 커밋 형식, 보호 브랜치 커밋·push 차단
- 지키는 것: 사용자 승인(`하네스 도입 승인`), 하네스 파일(`.harness/paths`)만 커밋, git 안전 규칙
- 훅이 강제: 보호 브랜치 커밋 시 staged 파일이 모두 `.harness/paths` 안에 있어야 하고, `git add`와 `git commit`을 한 명령에 묶을 수 없다. push할 커밋에 하네스 밖 파일이 있으면 막는다.
- 도입 커밋 이후의 모든 작업(요구사항, PRD, 기존 규약 추출, 기능 구현)은 일반 절차를 따른다.
- 하네스 업데이트(`harness-update`)도 같은 예외를 쓴다. 승인 문구는 `하네스 업데이트 승인`이고 범위는 같다(하네스 파일만).

## 되돌림

되돌림은 모두 같은 작업 브랜치 안에서 `HANDOFF.md`로 인계한다.

- 구현 중 PRD 문제 발견(Claude) → `prd-change` → 재검증, `PRD 승인` → `feature-plan`으로 `PLAN.md` 맞춤, `계획 승인` → `implement` 재개.
- 검증 중 PRD 문제 발견(Codex) → `HANDOFF.md` "PRD 변경 요청"에 기록하고 멈춤 → 같은 폴더의 Claude 세션에서 위와 같이 처리 → Codex 재검증.
- 검증·테스트에서 소스 결함 발견(Codex) → `HANDOFF.md` "구현 수정 요청"에 기록하고 멈춤 → Claude `implement`(수정 요청 반영) → Codex가 같은 REQ에 걸린 검증 항목을 모두 다시 검증. 테스트는 실패했던 TC, 미실행 TC, 수정 파일과 관련된 PASS TC를 다시 실행한다(`test-verify` "재실행 범위").
- 테스트 작성 중 TC를 그대로 구현할 수 없음(Codex) → `HANDOFF.md` "계획 변경 요청" → Claude `feature-plan`(재계획) → `승인 취소` 후 `계획 승인` → Codex `test-write` 재개.
- API 문서와 코드가 다르면 코드를 문서에 맞추는 것이 기본이다. 문서를 바꿔야 하면 "PRD 변경 요청"으로 처리하고 `prd-change`에서 `api-design` 3단계(변경 이력·프론트 영향)를 거친다.

## 검증 원칙

- 작성자와 검증자를 분리한다. 검증은 새 컨텍스트의 에이전트가 원문(요구사항·PRD·코드·테스트 결과)을 직접 읽고 판정한다.
- 검증 에이전트의 결과를 그대로 사용자에게 넘기지 않는다. 메인 세션이 위험이 큰 항목(사람이 바로 승인할 항목, 구체적이지만 주관적인 "일치" 주장, "변경 없음" 단정)을 골라 직접 재현해 본 뒤 보고한다. 재현 결과가 다르면 나머지 "통과" 항목도 다시 확인한다.
- "확인 못한 부분"은 "통과"와 같은 비중으로 생략 없이 보고한다.
- 테스트 통과 주장에는 실제 실행 명령과 결과 요약(성공·실패 수)을 붙인다. 실행하지 않은 테스트를 통과로 쓰지 않는다.
