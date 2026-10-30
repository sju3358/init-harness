---
name: work-start
description: ITD 티켓 하나의 작업 브랜치(feat|fix/ITD-####)와 worktree(../<원본 폴더명>-ITD-####)를 원본 폴더의 통합 브랜치에서 만든다. 티켓 하나에서 요구사항·PRD·API·계획(Claude)과 구현·테스트(Codex)를 모두 진행한다. "작업 시작", "티켓 시작", "F-01 시작", "worktree 만들어줘" 요청에 쓴다.
---

# 작업 시작

티켓 하나 = feature 하나 = 브랜치 하나 = worktree 하나다(`docs/rules/git.md`). 이 스킬은 원본 폴더에서 worktree만 만들고, 문서·계획 작업은 새 worktree의 세션에서 한다.

## 1. 전제 확인

- 원본 폴더에서 실행한다. `git rev-parse --abbrev-ref HEAD`가 통합 브랜치(`docs/project.md`, 기본 `main`)가 아니면 멈추고 원본 폴더에서 다시 열도록 안내한다.
- `git status`로 미커밋 변경이 없는지 확인한다. 있으면 멈추고 알린다.
- `docs/project.md`가 비어 있으면 `project-init`부터 하라고 안내한다.

## 2. 티켓 확인

- ITD 티켓 번호, 종류(`feat`·`fix`), 대상(새 feature / 기존 `F-##` 변경 / 결함)을 사용자에게 묻는다. 브랜치명을 스스로 짓지 않는다.
- `git worktree list`에 같은 티켓의 worktree가 있으면 새로 만들지 않고 그 폴더 경로를 알려 이어 하기로 전환한다.

## 3. worktree 생성

```bash
git pull
git worktree add -b feat/ITD-#### "../$(basename "$PWD")-ITD-####" <통합 브랜치>
```

- 브랜치가 이미 원격에 있으면 `-b` 없이 `git worktree add "../<폴더>" feat/ITD-####`로 만든다.
- worktree는 원본 폴더와 Git 이력·설정(`core.hooksPath` 포함)을 공유한다. 승인 기록(`.harness/state/`)은 worktree마다 따로 남는다.

## 4. 보고

- worktree 경로, 브랜치, 기준 커밋을 보고한다.
- 다음 행동을 안내한다: 그 폴더에서 새 Claude 세션을 연다(VS Code: `code <worktree 경로>`). 새 feature면 `req-gather`부터, 기존 feature의 요구·PRD 변경이면 `prd-change`부터 한다.
- 결함 수정처럼 문서를 바꾸지 않는 티켓은 바로 `feature-plan`으로 간다. 승인 기록은 worktree마다 따로라서, 통합 브랜치의 문서가 이미 `승인` 상태임을 보여준 뒤 이 worktree 세션에서 `PRD 승인`을 다시 입력받는다.
- 이 세션(원본 폴더)에서 이어서 문서를 쓰지 않는다. 원본 폴더의 문서·계획·코드 편집은 훅이 막는다.
- 병합 후 정리는 사용자가 원본 폴더에서 한다고 알린다: `git pull`, `git worktree remove <worktree 경로>`, `git branch -d feat/ITD-####`.
