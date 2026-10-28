---
name: api-verify
description: 구현된 컨트롤러·DTO·예외 처리가 API 문서(docs/api/*.md)와 일치하는지 검증한다. 엔드포인트 목록은 check-api.mjs로 기계 비교하고, 파라미터·필드·에러 코드는 verifier 에이전트(mode=api)가 대조한다. "API 검증", "API 문서와 코드 대조" 요청과 doc-code-verify 다음 단계에 쓴다. Codex를 쓸 수 없을 때 Claude가 대행할 수 있다.
---

# API 문서-코드 검증

Claude·Codex 공용 스킬이다. 원본은 `.agents/skills/api-verify/SKILL.md`이며, 그 파일을 읽고 절차를 그대로 따른다. 이 파일에는 절차를 적지 않는다(원본 하나만 고침).
