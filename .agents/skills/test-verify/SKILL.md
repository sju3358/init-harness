---
name: test-verify
description: 테스트를 실행하고, verifier 에이전트로 테스트가 인수 조건을 실제로 검증하는지(유효성) 판정해 TEST-REPORT.md와 요구사항 추적표를 갱신한다. "테스트 검증", "테스트 돌려", "검증 리포트" 요청에 쓴다. Codex를 쓸 수 없을 때 Claude가 대행할 수 있다.
---

# 테스트 검증

## 1. 실행

- `docs/project.md`의 단위·통합 테스트 명령을 실행한다. 결과(성공·실패·건너뜀 수)와 실패 메시지 원문을 `TEST-REPORT.md` "실행"에 적는다.
- 실패하면 원인을 분류한다: 소스 결함 → `implement`, 테스트 결함 → `test-write`, 환경(DB·컨테이너) → 사용자에게 보고. 고친 뒤 전체 테스트를 다시 실행한다.
- `sh scripts/check-trace.sh feature F-##` 출력을 "추적 검사"에 그대로 붙인다.

## 2. 유효성 판정

- `verifier` 에이전트를 `mode=test`로 실행해 "테스트 유효성"을 채우게 한다.
- `약함`·`무효` 판정은 `test-write`로 돌아가 고친 뒤 다시 판정받는다.
- 메인 세션은 `유효` 판정 중 1~2개를 골라 테스트 대상 코드의 해당 조건을 일부러 깨뜨리는 것처럼 생각해 본다. 실제 소스를 바꿔 돌려보는 경우 확인 후 반드시 원복하고 `git diff`로 원복을 확인한다.

## 3. 추적표

- `docs/traceability.md`의 이 feature REQ 행에 구현 위치, 테스트(`TC`), 결과를 채운다. 결과는 실제 실행 결과로만 쓴다(실행 안 했으면 `미검증`).

## 4. 커밋 준비

- 요약 보고: 테스트 결과 수, TC별 유효성, `확인 못한 부분`, 남은 `PRD 변경 요청`.
- 남은 문제가 없으면 `HANDOFF.md` 상태를 갱신하고 다음 행동을 `Claude itd-commit`으로 적은 뒤 멈춘다. 커밋·push는 Codex가 하지 않는다. 사용자에게 같은 worktree의 Claude 세션에서 "커밋해줘"라고 하도록 안내한다.

## Claude 대행

Codex를 쓸 수 없어 사용자가 Claude에게 대행을 요청한 경우(`docs/rules/workflow.md` "대행 작업").

- `verifier` 대신 `code-verifier` 에이전트를 `mode=test`로 실행한다. 메인 세션 재검증은 그대로 한다.
- 빌드·테스트·검사 스크립트는 실행해도 된다. 소스·테스트·`PLAN.md`는 고치지 않는다(훅이 차단).
- `수정 필요`가 나와도 `implement`·`test-write`로 돌아가지 않는다. `TEST-REPORT.md`에 판정을 남기고, `HANDOFF.md` "대행 기록"의 "원래 담당이 할 일"에 수정 항목을 적은 뒤 멈춘다.
