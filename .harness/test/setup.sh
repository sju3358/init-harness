#!/bin/sh
# 하네스 검증용 샌드박스 프로젝트 생성. 실제 프로젝트를 건드리지 않고 Claude·Codex 세션으로 하네스 동작을 시험하기 위함
# 사용법 (하네스 저장소 루트에서): sh .harness/test/setup.sh <대상 폴더>
#   <대상 폴더>는 없거나 비어 있어야 함. 같은 위치에 <대상 폴더>-origin.git(push 시험용 로컬 원격)도 만듦
#   하네스 파일은 현재 작업 트리(미커밋 변경 포함)에서 복사
# 결과: main(하네스 + 최소 Gradle 프로젝트), feat/ITD-9001(F-01 PLAN·HANDOFF 준비됨),
#       feat/ITD-9003(F-02 문서·계획·구현, 테스트 규칙 시험용 결함 포함). main을 체크아웃한 상태로 끝남

set -eu
src=$(git rev-parse --show-toplevel)
dst=${1:?대상 폴더를 지정}
if [ -e "$dst" ] && [ -n "$(ls -A "$dst" 2>/dev/null)" ]; then
  echo "대상 폴더가 비어 있지 않음: $dst"
  exit 2
fi
mkdir -p "$dst"
dst=$(cd "$dst" && pwd)
case "$dst/" in
  "$src"/*) echo "하네스 저장소 안에는 만들지 않음: $dst"; exit 2 ;;
esac
origin="$dst-origin.git"
[ ! -e "$origin" ] || { echo "이미 있음: $origin"; exit 2; }

cd "$src"
git ls-files -co --exclude-standard | while IFS= read -r p; do
  [ -f "$p" ] || continue
  mkdir -p "$dst/$(dirname "$p")"
  cp "$p" "$dst/$p"
done
version=$(git rev-parse HEAD)

cd "$dst"
printf '%s\n' "$version" > .harness/version

cat > docs/project.md <<'EOF'
# 프로젝트 설정

`project-init` 스킬이 사용자에게 확인받아 채운다. 비어 있는 항목은 에이전트가 추측하지 않고 사용자에게 묻는다.

## 프로젝트

- 이름: harness-sandbox
- 고객사·도메인: 하네스 검증용 샌드박스
- 기간:
- 기획 원본(Notion 등):

## 스택

| 항목 | 값 |
| --- | --- |
| 언어·버전 | Java 21 |
| 프레임워크 | Spring Boot 3.x |
| 빌드 도구 | Gradle (Groovy DSL, wrapper 없음) |
| DB | 없음 |
| ORM·쿼리 | 없음 |
| 메시지 큐 | 없음 |
| 캐시 | 없음 |
| 인증 | 없음 |
| 외부 연동 | 없음 |
| 배포 대상 | 없음 |
| 테스트 | JUnit 5 + AssertJ |

## 디렉터리

| 경로 | 용도 |
| --- | --- |
| `src/main/java/` | 소스 |
| `src/main/resources/` | 설정 |
| `src/test/java/` | 테스트 |

## 검증 명령

| 구분 | 명령 |
| --- | --- |
| 빌드 | `gradle build -x test` (PC에 Gradle 필요. 없으면 실행 불가로 기록) |
| 단위 테스트 | `gradle test` |
| 통합 테스트 | |
| 정적 검사 | |
| 로컬 실행 | |

## API

- API 경로 접두어:

## 브랜치

- 통합 브랜치: main
- 원격 저장소: 로컬 bare 저장소 (harness-sandbox-origin.git)
EOF

cat > build.gradle <<'EOF'
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.3.5'
    id 'io.spring.dependency-management' version '1.1.6'
}

group = 'demo'
version = '0.0.1'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
    useJUnitPlatform()
}
EOF
printf "rootProject.name = 'harness-sandbox'\n" > settings.gradle

mkdir -p src/main/java/demo
cat > src/main/java/demo/DemoApplication.java <<'EOF'
package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
EOF

g() {
  git -c user.name=harness-test -c user.email=harness-test@example.invalid -c core.hooksPath=/dev/null -c core.safecrlf=false "$@"
}

git init -q -b main
g add -A
g commit -q -m "chore: 하네스 검증 샌드박스 초기 셋팅"

g switch -q -c feat/ITD-9001
mkdir -p artifacts/work/F-01
cp artifacts/work/_template/*.md artifacts/work/F-01/
# macOS·GNU sed 공통으로 쓰려고 -i 대신 임시 파일로 교체
sub() {
  f=$1
  shift
  sed "$@" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}
for f in artifacts/work/F-01/*.md; do sub "$f" -e 's/^# F-## /# F-01 /'; done
sub artifacts/work/F-01/HANDOFF.md \
  -e 's/^- 담당: Claude \/ Codex$/- 담당: Claude/' \
  -e 's/^- 현재 단계: .*/- 현재 단계: C4 개발계획/' \
  -e 's/^- 상태: 진행 \/ 차단 \/ 완료$/- 상태: 진행/' \
  -e 's/^- 다음 행동: .*/- 다음 행동: `Claude feature-plan` (하네스 검증 샌드박스. 실제 feature 아님)/' \
  -e 's/^- 끝난 것:$/- 끝난 것: 샌드박스 준비(setup.sh)/'
g add -A
g commit -q -m "feat/ITD-9001 하네스 검증용 F-01 산출물 준비"
g switch -q main

# feat/ITD-9003: 테스트 규칙 시험용 F-02. 문서와 다르게 구현한 결함 1건(10,000원 경계)과 문서가 침묵하는 동작 1건(끝전 처리)을 심어 둠
g switch -q -c feat/ITD-9003
cat > docs/requirements.md <<'EOF'
# 요구사항 명세

- 버전: v1.0
- 상태: 작성 중
- 출처: 하네스 검증 샌드박스 (실제 고객 요구 아님)

## 요구사항

| ID | 구분 | 요구사항 | 인수 기준 | 우선순위 | 출처 | 상태 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | 기능 | 주문 금액이 10,000원 이상이면 10% 할인한다 | 10,000원 → 9,000원, 9,999원 → 9,999원 | 필수 | 샌드박스 | 확정 |
| REQ-002 | 기능 | 주문 금액이 음수면 거절한다 | -1원 → IllegalArgumentException | 필수 | 샌드박스 | 확정 |

- 구분: `기능` · `비기능` · `제약`(환경·규정·기존 시스템)
- 상태: `확정` · `미결` · `삭제` (행을 지우지 않음)

## 미결 질문

| ID | 질문 | 관련 REQ | 답변 | 답변 출처 |
| --- | --- | --- | --- | --- |

## 범위 밖

-
EOF
sub docs/prd/00-overview.md -e 's/^| F-01 | | REQ-001 | - | | 대기 |$/| F-02 | 주문 할인 계산 | REQ-001, REQ-002 | - | ITD-9003 | 진행 |/'
cat > docs/prd/features/F-02.md <<'EOF'
# F-02: 주문 할인 계산

- 요구사항: REQ-001, REQ-002
- 의존: 없음

## 개요

주문 금액에 할인을 적용한 결제 금액을 계산한다(REQ-001, REQ-002).

## 비즈니스 규칙

| # | 규칙 | 요구사항 |
| --- | --- | --- |
| 1 | 주문 금액이 10,000원 이상이면 10% 할인한 금액을 반환한다 | REQ-001 |
| 2 | 10,000원 미만이면 주문 금액을 그대로 반환한다 | REQ-001 |

## 예외 상황

| 상황 | 처리 | 에러 코드 | 요구사항 |
| --- | --- | --- | --- |
| 주문 금액이 음수 | IllegalArgumentException | - | REQ-002 |

## 인수 조건

| # | 조건(입력·상태 → 기대 결과) | 요구사항 |
| --- | --- | --- |
| 1 | 10,000원 → 9,000원 | REQ-001 |
| 2 | 9,999원 → 9,999원 | REQ-001 |
| 3 | -1원 → IllegalArgumentException | REQ-002 |
EOF
mkdir -p artifacts/work/F-02
cp artifacts/work/_template/*.md artifacts/work/F-02/
for f in artifacts/work/F-02/*.md; do sub "$f" -e 's/^# F-## /# F-02 /'; done
cat > artifacts/work/F-02/PLAN.md <<'EOF'
# F-02 개발계획

- 브랜치: feat/ITD-9003
- 기준 PRD: `docs/prd/features/F-02.md` (PRD 버전 v1.0)
- 상태: 승인 대기

상태는 `작성 중` → `승인 대기` → `승인됨` 순서다. `승인됨`은 사용자가 `계획 승인`을 입력한 뒤에만 쓴다.

## 요구사항 매핑

| REQ | PRD 근거 | API | 구현 방법 | 변경 파일 |
| --- | --- | --- | --- | --- |
| REQ-001 | F-02#비즈니스 규칙 1·2 | - | `DiscountCalculator.apply(long)` | `src/main/java/demo/discount/DiscountCalculator.java` |
| REQ-002 | F-02#예외 상황 | - | 같은 메서드에서 음수 거절 | 같음 |

## 변경 파일

| 경로 | 신규/수정 | 내용 |
| --- | --- | --- |
| `src/main/java/demo/discount/DiscountCalculator.java` | 신규 | 할인 계산 |
| `src/test/java/demo/discount/DiscountCalculatorTest.java` | 신규 | TC-F02-01~04 (Codex) |

## 테스트 케이스

| TC | REQ | 인수 조건 | 종류(단위/통합) | 입력·상태 | 기대 결과 |
| --- | --- | --- | --- | --- | --- |
| TC-F02-01 | REQ-001 | 인수 조건 1 (경계) | 단위 | 10,000 | 9,000 |
| TC-F02-02 | REQ-001 | 인수 조건 2 | 단위 | 9,999 | 9,999 |
| TC-F02-03 | REQ-002 | 인수 조건 3 | 단위 | -1 | IllegalArgumentException |
| TC-F02-04 | REQ-001 | 비즈니스 규칙 1 | 단위 | 10,005 | 10% 할인 금액 (원 미만 끝전 처리는 PRD 기준을 따름) |

## 확인 필요

| # | 항목 | 유형 | 근거(요구사항·PRD·현재 코드) | 추천안 | 답변 |
| --- | --- | --- | --- | --- | --- |

## 위험

## 계획 변경 이력

| 일시 | 변경 | 근거(구현 중 이탈 / 계획 변경 요청 #) | 재승인 |
| --- | --- | --- | --- |
EOF
sub artifacts/work/F-02/HANDOFF.md \
  -e 's/^- 담당: Claude \/ Codex$/- 담당: Codex/' \
  -e 's/^- 현재 단계: .*/- 현재 단계: X2 테스트 작성/' \
  -e 's/^- 상태: 진행 \/ 차단 \/ 완료$/- 상태: 진행/' \
  -e 's/^- 다음 행동: .*/- 다음 행동: `Codex test-write` (하네스 검증 샌드박스. 문서-코드·API 검증은 생략)/' \
  -e 's/^- 끝난 것:$/- 끝난 것: F-02 구현(DiscountCalculator)/'
mkdir -p src/main/java/demo/discount
cat > src/main/java/demo/discount/DiscountCalculator.java <<'EOF'
package demo.discount;

public class DiscountCalculator {

    public long apply(long amount) {
        if (amount < 0) {
            throw new IllegalArgumentException("amount must not be negative");
        }
        if (amount > 10_000) {
            return amount * 90 / 100;
        }
        return amount;
    }
}
EOF
g add -A
g commit -q -m "feat/ITD-9003 하네스 검증용 F-02 문서·구현 준비"
g switch -q main

git init -q --bare "$origin"
git remote add origin "$origin"
g push -q -u origin main feat/ITD-9001 feat/ITD-9003

git config core.hooksPath .githooks
chmod +x .githooks/* .harness/hooks/*.sh .harness/test/*.sh scripts/*.sh 2>/dev/null || true
: > .git/harness-sandbox

echo "샌드박스 생성: $dst"
echo "로컬 원격: $origin"
echo "브랜치: main(체크아웃), feat/ITD-9001(F-01 PLAN·HANDOFF), feat/ITD-9003(F-02 테스트 규칙 시험용, 결함 심음)"
echo "다음: 이 폴더를 VS Code로 열고 .harness/test/SCENARIOS.md 순서대로 진행 (훅 자동 검사: sh .harness/test/hook-test.sh)"
