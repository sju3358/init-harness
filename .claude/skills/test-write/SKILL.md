---
name: test-write
description: 개발계획(PLAN.md)의 TC를 테스트 코드로 작성한다. Claude에서는 'Claude 테스터'로 지정된 세션에서만 쓴다(다른 Claude 세션은 테스트 편집이 훅으로 차단됨). "테스트 코드 작성", "테스트 짜줘" 요청에 쓴다.
---

# 테스트 작성

Codex·Claude 테스터 세션 공용 스킬이다. 원본은 `.agents/skills/test-write/SKILL.md`이며, 그 파일을 읽고 절차를 그대로 따른다. 이 파일에는 절차를 적지 않는다(원본 하나만 고침).

- 이 세션이 `Claude 테스터` 세션이 아니면(구현 세션) 작성하지 않는다. 테스트 작성은 Codex(권장) 또는 새 Claude 세션의 첫 입력 `Claude 테스터`로 지정한 세션이 한다고 안내하고 멈춘다(`docs/rules/workflow.md` "Claude 테스터 세션").
