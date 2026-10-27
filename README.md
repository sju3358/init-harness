# init-harness

SI 프로젝트(보통 4~5일 단위)를 위한 **Claude·Codex 분업 하네스**입니다. Claude가 기획과 문서를, Codex가 구현과 테스트를 맡고, 모든 결과물은 요구사항 ID로 이어져 검증됩니다.

**핵심 원칙**

- **역할 분리**: Claude는 문서만, Codex는 코드만 고칩니다. 훅이 서로의 영역 편집을 막습니다.
- **문서가 원본**: 요구사항, PRD, API 문서가 기준입니다. 코드는 문서를 따르고, 문서를 바꿔야 하면 정해진 경로로 되돌아갑니다.
- **사람이 승인**: 다음 단계로 넘어가는 네 지점(PRD, 계획, 커밋, 푸시)은 사용자가 승인 문구를 직접 입력해야 열립니다.
- **작성자 ≠ 검증자**: 검증은 항상 새 컨텍스트의 별도 에이전트가 원문만 보고 판정합니다.
- **ID로 추적**: `REQ → PRD → API → PLAN → 테스트`가 ID로 연결되고, 누락은 스크립트가 기계적으로 찾습니다.

## 목차

1. [요구 환경](#1-요구-환경)
2. [시작하기](#2-시작하기)
3. [전체 흐름](#3-전체-흐름)
4. [단계별 절차](#4-단계별-절차)
5. [승인 게이트](#5-승인-게이트)
6. [추적과 검증](#6-추적과-검증)
7. [되돌림: PRD 변경 요청](#7-되돌림-prd-변경-요청)
8. [대행 작업](#8-대행-작업)
9. [예외: 하네스 도입·업데이트](#9-예외-하네스-도입업데이트)
10. [Git 규칙](#10-git-규칙)
11. [훅이 막는 것](#11-훅이-막는-것)
12. [모델 구성](#12-모델-구성)
13. [디렉터리 구조](#13-디렉터리-구조)
14. [제약사항](#14-제약사항)
15. [문제 해결](#15-문제-해결)

---

## 1. 요구 환경

| 항목 | 내용 |
| --- | --- |
| OS | macOS 또는 Linux (훅이 POSIX `sh`와 심볼릭 링크를 사용) |
| 도구 | `git`, `jq`, Node.js 18 이상, `rsync`(도입 시) |
| AI 도구 | Claude Code (Pro 이상), Codex (Plus 이상) |
| 대상 스택 | Java + Spring Boot 기본. DB·메시지 큐 등은 프로젝트마다 `project-init`에서 결정 |

Claude와 Codex는 **같은 PC의 같은 프로젝트 폴더**에서 씁니다. 승인 기록(`.harness/state/`)이 git에 올라가지 않는 로컬 파일이기 때문입니다.

## 2. 시작하기

상황에 맞는 방법 하나를 고릅니다.

### 2-1. 새 프로젝트

```bash
git clone https://github.com/sju3358/init-harness.git <프로젝트명>
cd <프로젝트명>
git rev-parse HEAD > .harness/version   # 설치한 하네스 버전 기록 (업데이트 기준)
rm -rf .git && git init -b main         # 하네스 이력을 끊고 프로젝트 저장소로 시작
```

Claude 세션을 열고 **"프로젝트 초기 셋팅해줘"** 라고 하면 `project-init`이 다음을 진행합니다.

1. 스택을 질문합니다. Java·Spring Boot 버전, 빌드 도구, DB, ORM, 메시지 큐, 인증, 배포 대상, 테스트 방식을 매번 묻습니다.
2. 답을 `docs/project.md`에 기록하고, 검증 명령(빌드·테스트)이 맞는지 확인받습니다.
3. Git 훅을 등록합니다(`core.hooksPath`).
4. 초기 커밋과 `develop` 브랜치 생성 명령을 안내합니다. 이 작업은 사용자가 직접 실행합니다.

### 2-2. 진행 중인 프로젝트에 도입

하네스가 없는 기존 프로젝트 루트에서 Claude 세션을 열고 **"이 프로젝트에 하네스 도입해줘"** 라고 합니다. `harness-adopt`가 하네스를 받아 기존 파일(`CLAUDE.md`, 설정, Git 훅)과 병합하고, 코드를 읽어 `docs/project.md`를 채웁니다. `하네스 도입 승인`을 입력하면 하네스 파일만 main에 바로 커밋·push합니다. 자세한 내용은 [9장](#9-예외-하네스-도입업데이트)에 있습니다.

### 2-3. 이미 설치된 하네스 업데이트

**"하네스 업데이트해줘"** 라고 합니다. 기준 버전은 `.harness/version`을 쓰고, 이 파일이 없는 구버전 프로젝트는 설치 당시 커밋을 알려줘야 합니다. 구버전 프로젝트에는 `harness-update` 스킬이 없으므로 이렇게 지시합니다.

```
init-harness를 임시 폴더에 clone해서, 그 안의 .claude/skills/harness-update/SKILL.md 절차대로
하네스 업데이트해줘. 기준 커밋은 <설치 당시 커밋>.
```

## 3. 전체 흐름

```mermaid
flowchart TD
    subgraph C["Claude · 기획/문서 (docs/ITD-#### 브랜치)"]
        C1[req-gather<br/>요구사항 도출] --> C2[prd-write<br/>PRD 작성]
        C2 --> C3[api-design<br/>API 문서]
        C3 --> C4[prd-verify<br/>정합성 검증]
        C4 --> G1{{"✋ PRD 승인"}}
    end

    G1 --> M1[사용자: PR·병합]
    M1 --> X1

    subgraph X["Codex · 구현/검증 (feat/ITD-#### 브랜치, feature마다 반복)"]
        X1[feature-start] --> X2[feature-plan<br/>개발계획]
        X2 --> G2{{"✋ 계획 승인"}}
        G2 --> X3[implement<br/>구현]
        X3 --> X4[doc-code-verify<br/>문서-코드 검증]
        X4 --> X5[api-verify<br/>API 검증]
        X5 --> X6[test-write<br/>테스트 작성]
        X6 --> X7[test-verify<br/>테스트 검증]
        X7 --> G3{{"✋ 커밋·푸시 승인"}}
    end

    G3 --> M2[사용자: PR·병합]

    X3 -. PRD 문제 발견 .-> R[HANDOFF.md<br/>PRD 변경 요청]
    X4 -. PRD 문제 발견 .-> R
    X5 -. PRD 문제 발견 .-> R
    R -.-> CH[Claude: prd-change] -.-> C4

    X4 -. 수정 필요 .-> X3
    X5 -. 수정 필요 .-> X3
    X7 -. 수정 필요 .-> X3
```

- PR 생성과 병합은 **사람이 직접** 합니다. 에이전트는 작업 브랜치까지만 push합니다.
- Claude와 Codex는 대화가 아니라 **파일로 인계**합니다. 다음 담당자는 `artifacts/work/F-##/HANDOFF.md`부터 읽습니다.
- 절차의 단일 원본은 [docs/rules/workflow.md](docs/rules/workflow.md)입니다. 이 README는 요약입니다.

## 4. 단계별 절차

### 4-1. Claude: 기획·문서

| 단계 | 이렇게 말하면 | 하는 일 | 산출물 | 다음으로 넘어가는 조건 |
| --- | --- | --- | --- | --- |
| 요구사항 | "요구사항 정리해줘", "Notion 기획서 읽어줘" | Notion(MCP)과 대화에서 요구사항을 뽑아 `REQ-###`, 인수 기준, 출처를 적습니다. 불확실한 건 미결 질문(`Q-###`)으로 분리합니다 | `docs/requirements.md` | 요구사항마다 판정 가능한 인수 기준이 있음 |
| PRD | "PRD 작성해줘" | feature 목록(`F-##`)을 먼저 확인받고 개요, 스킬셋, 공통 사항, 기능별 명세, 배포·운영을 씁니다. 모든 규정에 근거 REQ를 답니다 | `docs/prd/**` | `check-trace.sh prd` 통과 |
| API 문서 | "API 문서 작성해줘" | 프론트 전달용 Markdown 문서를 씁니다. 엔드포인트(`API-###`)마다 필드, 타입, 필수, null 가능, 에러를 적고 변경 이력을 남깁니다. 마지막에 전달용 요약을 줍니다 | `docs/api/**` | PRD의 모든 API가 필드 단위까지 문서화됨 |
| 검증 | "PRD 검증해줘" | `prd-verifier`(새 컨텍스트)가 요구사항, PRD, API를 대조해 판정하고, 메인 세션이 그 결과를 다시 확인합니다 | `docs/verification/prd-verify.md` | 결론 `승인 가능`, 사람 승인 필요 항목 답변 완료 |
| ✋ 승인 | `PRD 승인` 입력 | 요구사항·PRD·API 문서의 내용 해시를 기록합니다 | 문서 상태 `승인 vX.Y` | 이후 Codex가 시작 가능 |

### 4-2. Codex: 구현·검증 (feature 단위)

| 단계 | 이렇게 말하면 | 하는 일 | 산출물 | 다음으로 넘어가는 조건 |
| --- | --- | --- | --- | --- |
| 시작 | "F-01 시작해" | PRD 승인이 유효한지 확인하고, ITD 티켓 번호를 받아 브랜치와 작업 폴더를 만듭니다 | `feat/ITD-####`, `artifacts/work/F-01/` | PRD 승인 유효 |
| 계획 | "개발계획 작성해" | `planner`가 REQ·API → 변경 파일 → 테스트 케이스(`TC-F01-##`)를 매핑합니다. 사람이 정할 항목은 근거와 함께 질문합니다 | `PLAN.md` | 확인 필요 항목 답변 완료 |
| ✋ 승인 | `계획 승인` 입력 | 이 브랜치의 소스 편집을 허용합니다 | | |
| 구현 | "구현 시작해" | 계획과 API 문서대로 구현합니다. 계획에서 벗어나야 하면 멈추고 재승인을 받고, PRD 문제는 변경 요청으로 올립니다 | 소스 코드 | 빌드 통과 |
| 문서-코드 검증 | "정합성 검증해" | `verifier`가 REQ마다 `파일:줄` 근거로 PRD와 코드를 대조합니다 | `VERIFY.md` | 수정 필요 0건 |
| API 검증 | "API 검증해" | `check-api.mjs`로 엔드포인트 목록을 기계 비교하고, `verifier`가 파라미터·필드·에러 코드를 항목별로 대조합니다 | `API-VERIFY.md` | 불일치 0건 |
| 테스트 작성 | "테스트 작성해" | TC마다 테스트를 쓰고 `@DisplayName("[TC-F01-03][REQ-012] ...")`처럼 ID를 붙입니다 | 테스트 코드 | `check-trace.sh feature F-01` 통과 |
| 테스트 검증 | "테스트 검증해" | 테스트를 실행하고, `verifier`가 각 테스트가 인수 조건을 실제로 검사하는지 판정합니다 | `TEST-REPORT.md`, `docs/traceability.md` | 실패 0건, 무효·약함 판정 0건 |
| ✋ 승인 | `커밋 승인`, `푸시 승인` 입력 | ITD 형식으로 커밋하고 작업 브랜치에 push합니다 | 커밋 | |

## 5. 승인 게이트

| 입력 문구 | 열리는 것 | 유효 범위 | 막는 장치 |
| --- | --- | --- | --- |
| `PRD 승인` | Codex 작업 시작 | 요구사항·PRD·API 문서 내용이 바뀌기 전까지 | `prd-check.sh` (해시 비교) |
| `계획 승인` | `src/`·빌드 파일 편집 | 해당 작업 브랜치 | `edit-guard.sh` |
| `커밋 승인` | `git commit` | 30분 | `approval-gate.sh` |
| `푸시 승인` | `git push` | 30분 | `approval-gate.sh` |
| `커밋 푸시 승인` | 커밋과 push 둘 다 | 30분 | `approval-gate.sh` |
| `하네스 도입 승인` / `하네스 업데이트 승인` | 보호 브랜치에 하네스 파일만 커밋·push | 30분, 승인한 브랜치, push 1회 | `approval-gate.sh`, `pre-push` |
| `승인 취소` | 현재 브랜치의 계획·커밋·푸시·도입 승인 삭제 | | |

**규칙**

- 승인 문구는 **한 줄로 단독 입력**해야 인정됩니다. "계획 승인 전에 뭐 해?"처럼 문장 안에 들어간 언급은 무시합니다.
- "진행해", "ㄱㄱ" 같은 일반 응답은 승인이 아닙니다. 에이전트가 정확한 문구를 다시 안내합니다.
- 승인 기록은 **사용자 프롬프트에서만** 만들어집니다. 에이전트가 승인 기록 파일을 직접 만들거나 지우는 명령은 차단됩니다.
- PRD 승인 해시는 `- 상태:` 줄을 빼고 계산합니다. 그래서 승인 후 상태 줄을 `승인 vX.Y`로 바꿔도 승인은 유지되고, 나머지 내용이 한 글자라도 바뀌면 무효가 됩니다.
- 계획 승인 후 범위, 파일, 라이브러리가 바뀌면 `승인 취소` 후 다시 `계획 승인`을 받습니다.

## 6. 추적과 검증

### ID 체계

| ID | 형식 | 정의 위치 | 인용하는 곳 |
| --- | --- | --- | --- |
| 요구사항 | `REQ-###` | `docs/requirements.md` | PRD, API 문서, PLAN, 테스트 |
| feature | `F-##` | `docs/prd/00-overview.md` | API 문서, 작업 폴더 |
| API | `API-###` | `docs/api/<도메인>.md` 제목 | feature 명세, PLAN |
| 테스트 케이스 | `TC-F##-##` | `artifacts/work/F-##/PLAN.md` | 테스트 `@DisplayName` |

ID는 바꾸거나 재사용하지 않습니다. 삭제된 요구사항은 행을 지우지 않고 상태를 `삭제`로 바꿉니다.

### 기계 검사

| 명령 | 잡는 것 |
| --- | --- |
| `sh scripts/check-trace.sh prd` | PRD에 반영 안 된 REQ, 정의 없는 REQ, 삭제된 REQ 인용, feature 명세 누락, API ↔ feature 연결 누락 |
| `sh scripts/check-trace.sh feature F-01` | PLAN에 빠진 REQ·API, 범위 밖 REQ, 테스트에 연결 안 된 REQ·TC, PLAN에 없는 TC |
| `node scripts/check-api.mjs [F-01]` | 문서에는 있는데 코드에 없는 엔드포인트, 코드에만 있는 엔드포인트, 폐기됐는데 남은 엔드포인트, 경로를 해석할 수 없는 매핑 |

기계 검사는 **연결 여부만** 봅니다. 내용이 맞는지는 검증 에이전트가 판정합니다.

### 검증 에이전트

| 에이전트 | 위치 | 검증 대상 |
| --- | --- | --- |
| `prd-verifier` | Claude | 요구사항 ↔ PRD ↔ API 문서 |
| `verifier` mode=code | Codex | PRD·계획 ↔ 코드 |
| `verifier` mode=api | Codex | API 문서 ↔ 컨트롤러·DTO·에러 처리 |
| `verifier` mode=test | Codex | 테스트가 인수 조건을 실제로 검사하는지 |

**검증 원칙**

- 검증 에이전트는 작성자의 자기평가를 근거로 삼지 않고 원문(문서, 코드, 실행 결과)만 봅니다.
- 메인 세션은 검증 결과를 그대로 넘기지 않습니다. 위험이 큰 항목을 직접 재현해 확인하고, 하나라도 다르면 나머지 "통과" 항목도 다시 봅니다.
- "확인 못한 부분"은 "통과"와 같은 비중으로 보고합니다. 실행하지 않은 테스트는 통과로 쓰지 않습니다.

## 7. 되돌림: PRD 변경 요청

Codex는 PRD와 API 문서를 고칠 수 없습니다. 구현이나 검증 중에 문서 문제를 발견하면 아래 순서로 처리합니다.

1. **Codex**: `HANDOFF.md`의 "PRD 변경 요청"에 대상(REQ, API, 문서 위치), 문제, 근거, 제안을 적고 멈춥니다.
2. **사용자**: Claude에서 "PRD 변경 요청 반영해"라고 합니다.
3. **Claude** (`prd-change`): 요청마다 근거를 보여주고 사용자가 반영 / 반려 / 고객 확인 중 하나를 정합니다. 반영하면 버전을 올리고, API가 바뀌었으면 `CHANGELOG.md`에 프론트 영향을 적습니다.
4. **Claude**: 재검증합니다. 문서가 바뀌었으므로 `PRD 승인`을 다시 받습니다.
5. **Codex**: 영향받는 feature의 계획을 다시 맞추고 `계획 승인`부터 재개합니다.

API 문서와 코드가 다를 때는 **코드를 문서에 맞추는 것이 기본**입니다. 문서를 바꿔야 할 때만 위 경로를 탑니다.

## 8. 대행 작업

한쪽 도구의 토큰이 부족할 때 사용자가 요청하면 다른 도구가 대신할 수 있습니다. 기준은 **상대가 만든 결과물(문서 내용, 코드, 계획)은 바꾸지 않고 실행·검증·기록만 대신하는 것**입니다.

| 작업 | Claude가 대행 (Codex 영역) | Codex가 대행 (Claude 영역) |
| --- | --- | --- |
| 커밋·push | 구현 커밋 | 문서 커밋 |
| 기계 검사 | `check-trace.sh feature`, `check-api.mjs` | `check-trace.sh prd` |
| 빌드·테스트 실행 | 실행하고 `TEST-REPORT.md`에 기록 | - |
| 검증 판정 | 문서-코드, API, 테스트 유효성 (`code-verifier`) | PRD 정합성 (`verifier` mode=prd) |
| feature 시작 준비 | 브랜치 생성, 템플릿 복사 | - |
| 인계 정리 | `HANDOFF.md` 상태·대행 기록 | 같음 |
| 통합 브랜치 반영 | 충돌 없을 때만 병합 | 같음 |
| 프론트 전달 요약 | - | `CHANGELOG.md` 기반 요약 |

**대행 중에도 금지**: 상대 영역 편집(훅이 차단), 병합 충돌 해결, 승인 답변란 채우기, 상대가 하던 구현이나 문서 작성을 이어서 하기. 대행 검증에서 "수정 필요"가 나오면 대행한 쪽은 고치지 않고 `HANDOFF.md` "대행 기록"에 남깁니다.

## 9. 예외: 하네스 도입·업데이트

하네스 절차를 건너뛰는 유일한 예외입니다. 하네스 파일 자체를 설치하거나 갱신할 때만 씁니다.

| | 도입 (`harness-adopt`) | 업데이트 (`harness-update`) |
| --- | --- | --- |
| 대상 | 하네스가 없는 진행 중 프로젝트 | 하네스가 설치된 프로젝트 |
| 하는 일 | 하네스 복사(기존 파일 덮어쓰지 않음) → 충돌 파일 병합 → `project.md` 채우기 → 문서화 범위 결정 | 기준 버전 ↔ 프로젝트 ↔ 새 버전 3-way 병합 → 충돌 정리 → 템플릿 변경 보고 |
| 승인 문구 | `하네스 도입 승인` | `하네스 업데이트 승인` |

**건너뛰는 것**: PRD 승인, 작업 브랜치, ITD 커밋 형식, 보호 브랜치 차단

**그대로 지키는 것** (훅이 강제)

- 커밋할 수 있는 파일은 [.harness/paths](.harness/paths)에 적힌 하네스 파일뿐입니다. 소스가 섞이면 차단합니다.
- `git add`와 `git commit`은 따로 실행해야 합니다(staged 파일 검사). `commit -a`도 차단합니다.
- 승인은 30분 동안, 승인한 브랜치에서만 유효하고 push 1회 후 삭제됩니다.

**업데이트 시 파일 처리**

| 파일 | 처리 |
| --- | --- |
| 프로젝트가 안 고친 하네스 파일 | 새 버전으로 교체 |
| 양쪽이 고친 하네스 파일 | 자동 병합. 같은 곳을 고쳤으면 충돌 표시를 남기고 사람이 정리 |
| 프로젝트가 채운 문서 ([.harness/seed](.harness/seed)) | 덮어쓰지 않음. 템플릿 변경만 `.harness/update/seed/*.diff`로 보고 |
| 새 버전에서 삭제된 파일 | 프로젝트가 안 고쳤을 때만 삭제 |

> 업데이트로 `docs/requirements.md`, `docs/prd/`, `docs/api/` 내용이 바뀌거나 파일이 추가되면 PRD 승인이 무효가 됩니다. 진행 중인 feature가 있으면 업데이트 시점을 고려합니다.

## 10. Git 규칙

### 브랜치

| 브랜치 | 용도 | 담당 |
| --- | --- | --- |
| `main`, `master`, 통합 브랜치(기본 `develop`) | 보호 브랜치. 직접 편집·커밋·push 금지 | 사람이 PR로 병합 |
| `feat/ITD-####` | feature 구현 (feature 1개 = 티켓 1개 = 브랜치 1개) | Codex |
| `fix/ITD-####` | 결함 수정 | Codex |
| `docs/ITD-####` | 요구사항·PRD·API 문서 작성·변경 | Claude |

티켓 번호를 모르면 에이전트가 브랜치명을 짓지 않고 사용자에게 묻습니다.

### 커밋 메시지

```
feat/ITD-1234 주문 조회 API 추가

- 주문 단건·목록 조회 API와 응답 DTO 추가
- 주문 미존재 시 ORDER_NOT_FOUND 에러 처리
```

- 제목의 `{종류}/ITD-####`는 현재 브랜치명과 같아야 합니다(`commit-msg` 훅이 검사).
- `fix`는 본문을 `- 원인:`, `- 해결:` 두 줄로 씁니다.
- 커밋은 쌓아도 됩니다. 이미 push한 커밋은 amend하지 않습니다.

## 11. 훅이 막는 것

훅 스크립트는 `.harness/hooks/`에 있고, Claude와 Codex가 같은 스크립트를 씁니다.

| 훅 | 시점 | 막는 것 |
| --- | --- | --- |
| `edit-guard.sh` | 파일 편집 전 | Claude의 소스·빌드·`PLAN.md` 편집 / Codex의 요구사항·PRD·API 문서 편집 / 계획 승인 없는 소스 편집 / 작업 브랜치가 아닌 곳에서의 소스 편집 / 승인 기록 파일 편집 |
| `approval-gate.sh` | 셸 명령 전 | 승인 없는 commit·push / 보호 브랜치 커밋 / 승인 기록 조작 / 하네스 예외 범위를 벗어난 커밋·push |
| `git-safety-guard.sh` | 셸 명령 전 | `reset --hard`, `clean -f`, `branch -D`, `checkout -- .`, 강제 push, bare `stash`·`stash pop`, `pkill`·`killall` |
| `record-approval.sh` | 사용자 입력 시 | (막지 않음) 승인 문구 기록 |
| `.githooks/commit-msg` | 커밋 시 | 작업 브랜치에서 ITD 형식이 아니거나 티켓이 브랜치와 다른 커밋 |
| `.githooks/pre-push` | push 시 | 보호 브랜치 push (하네스 예외 1회 제외) |

차단된 작업이 정말 필요하면 **사용자가 터미널에서 직접** 실행합니다. 에이전트는 우회하지 않습니다.

## 12. 모델 구성

| 위치 | 모델 | 용도 | 설정 파일 |
| --- | --- | --- | --- |
| Claude 메인 | Opus 5.5 | 요구사항 도출, PRD·API 문서 작성 | `.claude/settings.json` |
| Claude `prd-verifier` | Opus 5.5 | PRD 정합성 검증 | `.claude/agents/prd-verifier.md` |
| Claude `code-verifier` | Opus 5.5 | 구현 검증 대행 | `.claude/agents/code-verifier.md` |
| Codex 메인 | gpt-6-luna, medium | 구현, 테스트 작성 | `.codex/config.toml` |
| Codex `planner` | gpt-6.1-sol, high | 개발계획 | `.codex/agents/planner.toml` |
| Codex `verifier` | gpt-6.1-sol, high | 문서-코드·API·테스트 검증, PRD 검증 대행 | `.codex/agents/verifier.toml` |

Pro·Plus 사용량 한도를 고려해 상위 모델은 계획과 검증에만 씁니다. 양이 많은 구현은 가벼운 모델이 맡습니다.

## 13. 디렉터리 구조

```
.
├── CLAUDE.md                  Claude 진입점 (역할, 스킬 표, 대행 범위)
├── AGENTS.md                  Codex 진입점
├── docs/
│   ├── project.md             프로젝트 스택·검증 명령·브랜치 (project-init이 채움)
│   ├── requirements.md        요구사항 REQ-### · 미결 질문 Q-###
│   ├── prd/
│   │   ├── 00-overview.md     목적·범위·feature 목록·변경 이력
│   │   ├── 01-skillset.md     기술 스택·라이브러리·개발 규약
│   │   ├── 02-common.md       공통 규약(응답·에러·인증·로깅·비기능)
│   │   ├── 90-deploy-ops.md   배포·로깅·모니터링·롤백
│   │   └── features/F-##.md   기능별 명세 (_template.md 복사)
│   ├── api/                   프론트 전달용 API 문서 (README, 도메인별, CHANGELOG)
│   ├── traceability.md        요구사항 추적표 (검수 산출물)
│   ├── verification/          PRD 검증 결과
│   └── rules/                 workflow(절차 원본) · common · principles(개발 원칙) · git
├── artifacts/work/F-##/       feature별 PLAN · VERIFY · API-VERIFY · TEST-REPORT · HANDOFF
├── .claude/                   Claude 설정·스킬·에이전트
├── .codex/                    Codex 설정·훅 등록·에이전트
├── .agents/skills/            Codex 스킬 (일부는 .claude/skills와 링크로 공유)
├── .harness/
│   ├── hooks/                 공용 훅 스크립트
│   ├── paths · seed           하네스 소유 경로 · 프로젝트가 채우는 문서 목록
│   ├── update.sh              하네스 업데이트 스크립트
│   ├── version                설치된 하네스 버전 (프로젝트에서 생성)
│   └── state/                 승인 기록 (git 제외)
├── .githooks/                 commit-msg · pre-push
└── scripts/                   check-trace.sh · check-api.mjs
```

## 14. 제약사항

| 제약 | 내용 | 대응 |
| --- | --- | --- |
| 셸 쓰기 우회 | 편집 차단은 에디터 도구(Edit·Write·apply_patch) 기준이라, `sed -i`나 `cat >`로 쓰면 막지 못합니다 | 규칙으로 금지하고, 검증 단계에서 `git diff`로 계획과 대조 |
| 같은 PC 전제 | 승인 기록은 로컬 파일입니다 | 다른 PC에서는 승인을 다시 입력 |
| 훅 로드 시점 | Claude는 세션 시작 때 훅 등록을 읽습니다. 훅 스크립트 내용 변경은 바로 반영되지만, 등록(`settings.json`) 변경은 재시작해야 반영됩니다 | 하네스 도입 직후나 설정 변경 후에는 세션 재시작 |
| Codex 신뢰 | `.codex/config.toml`·`hooks.json`은 신뢰된 프로젝트에서만 적용됩니다 | 처음 열 때 프로젝트 신뢰 허용 |
| API 기계 비교 범위 | `check-api.mjs`는 메서드와 경로만 비교합니다. 상수나 프로퍼티로 만든 경로는 해석하지 못합니다 | 필드 단위 대조는 `verifier`, 해석 불가 항목은 직접 확인. context-path는 `project.md`의 `API 경로 접두어`에 기록 |
| worktree | 훅이 세션 폴더 기준이라, 별도 worktree에서 커밋하면 승인 기록 위치가 어긋날 수 있습니다 | 작업은 세션을 연 폴더에서 진행 |
| 계획 승인 후 PRD 변경 | 계획 승인 뒤 PRD가 바뀌어도 계획 승인 기록은 자동으로 무효가 되지 않습니다 | `prd-change`가 영향받는 feature의 재계획을 안내. 재개 전 `승인 취소` 후 재승인 |
| Codex 모델 서열 | 현재 모델 배분은 운용 전 추정입니다 | 한 프로젝트 운용 후 사용량을 보고 조정 |

## 15. 문제 해결

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| "계획 승인 기록 없음"으로 편집 차단 | 현재 브랜치에 계획 승인이 없음 | `PLAN.md`를 확인하고 `계획 승인` 입력 |
| 승인 문구를 입력했는데 반응이 없음 | 문장 안에 넣었거나, 작업 브랜치가 아니거나, 훅이 로드되지 않음 | 한 줄로 단독 입력. 브랜치 확인. 세션 재시작 |
| "PRD 승인 이후 내용이 바뀜" | 승인 후 요구사항·PRD·API 문서가 수정됨 | Claude에서 재검증 후 `PRD 승인` 다시 입력 |
| 커밋·push가 "승인 기록 없음"으로 차단 | 승인 후 30분이 지남 | 다시 `커밋 승인`·`푸시 승인` 입력 |
| main·develop push 차단 | 보호 브랜치 | 작업 브랜치에 push하고 PR로 병합. 사람이 꼭 직접 해야 하면 `git push --no-verify` |
| 커밋 메시지 형식 오류 | 제목이 `{종류}/ITD-#### 제목`이 아니거나 티켓이 브랜치와 다름 | 브랜치명과 같은 접두어로 다시 작성 |
| 훅이 전혀 동작하지 않음 | Git 훅 미등록, Codex 프로젝트 미신뢰, Claude 세션이 하네스 설치 전에 시작됨 | `git config core.hooksPath .githooks`, Codex에서 프로젝트 신뢰, Claude 세션 재시작 |
| 승인 기록을 초기화하고 싶음 | | `승인 취소` 입력 (현재 브랜치 기준) |
