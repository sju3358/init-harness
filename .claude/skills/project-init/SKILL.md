---
name: project-init
description: 하네스를 clone한 새 프로젝트의 초기 셋팅을 한다. 스택(Java·Spring Boot 버전, 빌드 도구, DB, ORM, 메시지 큐, 캐시, 인증, 배포 대상, 테스트)을 매번 사용자에게 확인받아 docs/project.md를 채우고 Git 훅을 등록한다. "프로젝트 초기 셋팅", "프로젝트 시작", "스택 설정" 요청에 쓴다.
---

# 프로젝트 초기 셋팅

기본값은 Java + Spring Boot지만 프로젝트마다 DB·메시지 큐가 달라지므로 기본값을 그대로 채우지 않고 반드시 묻는다.

## 1. 현황 확인

- `docs/project.md`가 이미 채워져 있으면 덮어쓰지 않고 바뀔 항목만 묻는다.
- `git status`, `git branch`, `git remote -v`로 저장소 상태를 확인한다. `.git`이 하네스 원본(`init-harness`)을 가리키면 README의 "시작" 절차(`rm -rf .git && git init -b main`)를 사용자가 직접 하도록 안내하고 멈춘다. `.git` 삭제는 에이전트가 하지 않는다.
- Notion 기획 원본 링크가 있으면 받아 둔다(이 단계에서 읽지는 않음).

## 2. 스택 질문

`AskUserQuestion`으로 묻는다. 한 번에 최대 4문항이라 두 번에 나눈다. 각 질문의 첫 선택지는 기본값으로 둔다.

1차: 언어·프레임워크 버전(Java 21 + Spring Boot 3.x), 빌드 도구(Gradle Kotlin DSL / Gradle Groovy / Maven), DB(PostgreSQL / MySQL·MariaDB / Oracle / MSSQL), ORM(JPA / MyBatis / JPA+QueryDSL)

2차: 메시지 큐(없음 / RabbitMQ / Kafka / MQTT), 인증(없음 / JWT / 세션 / 외부 SSO), 배포 대상(Docker / jar 직접 / 고객사 WAS), 통합 테스트(Testcontainers 사용 / H2 등 내장 DB / 단위 테스트만)

- 캐시, 외부 연동, 고객사·기간은 자유 입력으로 한 번에 묻는다. 모르면 비워 둔다.
- 답에 없는 값을 추측으로 채우지 않는다.

## 3. 기록

- `docs/project.md`의 스택 표, 검증 명령(빌드 도구에 맞춰: Gradle이면 `./gradlew build`, `./gradlew test` 등), 통합 브랜치를 채운다.
- 검증 명령은 사용자에게 보여주고 맞는지 확인받는다.
- `docs/prd/01-skillset.md`는 통합 브랜치에서 고치지 않는다(PRD 문서는 작업 브랜치에서만 편집). 첫 티켓의 `prd-write`가 `project.md` 스택을 옮겨 채운다.

## 4. Git 훅

```bash
git config core.hooksPath .githooks
chmod +x .githooks/* .harness/hooks/*.sh scripts/*.sh
```

## 5. 보고와 다음 단계

- 채운 값, 비워 둔 값, 등록한 훅을 보고한다.
- 초기 커밋과 push는 보호 브랜치(`main`) 작업이라 사용자가 직접 한다고 안내한다.

```bash
git add -A && git commit -m "chore: 프로젝트 초기 셋팅"
git push -u origin main --no-verify
```

- 다음 단계: 첫 티켓의 `work-start`(작업 브랜치로 전환) → 같은 세션에서 `req-gather`.
