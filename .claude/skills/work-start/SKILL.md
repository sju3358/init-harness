---
name: work-start
description: ITD 티켓 하나의 작업 브랜치(feat|fix/ITD-####)를 통합 브랜치에서 만들어 같은 폴더에서 전환하고, 같은 세션에서 바로 이어 간다. 티켓 하나에서 요구사항·PRD·API·계획·구현(Claude)과 테스트·검증(Codex)을 모두 진행한다. "작업 시작", "티켓 시작", "F-01 시작", "브랜치 만들어줘" 요청에 쓴다.
---

# 작업 시작

티켓 하나 = feature 하나 = 브랜치 하나다(`docs/rules/git.md`). worktree는 만들지 않는다. 이 폴더에서 작업 브랜치로 전환하고, 이 세션에서 이어서 문서·계획 작업을 한다.

## 1. 전제 확인

- `docs/project.md`가 비어 있으면 `project-init`부터 하라고 안내한다.
- `git status --short`로 미커밋 변경이 없는지 확인한다. 있으면 멈추고 알린다. 지금 브랜치의 작업이면 `itd-commit`으로 커밋한 뒤 다시 시작한다. 미커밋 변경을 안고 브랜치를 바꾸지 않는다.
- 현재 브랜치가 통합 브랜치(`docs/project.md`, 기본 `main`)가 아니고 작업 브랜치면, 그 티켓을 이어 할지 새 티켓으로 전환할지 사용자에게 묻는다.

## 2. 티켓 확인

- ITD 티켓 번호, 종류(`feat`·`fix`), 대상(새 feature / 기존 `F-##` 변경 / 결함)을 사용자에게 묻는다. 브랜치명을 스스로 짓지 않는다.
- 같은 티켓 브랜치가 로컬(`git branch --list`)이나 원격(`git branch -r --list`)에 있으면 새로 만들지 않고 그 브랜치로 전환해 이어 한다.

## 3. 브랜치 생성·전환

```bash
git switch <통합 브랜치>
git pull
git switch -c feat/ITD-####
```

- 브랜치가 이미 있으면 `git switch feat/ITD-####`(원격에만 있으면 `git switch --track origin/feat/ITD-####`)로 전환한다.
- 승인 기록(`.harness/state/`)은 이 폴더에 하나로 남는다. 계획 승인은 브랜치별이고, PRD 승인은 문서 해시라 브랜치를 바꿔 문서가 달라지면 다시 받아야 한다.

## 4. 보고

- 브랜치, 기준 커밋을 보고한다.
- 다음 행동을 안내하고 이 세션에서 이어 간다. 새 feature면 `req-gather`부터, 기존 feature의 요구·PRD 변경이면 `prd-change`부터 한다.
- 결함 수정처럼 문서를 바꾸지 않는 티켓은 바로 `feature-plan`으로 간다. 통합 브랜치의 문서가 이미 `승인` 상태임을 보여주고 `sh .harness/hooks/prd-check.sh`를 실행한다. `PRD 승인 유효`가 아니면 이 브랜치에서 `PRD 승인`을 다시 입력받는다(승인 해시가 이 브랜치 문서 기준이어야 함).
- Codex도 같은 폴더의 Codex 세션에서 이어 받는다고 알린다.
- 병합 후 정리는 사용자가 한다고 알린다: `git switch main`, `git pull`, `git branch -d feat/ITD-####`.
