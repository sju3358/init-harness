# 요구사항 추적표

요구사항이 PRD, 구현, 테스트까지 어떻게 이어지는지 기록한다. 검수 산출물로 그대로 쓸 수 있게 유지한다.

- PRD 열: Claude `prd-write`·`prd-change`가 갱신
- 구현·테스트·결과 열: Codex `test-verify`가 갱신
- 누락 검사: `sh scripts/check-trace.sh prd`, `sh scripts/check-trace.sh feature F-##`

| REQ | 요구사항 요약 | PRD | feature | 구현 위치 | 테스트 | 결과 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | | | | | | |

- 결과: `통과` · `실패` · `미검증` (실행 결과가 없으면 `미검증`)
