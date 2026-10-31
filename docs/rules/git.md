# Git 규칙

## 브랜치

- 통합 브랜치: `docs/project.md`의 값(기본 `main`). `main`·`master`·통합 브랜치에서 직접 편집·커밋하지 않는다.
- worktree를 쓰지 않는다. 프로젝트 폴더 하나에서 티켓마다 작업 브랜치로 전환해 작업한다.
- 작업 브랜치: ITD 티켓 하나당 feature 하나, 브랜치 하나. 문서·계획·구현(Claude)과 테스트·검증(Codex)을 같은 브랜치에서 한다.

| prefix | 용도 |
| --- | --- |
| `feat/ITD-####` | feature (요구사항·PRD·API 문서·계획·구현·테스트) |
| `fix/ITD-####` | 결함 수정 |

- `work-start`가 통합 브랜치에서 `git pull` 후 `git switch -c feat/ITD-####`로 만들고 전환한다. 세션은 그대로 이어 간다.
- Claude·Codex 세션은 같은 프로젝트 폴더에서 연다. 두 세션이 동시에 편집하지 않는다.
- 다른 티켓으로 전환하기 전에 지금 브랜치의 변경을 커밋한다. 미커밋 변경을 안고 브랜치를 바꾸지 않는다.
- 티켓 번호는 `ITD-1234`처럼 숫자 하나이거나 `ITD-1234-5678-9012`처럼 숫자 묶음을 `-`로 이어도 된다. 브랜치·커밋 제목에 같은 번호를 그대로 쓴다.
- 티켓 번호를 모르면 브랜치명을 짓지 않고 사용자에게 묻는다.
- 커밋·push는 Claude가 `itd-commit`으로 한다. Codex는 커밋·push·병합·브랜치 전환을 하지 않는다.
- PR 생성과 병합은 사람이 한다. 에이전트는 작업 브랜치까지만 push한다. 보호 브랜치 push는 `.githooks/pre-push`가 막는다.
- 병합 후 정리는 사용자가 한다: `git switch main`, `git pull`, `git branch -d feat/ITD-####`.

## 커밋 메시지

```
{종류}/ITD-#### {티켓 제목}

- 의미 단위 작업 내용 (3~7개)
```

- `종류`와 티켓 번호는 현재 브랜치명에서 가져온다. `.githooks/commit-msg`가 제목 형식과 브랜치 티켓 일치를 검사한다.
- `fix`는 본문을 `- 원인:`, `- 해결:` 두 줄로 쓴다.
- 커밋은 쌓아도 된다(amend 강제 없음). 이미 push한 커밋은 amend·rebase하지 않는다.
- 산출물(`artifacts/`)만 바뀐 내용은 본문 bullet에 쓰지 않는다.

## 금지 (훅이 차단)

- `git reset --hard`, `git clean -f/-d/-x`, `git branch -D`, 경로 없는 `git checkout -- .`
- bare `git stash`, `git stash pop` (태그 붙인 `git stash push -m`과 `apply <sha>`는 허용)
- `git push --force`/`-f` (`--force-with-lease`도 사용자 승인 후 사용자가 직접 실행)
- `pkill`, `killall`, Windows `taskkill /IM`, `Stop-Process -Name` (포트로 지정해 종료)
- 승인 기록 없는 `git commit`, `git push`
- 보호 브랜치 커밋·push (예외: `harness-adopt`의 `하네스 도입 승인`, 하네스 파일만. `workflow.md` "예외" 참고)
- Codex의 `git commit`·`push`·`merge`·`rebase`·`switch`, 브랜치 전환용 `git checkout`, `git branch <이름>` (승인 기록과 무관하게 차단. 파일 되돌리기는 `git restore <경로>`)

차단을 풀어야 하는 정당한 사유가 있으면 사용자가 터미널에서 직접 실행한다.
