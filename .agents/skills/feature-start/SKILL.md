---
name: feature-start
description: 승인된 PRD의 feature 목록에서 하나를 골라 ITD 티켓 브랜치(feat/ITD-####)와 작업 폴더(artifacts/work/F-##/)를 만든다. "feature 시작", "F-01 시작", "다음 기능 진행" 요청에 쓴다. Codex를 쓸 수 없을 때 Claude가 대행할 수 있다.
---

# feature 시작

## 1. 전제 확인

- `sh .harness/hooks/prd-check.sh`가 `PRD 승인 유효`를 출력해야 한다. 실패하면 출력 원문을 사용자에게 전하고 멈춘다(Claude에서 `prd-verify`·`PRD 승인` 필요).
- `docs/prd/00-overview.md` feature 목록에서 대상 feature와 의존 feature 상태를 확인한다. 의존 feature가 `병합` 전이면 사용자에게 알리고 진행 여부를 묻는다.
- `artifacts/work/F-##/`가 이미 있으면 새로 만들지 않고 `HANDOFF.md`부터 읽어 이어 하기로 전환한다.

## 2. 브랜치

- ITD 티켓 번호를 사용자에게 묻는다. 브랜치명을 스스로 짓지 않는다.
- `git status && git branch`로 미커밋 변경이 없는지 확인한다. 있으면 멈추고 알린다.
- 통합 브랜치(`docs/project.md`)로 이동해 `git pull` 후 `git switch -c feat/ITD-####`.

## 3. 작업 폴더

- `artifacts/work/_template/`을 `artifacts/work/F-##/`로 복사하고, 각 파일의 `F-##`, 브랜치, PRD 버전을 채운다.
- `HANDOFF.md` 상태: 담당 Codex, 단계 X1, 다음 행동 `feature-plan`.
- `00-overview.md`의 ITD 티켓 칸은 Codex가 고치지 않는다(PRD 편집 금지). 티켓 번호는 `HANDOFF.md`에 적고, PRD 반영이 필요하면 "PRD 변경 요청"으로 남긴다.

## 4. 보고

브랜치명, 대상 feature와 REQ 목록, 다음 단계(`feature-plan`)를 보고한다.

## Claude 대행

- 1~3단계를 그대로 하되, 작업 폴더는 템플릿 복사(`cp -R artifacts/work/_template artifacts/work/F-##`)와 `HANDOFF.md` 채우기까지만 한다. `PLAN.md`는 복사만 하고 내용을 쓰지 않는다(Claude의 `PLAN.md` 편집은 훅이 차단).
- `HANDOFF.md` "대행 기록"에 남기고, 다음 행동을 Codex `feature-plan`으로 적는다.
