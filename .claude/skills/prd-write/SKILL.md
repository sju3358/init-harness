---
name: prd-write
description: docs/requirements.md를 바탕으로 PRD(docs/prd/ - 개요·feature 목록, 스킬셋, 공통 사항, 기능별 명세, 배포·운영)를 작성하거나 보완한다. 모든 규정에 근거 REQ를 단다. "PRD 작성", "PRD 보완", "기능 명세 써줘" 요청에 쓴다.
---

# PRD 작성

## 0. 준비

- `docs/requirements.md`, `docs/project.md`, 기존 `docs/prd/**`를 읽는다.
- 작업 브랜치가 `docs/ITD-####`인지 확인한다.
- 이미 `승인` 상태인 PRD를 고치려는 요청이면 이 스킬이 아니라 `prd-change`를 쓴다.

## 1. 구조 결정

- feature를 나눈다. 한 feature는 ITD 티켓·브랜치 하나로 4~5일 프로젝트 안에서 구현할 크기다. 여러 기능이 섞여도 하나의 브랜치로 묶는 게 자연스러우면 한 feature로 둔다.
- feature 목록과 의존 관계를 먼저 사용자에게 보여주고 확인받는다. 확인 전에 기능 명세를 쓰지 않는다.

## 2. 작성

| 문서 | 쓰는 법 |
| --- | --- |
| `00-overview.md` | 목적, 범위·범위 밖(근거 REQ), feature 목록, 변경 이력 |
| `01-skillset.md` | `project.md` 스택 + 라이브러리, 선택 근거, 개발 규약 |
| `02-common.md` | API 응답·에러 코드·예외·인증·로깅·설정·비기능 |
| `features/F-##.md` | `_template.md` 복사. API 목록(ID·메서드·경로만, 상세는 `api-design`), 데이터, 메시지, 비즈니스 규칙, 예외, 인수 조건 |
| `90-deploy-ops.md` | 배포, DB 스키마 관리, 로그·모니터링·알람, 롤백 |

- 모든 규정 행·문장에 근거 REQ를 단다. 고객 요구가 아닌 설계 결정이면 `설계 결정: <이유>`로 쓴다.
- feature 인수 조건은 요구사항 인수 기준을 그대로 옮기거나 더 구체화한다. 기준을 바꾸거나 완화하지 않는다.
- 미결 질문(Q-###)에 걸린 내용은 답을 가정하지 않고 해당 위치에 `미결 Q-###`로 표시한다.
- 요구사항에 없는 기능을 넣지 않는다. 필요해 보이면 사용자에게 제안하고, 받아들여지면 먼저 `requirements.md`에 REQ로 추가한다.

## 3. 마무리

- `sh scripts/check-trace.sh prd`를 실행해 누락을 고친다. 출력은 그대로 보고한다.
- `docs/traceability.md`의 REQ·요약·PRD·feature 열을 채운다.
- 개요 상태는 `작성 중`으로 둔다. 자기 검증으로 `검증 완료`를 쓰지 않는다.
- 다음 단계: `api-design`(feature에 API가 있으면), 그다음 `prd-verify`.
