# {도메인} API

`api-design`이 이 파일을 복사해 `docs/api/<도메인>.md`로 만든다. 이 템플릿은 검사 대상이 아니다.

엔드포인트 제목은 `### API-### 메서드 경로` 형식을 지킨다. `scripts/check-api.mjs`가 이 줄로 코드와 엔드포인트 목록을 비교한다.

---

### API-### GET /api/v1/{resources}/{id}

- 요구사항: REQ-###
- feature: F-##
- API 상태: 확정
- 인증: 필요 (권한) / 불필요

{무엇을 하는 API인지 한두 문장}

**Path**

| 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |

**Query**

| 이름 | 타입 | 필수 | 기본값 | 설명 |
| --- | --- | --- | --- | --- |

**Request Body** (`application/json`)

| 필드 | 타입 | 필수 | 제약 | 설명 |
| --- | --- | --- | --- | --- |

**Response 200**

| 필드 | 타입 | null 가능 | 설명 |
| --- | --- | --- | --- |

```json
{}
```

**Errors**

| HTTP | 코드 | 상황 |
| --- | --- | --- |

- 필드 경로는 중첩을 점으로 쓴다(`data.items[].price`).
- 타입은 `string` · `number(int)` · `number(decimal)` · `boolean` · `string(date-time)` · `enum(A,B)` · `object` · `array<T>`로 쓴다.
- 제약은 검증 규칙(`1~50자`, `>= 0`, `email` 등)을 코드의 검증과 같은 값으로 쓴다.
