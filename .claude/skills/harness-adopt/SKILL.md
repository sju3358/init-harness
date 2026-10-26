---
name: harness-adopt
description: 하네스가 없는 진행 중 프로젝트에 하네스를 도입한다. 하네스 절차(PRD 승인·작업 브랜치·ITD 커밋)를 건너뛰고, 충돌 파일을 정리한 뒤 하네스 파일만 '하네스 도입 승인'을 받아 보호 브랜치(main 등)에 바로 커밋·push한다. "이 프로젝트에 하네스 적용", "하네스 도입", "중간에 하네스 구축" 요청에 쓴다.
---

# 하네스 도입 (진행 중 프로젝트)

이 스킬은 하네스 절차의 유일한 예외다. 예외 범위는 **하네스 파일(`.harness/paths`)을 보호 브랜치에 한 번 커밋·push하는 것**뿐이다. 소스 코드, 기존 문서 수정, 기능 작업은 예외에 포함되지 않는다.

## 0. 사전 확인

- 프로젝트 루트에서 실행한다. `.harness/paths`가 이미 있으면 도입된 프로젝트이므로 멈추고 알린다.
- `git status`가 깨끗해야 한다. 미커밋 변경이 있으면 멈추고 사용자가 정리하게 한다(하네스 파일과 섞이지 않게).
- 현재 브랜치를 확인한다. 도입 대상 브랜치(보통 `main`)가 맞는지 사용자에게 확인하고, `git pull`로 최신화한다.
- 진행 중인 작업 브랜치가 있으면 목록만 보고한다(도입 후 `feature-plan`으로 이어 붙일 대상).

## 1. 하네스 파일 복사

```bash
tmp=$(mktemp -d)
git clone --depth 1 https://github.com/sju3358/init-harness.git "$tmp/harness"
rsync -a --ignore-existing --exclude .git --exclude README.md "$tmp/harness/" ./
git -C "$tmp/harness" rev-parse HEAD > .harness/version   # 이후 harness-update의 기준 버전
rm -rf "$tmp"
```

- `--ignore-existing`라 기존 파일은 덮어쓰지 않는다. 복사 후 하네스 원본과 내용이 달라 건너뛴 파일 목록을 만든다(`CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.gitignore`, `docs/` 하위 등).

## 2. 충돌 파일 병합

| 파일 | 병합 |
| --- | --- |
| `CLAUDE.md`, `AGENTS.md` | 기존 내용을 "프로젝트 규칙" 절로 남기고 하네스 내용을 위에 추가. 기존 규칙과 하네스 규칙이 상반되면 목록으로 보고하고 사용자가 정함 |
| `.claude/settings.json` | 기존 `permissions`를 유지하고 하네스 `hooks`·`model`·허용 목록을 합침. JSON 유효성 확인 |
| `.codex/config.toml`, `.codex/hooks.json` | 기존 설정 유지, 하네스 항목 추가 |
| `.gitignore` | `.harness/state/` 줄 추가 |
| Git 훅 | `core.hooksPath`가 없으면 `git config core.hooksPath .githooks`. Husky 등 기존 훅이 있으면 기존 훅 파일 끝에 `.githooks/commit-msg "$1"`, `.githooks/pre-push "$@"` 호출을 추가 |

- 기존 프로젝트 파일(소스, 기존 문서)은 고치지 않는다. 고쳐야 할 것 같으면 도입 후 작업으로 보고한다.

## 3. 프로젝트 값 채우기

- `docs/project.md`를 코드(`build.gradle*`, `pom.xml`, `application*.yml`, 컨트롤러 매핑)에서 읽어 채운 뒤 사용자에게 확인받는다. 모르는 값은 비운다.
- 멀티모듈이면 모듈 목록과 각 모듈의 소스 경로를 `디렉터리` 표에 적는다.
- 컨트롤러 경로 앞에 붙는 context-path가 있으면 `API 경로 접두어`에 적는다.
- 통합 브랜치(develop 등)와 보호 브랜치를 확인해 적는다.

## 4. 문서화 범위 결정

사용자에게 고르게 한다.

| 방식 | 내용 |
| --- | --- |
| 남은 범위만 (추천) | `requirements.md`에는 앞으로 할 작업만 REQ로. 기존 기능은 `범위 밖`에 "기존 구현"으로 |
| 전체 역추출 | 기존 기능까지 REQ·PRD·API 문서로 작성 (검수용 전체 추적표가 필요할 때) |

- 이 단계에서는 결정만 `docs/project.md`에 적고, 실제 요구사항·PRD 작성은 도입 후 일반 절차(`docs/ITD-####` 브랜치)로 한다.
- `02-common.md`, `01-skillset.md`의 기존 규약 추출도 도입 후 작업으로 남긴다(도입 커밋을 하네스 골격으로 한정하기 위함).

## 5. 승인과 커밋·push

1. 하네스 파일만 stage한다: `.harness/paths` 목록 경로만 `git add`. `git add -A`·`git add .` 금지.
2. `git diff --cached --name-only`로 staged 목록을 보여주고, 하네스 밖 파일이 없는지 확인한다.
3. 사용자에게 보고한다: 추가 파일 수, 병합한 파일과 병합 방식, 보류한 상반 규칙, 대상 브랜치, 커밋 메시지(`chore: 하네스 도입`).
4. 사용자에게 `하네스 도입 승인`을 한 줄로 입력하도록 안내한다.
5. 훅 메시지 `승인 기록: 하네스 도입 승인`을 확인한다. **이 메시지가 없으면** 방금 복사한 훅이 이 세션에 로드되지 않은 것이다. 커밋하지 말고 세션을 다시 시작한 뒤 이 스킬을 이어서(5단계부터) 실행하도록 안내한다.
6. 커밋과 push를 따로 실행한다(훅이 staged 파일을 검사함).

```bash
git commit -F - <<'EOF'
chore: 하네스 도입

- Claude·Codex 분업 하네스(규칙, 스킬, 훅, 문서 템플릿) 추가
- 기존 CLAUDE.md·설정 파일에 하네스 항목 병합
EOF
git push origin HEAD
```

- 훅에 막히면 메시지대로 고친다(하네스 밖 파일 제외 등). 우회하지 않는다.
- 승인은 30분, 승인한 브랜치에만 유효하고 push 1회 후 삭제된다.

## 6. 보고와 다음 단계

- 커밋 해시, push 결과, 등록한 Git 훅, 보류 항목을 보고한다.
- 이후는 일반 절차다: Claude에서 `req-gather`(남은 범위) → `prd-write` → `api-design` → `prd-verify`. 진행 중이던 작업 브랜치는 브랜치명이 `feat/ITD-####` 형식이어야 하며, Codex `feature-plan`으로 이미 구현한 부분과 남은 부분을 나눠 계획을 쓰고 `계획 승인`부터 이어 간다.
