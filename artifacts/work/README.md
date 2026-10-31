# feature 작업 산출물

feature마다 그 feature의 작업 브랜치에 `artifacts/work/F-##/`를 만들고 `_template/`의 파일을 복사해 쓴다(Claude `feature-plan`이 수행).

| 파일 | 작성 | 내용 |
| --- | --- | --- |
| `PLAN.md` | Claude `feature-plan` | REQ ↔ 변경 파일 ↔ TC 매핑, 확인 필요, 계획 변경 이력 |
| `VERIFY.md` | Codex `verifier` | 문서-코드 정합성 판정표 |
| `API-VERIFY.md` | Codex `verifier` | API 문서-코드 엔드포인트·항목별 판정표 |
| `TEST-REPORT.md` | Codex `test-verify` | 회차별 실행 범위·결과, 명세 누락, 테스트 유효성 판정 |
| `test-status.md` | Codex `test-write`·`test-verify` | TC별 최신 상태(`PASS`·`FAIL`·`미실행`)와 마지막 전체 회귀. 재실행 범위의 기준 |
| `HANDOFF.md` | Codex·Claude | 현재 상태, 진행 위치, 다음 행동, 구현 수정 요청·계획 변경 요청·PRD 변경 요청 |

- 세션이 바뀌거나 Claude ↔ Codex로 넘어갈 때 다음 담당자는 같은 폴더·브랜치에서 `HANDOFF.md`부터 읽는다. 대화 내용만으로 인계하지 않는다.
- 산출물은 커밋에 포함하되 커밋 본문에는 쓰지 않는다.
- 코드 주석에 산출물 파일 경로를 인용하지 않는다(정리·이동될 수 있음).
