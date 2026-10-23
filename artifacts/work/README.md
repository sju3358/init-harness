# feature 작업 산출물

feature마다 `artifacts/work/F-##/`를 만들고 `_template/`의 파일을 복사해 쓴다(`feature-start`가 수행).

| 파일 | 작성 | 내용 |
| --- | --- | --- |
| `PLAN.md` | Codex `planner` | REQ ↔ 변경 파일 ↔ TC 매핑, 확인 필요, 구현 중 변경 |
| `VERIFY.md` | Codex `verifier` | 문서-코드 정합성 판정표 |
| `TEST-REPORT.md` | Codex `test-verify` | 테스트 실행 결과와 테스트 유효성 판정 |
| `HANDOFF.md` | Codex·Claude | 현재 상태, 다음 행동, PRD 변경 요청 |

- 세션이 바뀌거나 Claude ↔ Codex로 넘어갈 때 다음 담당자는 `HANDOFF.md`부터 읽는다. 대화 내용만으로 인계하지 않는다.
- 산출물은 커밋에 포함하되 커밋 본문에는 쓰지 않는다.
- 코드 주석에 산출물 파일 경로를 인용하지 않는다(정리·이동될 수 있음).
