---
name: test-write
description: 개발계획(PLAN.md)의 테스트 케이스(TC)를 테스트 코드로 작성한다. 각 테스트에 TC·REQ ID를 달아 추적한다. "테스트 코드 작성", "테스트 짜줘" 요청에 쓴다.
---

# 테스트 작성

## 1. 전제

- `VERIFY.md`의 `수정 필요`가 모두 해소됐는지 확인한다. 남아 있으면 `implement`로 돌아간다.
- `docs/project.md`의 테스트 스택(JUnit 5, AssertJ, Mockito, Testcontainers 여부)을 따른다.

## 2. 작성

- `PLAN.md` 테스트 케이스 표의 TC마다 테스트 메서드를 하나 이상 만든다.
- 추적 표기: `@DisplayName("[TC-F01-03][REQ-012] 재고 부족 시 주문 거절")`처럼 TC와 REQ를 함께 적는다. `check-trace.sh`가 이 표기를 찾는다.
- 단언은 TC의 기대 결과를 구체 값으로 확인한다(상태 코드만이 아니라 응답 본문·에러 코드·저장된 데이터까지).
- 금지:
  - 테스트 대상 클래스 자체를 목으로 대체
  - 구현 로직을 테스트 안에 복제해 같은 계산 결과끼리 비교
  - 단언 없는 테스트, 예외를 삼키는 테스트
  - 실패하는 테스트를 통과시키려고 소스나 기대값을 바꾸는 것. 소스 결함이면 멈추고 보고한다(수정은 `implement`로).
- 외부 시스템(메시지 큐, 외부 API)은 `PLAN.md`가 정한 방식(Testcontainers, 목 서버 등)을 따른다. 정하지 않았으면 사용자에게 묻는다.

## 3. 마무리

- `sh scripts/check-trace.sh feature F-##`가 `문제 없음`이어야 한다.
- `HANDOFF.md` 다음 행동을 `test-verify`로 갱신한다. 테스트 실행 결과는 다음 단계에서 기록한다.
