---
name: itd-commit
description: 커밋·푸시 요청("커밋해줘", "푸시해줘")을 받았을 때 읽는다. Codex는 커밋·push하지 않고 Claude에 넘긴다.
---

# ITD 커밋 (Codex는 실행하지 않음)

커밋·push는 Claude 전용이다. 원본은 `.claude/skills/itd-commit/SKILL.md`이며 Codex는 이 절차를 실행하지 않는다. worktree의 Git 메타데이터가 원본 폴더 `.git/`에 있어 Codex 샌드박스에서는 `git add`·`git commit`이 쓰기 권한 오류로 실패한다.

- `git add`, `git commit`, `git push`를 실행하지 않는다.
- `HANDOFF.md` 다음 행동을 `Claude itd-commit`으로 적고, 사용자에게 같은 worktree의 Claude 세션에서 "커밋해줘"라고 하도록 안내한 뒤 멈춘다.
