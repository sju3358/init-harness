# init-harness

SI 프로젝트(4~5일 단위)용 Claude·Codex 분업 하네스. Claude는 기획·문서, Codex는 구현·테스트·검증을 맡고, 모든 단계는 요구사항 ID(REQ)로 추적한다. waveness 하네스 구조를 참고해 검증 중심으로 줄였다.

## 시작

```bash
git clone https://github.com/sju3358/init-harness.git <프로젝트명>
cd <프로젝트명>
rm -rf .git && git init -b main      # 하네스 이력을 끊고 프로젝트 저장소로 시작
```

그다음 Claude 세션에서 "프로젝트 초기 셋팅해줘"라고 하면 `project-init` 스킬이 스택(DB·메시지 큐 등)을 묻고 `docs/project.md`를 채운 뒤 Git 훅을 등록한다.

## 흐름

```
[Claude · Opus 5.5]  기획·문서
 project-init → req-gather → prd-write → prd-verify → ✋PRD 승인 → docs 커밋
                                                          ▲
                                         PRD 변경 요청(HANDOFF.md) → prd-change
[Codex]  구현·검증                                         │
 feature-start → feature-plan → ✋계획 승인 → implement → doc-code-verify
 → test-write → test-verify → ✋커밋/푸시 승인 → itd-commit
 (PR·머지는 사람이 직접)
```

절차와 승인 게이트의 단일 원본은 [docs/rules/workflow.md](docs/rules/workflow.md)다.

## 승인 게이트

| 게이트 | 사용자가 입력할 문구 | 강제 방식 |
| --- | --- | --- |
| PRD 승인 | `PRD 승인` | 승인 기록 없으면 Codex `feature-start`가 중단 |
| 계획 승인 | `계획 승인` | 현재 브랜치 승인 기록 없으면 `src/`·빌드 파일 편집 차단 |
| 커밋 승인 | `커밋 승인` | 30분 내 승인 기록 없으면 `git commit` 차단 |
| 푸시 승인 | `푸시 승인` (또는 `커밋 푸시 승인`) | 30분 내 승인 기록 없으면 `git push` 차단 |

승인 기록은 사용자 프롬프트에서만 만들어진다(`UserPromptSubmit` 훅 → `.harness/state/`). 에이전트가 `.harness/state/`를 직접 쓰는 명령은 차단한다. `승인 취소`로 현재 브랜치의 승인 기록을 지운다.

## 모델

| 위치 | 모델 | 용도 |
| --- | --- | --- |
| Claude 메인 | Opus 5.5 (`.claude/settings.json`) | 요구사항 도출, PRD 작성 |
| Claude `prd-verifier` | Opus 5.5, 새 컨텍스트 | 요구사항 ↔ PRD 정합성 검증 |
| Codex 메인 | gpt-6-luna, medium (`.codex/config.toml`) | 구현, 테스트 작성 |
| Codex `planner` | gpt-6.1-sol, high | 개발계획 |
| Codex `verifier` | gpt-6.1-sol, high, 새 컨텍스트 | 문서-코드 정합성, 테스트 검증 |

Pro·Plus 사용량 한도를 고려해 서브에이전트는 계획·검증에만 쓴다. Codex 모델 서열은 한 프로젝트 운용 후 조정한다.

## 구성

| 경로 | 내용 |
| --- | --- |
| `CLAUDE.md` / `AGENTS.md` | Claude / Codex 진입점 |
| `docs/` | 원본 문서. 요구사항, PRD, 추적표, 프로젝트 설정, 규칙 |
| `artifacts/work/F-xx/` | feature별 계획·검증·테스트 리포트·인계 |
| `.claude/skills/`, `.claude/agents/` | Claude 기획 스킬·검증 에이전트 |
| `.agents/skills/`, `.codex/agents/` | Codex 구현·검증 스킬·에이전트 |
| `.harness/hooks/` | Claude·Codex 공용 훅 스크립트 |
| `.githooks/` | commit-msg(ITD 형식), pre-push(보호 브랜치 차단) |
| `scripts/check-trace.sh` | REQ 추적 누락 기계 검사 |

## 한계

- 편집 차단 훅은 에디터 도구(Edit·Write·apply_patch) 기준이다. 셸 리다이렉션(`sed -i`, `cat >`)으로 쓰는 우회는 막지 못하므로 규칙으로 금지하고 검증 단계에서 `git diff`로 대조한다.
- Codex 프로젝트 설정(`.codex/config.toml`, `.codex/hooks.json`)은 신뢰된 프로젝트에서만 적용된다. 처음 열 때 신뢰 여부를 확인한다.
