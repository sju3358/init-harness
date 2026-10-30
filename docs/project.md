# 프로젝트 설정

`project-init` 스킬이 사용자에게 확인받아 채운다. 비어 있는 항목은 에이전트가 추측하지 않고 사용자에게 묻는다.

## 프로젝트

- 이름:
- 고객사·도메인:
- 기간:
- 기획 원본(Notion 등):

## 스택

| 항목 | 값 |
| --- | --- |
| 언어·버전 | (기본 Java 21) |
| 프레임워크 | (기본 Spring Boot 3.x) |
| 빌드 도구 | (Gradle / Maven) |
| DB | |
| ORM·쿼리 | (JPA / MyBatis / jOOQ) |
| 메시지 큐 | (없음 / RabbitMQ / Kafka / MQTT) |
| 캐시 | |
| 인증 | |
| 외부 연동 | |
| 배포 대상 | |
| 테스트 | (JUnit 5 + AssertJ + Mockito, 통합 테스트는 Testcontainers 여부) |

## 디렉터리

| 경로 | 용도 |
| --- | --- |
| `src/main/java/` | 소스 |
| `src/main/resources/` | 설정 |
| `src/test/java/` | 테스트 |

## 검증 명령

| 구분 | 명령 |
| --- | --- |
| 빌드 | |
| 단위 테스트 | |
| 통합 테스트 | |
| 정적 검사 | |
| 로컬 실행 | |

## API

- API 경로 접두어: (컨트롤러 매핑 앞에 붙는 context-path 등. 없으면 비움. `check-api.mjs`가 사용)

## 브랜치

- 통합 브랜치: main
- 원격 저장소:
