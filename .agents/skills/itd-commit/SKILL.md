---
name: itd-commit
description: 커밋·푸시 요청("커밋해줘", "푸시해줘")을 받았을 때 읽는다. Codex는 커밋·push하지 않고 Claude에 넘긴다.
---

# ITD 커밋 (Codex는 실행하지 않음)

커밋·push는 Claude 전용이다. 원본은 `.claude/skills/itd-commit/SKILL.md`이며 Codex는 이 절차를 실행하지 않는다. 미검증 경고·ITD 메시지·승인 확인을 Claude `itd-commit` 한 곳에서 처리하기 위함이다.

- `git add`, `git commit`, `git push`를 실행하지 않는다.
- `HANDOFF.md` 다음 행동을 `Claude itd-commit`으로 적고, 사용자에게 같은 폴더의 Claude 세션에서 "커밋해줘"라고 하도록 안내한 뒤 멈춘다.
