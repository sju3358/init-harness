# Git 규칙

## 브랜치

- 통합 브랜치: `docs/project.md`의 값(기본 `develop`). `main`·`master`·통합 브랜치에서 직접 편집·커밋하지 않는다.
- 작업 브랜치: feature 하나당 ITD 티켓 하나, 브랜치 하나.

| prefix | 용도 | 담당 |
| --- | --- | --- |
| `feat/ITD-####` | feature 구현 | Codex |
| `fix/ITD-####` | 결함 수정 | Codex |
| `docs/ITD-####` | 요구사항·PRD 작성·변경 | Claude |

- 티켓 번호를 모르면 브랜치명을 짓지 않고 사용자에게 묻는다.
- 작업 전 `git status && git branch`로 상태를 확인하고, origin보다 뒤처졌으면 `git pull` 후 분기한다.
- PR 생성과 병합은 사람이 한다. 에이전트는 feature 브랜치까지만 push한다. 보호 브랜치 push는 `.githooks/pre-push`가 막는다.

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
- `pkill`, `killall` (포트로 지정해 종료)
- 승인 기록 없는 `git commit`, `git push`

차단을 풀어야 하는 정당한 사유가 있으면 사용자가 터미널에서 직접 실행한다.
