---
name: api-verify
description: 구현된 컨트롤러·DTO·예외 처리가 API 문서(docs/api/*.md)와 일치하는지 검증한다. 엔드포인트 목록은 check-api.mjs로 기계 비교하고, 파라미터·필드·에러 코드는 verifier 에이전트(mode=api)가 대조한다. "API 검증", "API 문서와 코드 대조" 요청과 doc-code-verify 다음 단계에 쓴다.
---

# API 문서-코드 검증

API 문서는 프론트엔드가 그대로 믿고 개발하는 계약이다. 문서와 다른 코드는 "동작한다"여도 결함으로 본다. API 문서는 Codex가 고치지 않는다.

## 1. 기계 비교

- `node scripts/check-api.mjs F-##`를 실행해 이 feature의 문서 엔드포인트가 코드에 모두 매핑됐는지 본다.
- `node scripts/check-api.mjs`(전체)도 실행해 문서에 없는 엔드포인트가 새로 생겼는지 본다. 이번 feature 브랜치에서 추가한 매핑이 `문서 누락`이면 결함이다. 기존부터 있던 것이면 `확인 못한 부분`이 아니라 "기존 미문서화"로 따로 보고한다.
- 출력 원문을 `artifacts/work/F-##/API-VERIFY.md` "기계 비교"에 붙인다. `해석 불가` 항목은 verifier가 직접 확인할 목록으로 넘긴다.

## 2. 필드 단위 대조

- `verifier` 에이전트를 `mode=api`로 실행한다. 프롬프트에는 feature ID, API 문서 버전, 산출물 경로(`API-VERIFY.md`)만 준다.
- 대조 항목(엔드포인트마다): 메서드·경로, Path·Query 파라미터(이름, 타입, 필수, 기본값), Request Body 필드(이름, 타입, 필수, 검증 제약), Response 필드(이름, 타입, null 가능, 직렬화 이름), 응답 상태 코드, 에러 코드와 HTTP 상태, 인증·권한, 페이지네이션·정렬, 날짜·enum 형식.
- 직렬화 설정(`@JsonProperty`, `@JsonInclude`, Jackson 전역 설정, naming strategy)이 실제 필드 이름·null 처리를 바꾸는지까지 확인한다.

## 3. 메인 세션 재검증

- verifier가 `일치`로 판정한 엔드포인트 중 Request Body나 에러 코드가 많은 것 1~2개를 골라 직접 대조한다.
- 가능하면 MockMvc 테스트 결과나 로컬 실행 응답으로 실제 JSON을 확인해 문서 예시와 비교한다(필드 이름, null 필드 생략 여부). 확인한 방법을 "메인 세션 재검증"에 적는다.
- 재현 결과가 다르면 나머지 `일치` 항목도 다시 확인한다.

## 4. 결과 처리

- 코드가 문서와 다름: `implement`로 돌아가 코드를 문서에 맞춘다.
- 문서가 틀렸거나 빠짐(구현 중 정당한 이유로 바뀌어야 함): 코드를 문서와 다르게 둔 채 넘어가지 않는다. `HANDOFF.md` "PRD 변경 요청"에 대상 `API-###`와 바꿀 내용을 적고 멈춘다(Claude `prd-change` → `api-design`).
- 보고에는 `확인 못한 부분`과 `해석 불가` 항목을 생략 없이 넣는다.
- 정리되면 `HANDOFF.md` 다음 행동을 `test-write`로 갱신한다.
