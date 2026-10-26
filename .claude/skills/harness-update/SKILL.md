---
name: harness-update
description: 하네스가 이미 설치된 프로젝트(구버전 포함)에 최신 하네스를 반영한다. 하네스 파일은 3-way 병합으로 프로젝트 수정분을 보존하고, 프로젝트가 채운 문서는 템플릿 변경분만 보고한다. 하네스 파일만 '하네스 업데이트 승인'으로 보호 브랜치에 커밋·push한다. "하네스 업데이트", "최신 하네스 적용", "하네스 버전 올려" 요청에 쓴다.
---

# 하네스 업데이트

하네스 도입 예외(`workflow.md` "예외")와 같은 범위다. 하네스 파일(`.harness/paths`)만 바꾸고, 소스와 프로젝트 문서 내용은 바꾸지 않는다.

## 0. 사전 확인

- `git status`가 깨끗해야 한다. 미커밋 변경이 있으면 멈춘다.
- 기준 버전(설치 당시 하네스 커밋)을 정한다.
  - `.harness/version`이 있으면 그 값
  - 없으면(초기 버전 설치 프로젝트) 사용자에게 묻는다. 모르면 `.harness/hooks/` 파일과 하네스 이력을 비교해 후보 커밋을 찾아 보여주고 확인받는다.
- 대상 브랜치를 확인한다. 보호 브랜치(main 등)에 바로 반영하거나 작업 브랜치(`docs/ITD-####`)에서 PR로 반영할 수 있다. 사용자에게 고르게 한다.

## 1. 병합 실행

```bash
tmp=$(mktemp -d)
git clone -q https://github.com/sju3358/init-harness.git "$tmp/harness"
sh "$tmp/harness/.harness/update.sh" <기준 커밋|-> "$tmp/harness"
```

- 새 버전의 스크립트로 실행한다(구버전 프로젝트에는 `update.sh`가 없음).
- 결과는 `.harness/update/report.txt`에 남는다. 종료 코드 1이면 충돌이 있다는 뜻이다.
- `$tmp`는 6단계까지 쓰고 지운다.

| 결과 | 뜻 |
| --- | --- |
| 추가·갱신·링크·삭제 | 프로젝트가 고치지 않은 파일이라 새 버전으로 그대로 반영 |
| 병합 | 양쪽이 고친 파일, 자동 병합 성공 |
| 충돌 | 양쪽이 같은 곳을 고침. 충돌 표시(`<<<<<<< 프로젝트`)가 파일에 남음 |
| 삭제보류 | 새 버전에서 없어졌지만 프로젝트가 고친 파일. 그대로 둠 |
| 템플릿변경 | 프로젝트 문서(`.harness/seed`)의 템플릿이 바뀜. diff만 남음 |

## 2. 충돌 정리

- 충돌 파일마다 양쪽 내용을 보여주고 정한다. 프로젝트 전용 규칙(스택, 고객사 규칙)은 프로젝트 쪽, 하네스 절차·훅은 새 버전 쪽이 기본이다. 애매하면 사용자에게 묻는다.
- `grep -rln '^<<<<<<< 프로젝트' .`로 충돌 표시가 남지 않았는지 확인한다.
- `삭제보류` 파일은 목록으로 보고하고 사용자가 정한다.

## 3. 템플릿 변경 반영

- `.harness/update/seed/*.diff`를 읽고 프로젝트 문서에 구조 변경(새 절, 새 항목)만 옮긴다. 프로젝트가 채운 값은 건드리지 않는다.
- `docs/requirements.md`, `docs/prd/**`, `docs/api/**`를 바꾸면 PRD 승인 해시가 깨져 재승인이 필요하다. 진행 중 feature가 있으면 이 문서들의 템플릿 변경은 미뤄 두고 다음 `prd-change` 때 반영하도록 보고한다. `docs/project.md`, `docs/traceability.md`는 승인과 무관하므로 바로 반영해도 된다.
- 업데이트로 `docs/api/`에 새 파일이 추가된 경우도 해시가 바뀐다. `sh .harness/hooks/prd-check.sh` 결과를 보고한다.

## 4. 검증

```bash
jq empty .claude/settings.json .codex/hooks.json
for f in .harness/hooks/*.sh .githooks/* scripts/*.sh; do sh -n "$f" || echo "문법 오류: $f"; done
node --check .harness/hooks/codex-tool-adapter.mjs scripts/check-api.mjs
git config core.hooksPath
```

- 실패하면 원인을 고친다. 고칠 수 없으면 커밋하지 않고 보고한다.
- 훅 등록(`.claude/settings.json`, `.codex/hooks.json`)이 바뀌었으면 세션을 다시 시작해야 반영된다고 알린다. 훅 스크립트 내용 변경은 바로 반영된다.

## 5. 커밋·push

- 하네스 파일만 stage한다. `.harness/paths` 목록 경로만 `git add`하고, `git diff --cached --name-only`로 확인한다.
- 커밋 메시지: `chore: 하네스 업데이트 (<기준 7자리> → <새 7자리>)`. 본문에 주요 변경과 충돌 정리 내용을 bullet로 쓴다.
- 보호 브랜치면 사용자에게 `하네스 업데이트 승인`을 한 줄로 입력하게 한다. 작업 브랜치면 일반 `커밋 승인`·`푸시 승인`이다.
- 커밋과 push는 따로 실행한다(staged 파일 검사).

## 6. 보고

- 기준 → 새 버전, 결과 건수, 충돌 정리 내용, 미뤄 둔 템플릿 변경, PRD 승인 상태, 세션 재시작 필요 여부, 커밋 해시.
- `rm -rf "$tmp"`로 임시 클론을 지운다.
