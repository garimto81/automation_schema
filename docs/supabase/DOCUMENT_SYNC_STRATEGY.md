# 문서-DB 스키마 동기화 전략

**Version**: 1.1.0
**Date**: 2026-01-19
**Issue**: #1

---

## 1. 문제 정의

### 1.1 현재 상황

PRD 문서와 실제 Supabase DB 마이그레이션 간의 불일치가 발생:

| 문서 | 역할 | 불일치 유형 |
|------|------|------------|
| `02-GFX-JSON-DB.md` | JSON 스키마 설계 | 테이블/FK 정의 차이 |
| `07-Supabase-Orchestration.md` | 통합 뷰 설계 | 뷰 정의 업데이트 누락 |
| `08-GFX-AEP-Mapping.md` | AEP 매핑 설계 | 컴포지션 개수, 함수 구현 차이 |
| `09-DB-Sync-Guidelines.md` | 동기화 가이드 | 미구현 함수/뷰 포함 |

### 1.2 근본 원인

1. **수동 동기화**: 문서 수정 → 마이그레이션 작성이 별도 작업
2. **버전 불일치**: 문서 버전과 마이그레이션 버전 추적 안됨
3. **검증 부재**: 문서-DB 일치 여부 자동 검증 없음
4. **SSOT 혼란**: 어느 것이 진실의 소스인지 불명확

---

## 2. 제안 전략: Schema-as-Code + 자동 검증

### 2.1 SSOT 계층 정의

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SSOT 계층 구조                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Layer 1: 설계 문서 (PRD)                                           │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  docs/*.md                                                  │   │
│   │  - 비즈니스 요구사항                                          │   │
│   │  - 설계 의도 및 배경                                          │   │
│   │  - 예시 및 사용 시나리오                                       │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              │ 수동 변환 (설계자)                     │
│                              ▼                                      │
│   Layer 2: 스키마 정의 (SSOT)                                        │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  supabase/migrations/*.sql (번호순 정렬)                     │   │
│   │  - 테이블, 컬럼, 인덱스                                       │   │
│   │  - 함수, 트리거, 뷰                                           │   │
│   │  - RLS 정책, ENUM                                            │   │
│   │  ※ 이것이 진실의 소스 (SSOT)                                  │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              │ 자동 적용 (supabase db push)          │
│                              ▼                                      │
│   Layer 3: 실제 DB                                                  │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Supabase PostgreSQL                                        │   │
│   │  - 마이그레이션 적용 결과                                      │   │
│   │  - 런타임 데이터                                              │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**핵심 원칙**:
- **마이그레이션 SQL이 SSOT**
- 문서는 설계 의도와 배경 설명용
- 문서와 마이그레이션이 다르면 → 마이그레이션이 정답

### 2.2 문서 구조 표준화

모든 DB 관련 문서는 다음 섹션을 필수로 포함:

```markdown
## N. 테이블/뷰/함수 정의

### N.1 개요
- 목적, 비즈니스 요구사항

### N.2 스키마 정의
> **참조**: `supabase/migrations/YYYYMMDDHHMMSS_*.sql`

```sql
-- 마이그레이션 파일에서 직접 복사 (동기화 필수)
CREATE TABLE ...
```

### N.3 마이그레이션 이력
| 버전 | 마이그레이션 파일 | 변경 내용 |
|------|-----------------|----------|
| 1.0.0 | `20260113_01_gfx_schema.sql` | 초기 생성 |
| 1.1.0 | `20260119_json_public.sql` | 컬럼 추가 |

### N.4 사용 예시
```sql
SELECT * FROM ...
```
```

### 2.3 자동 검증 스크립트

#### scripts/validate_docs_schema.py

```python
#!/usr/bin/env python3
"""
문서-마이그레이션 스키마 일치 검증 스크립트

Usage:
    python scripts/validate_docs_schema.py
    python scripts/validate_docs_schema.py --fix  # 자동 수정 (문서 업데이트)
"""

import re
import sys
from pathlib import Path
from typing import NamedTuple

DOCS_DIR = Path("docs")
MIGRATIONS_DIR = Path("supabase/migrations")

class SchemaItem(NamedTuple):
    name: str
    type: str  # table, view, function, trigger, index
    definition: str
    source_file: str

def extract_from_migrations() -> list[SchemaItem]:
    """마이그레이션 파일에서 스키마 항목 추출"""
    items = []
    for sql_file in sorted(MIGRATIONS_DIR.glob("*.sql")):
        content = sql_file.read_text(encoding="utf-8")

        # CREATE TABLE
        for match in re.finditer(r"CREATE TABLE (?:IF NOT EXISTS )?(\w+\.\w+|\w+)", content):
            items.append(SchemaItem(match.group(1), "table", match.group(0), sql_file.name))

        # CREATE VIEW
        for match in re.finditer(r"CREATE (?:OR REPLACE )?VIEW (\w+)", content):
            items.append(SchemaItem(match.group(1), "view", match.group(0), sql_file.name))

        # CREATE FUNCTION
        for match in re.finditer(r"CREATE (?:OR REPLACE )?FUNCTION (\w+)", content):
            items.append(SchemaItem(match.group(1), "function", match.group(0), sql_file.name))

    return items

def extract_from_docs() -> list[SchemaItem]:
    """문서에서 스키마 정의 추출"""
    items = []
    for md_file in DOCS_DIR.glob("*.md"):
        content = md_file.read_text(encoding="utf-8")

        # 코드 블록 내 CREATE 문 찾기
        for match in re.finditer(r"```sql\n(.*?)```", content, re.DOTALL):
            sql_block = match.group(1)
            for create_match in re.finditer(r"CREATE (?:OR REPLACE )?(?:TABLE|VIEW|FUNCTION) (?:IF NOT EXISTS )?(\w+)", sql_block):
                item_type = "table" if "TABLE" in create_match.group(0) else "view" if "VIEW" in create_match.group(0) else "function"
                items.append(SchemaItem(create_match.group(1), item_type, create_match.group(0), md_file.name))

    return items

def compare_schemas(migration_items: list[SchemaItem], doc_items: list[SchemaItem]) -> dict:
    """스키마 비교"""
    migration_names = {item.name for item in migration_items}
    doc_names = {item.name for item in doc_items}

    return {
        "in_migration_not_doc": migration_names - doc_names,
        "in_doc_not_migration": doc_names - migration_names,
        "in_both": migration_names & doc_names
    }

def main():
    migration_items = extract_from_migrations()
    doc_items = extract_from_docs()

    comparison = compare_schemas(migration_items, doc_items)

    print("=== 문서-마이그레이션 스키마 검증 결과 ===\n")

    if comparison["in_doc_not_migration"]:
        print("⚠️  문서에만 있는 항목 (마이그레이션에 없음):")
        for name in sorted(comparison["in_doc_not_migration"]):
            print(f"  - {name}")
        print()

    if comparison["in_migration_not_doc"]:
        print("ℹ️  마이그레이션에만 있는 항목 (문서에 없음):")
        for name in sorted(comparison["in_migration_not_doc"]):
            print(f"  - {name}")
        print()

    print(f"✅ 일치하는 항목: {len(comparison['in_both'])}개")

    # 불일치가 있으면 exit code 1
    if comparison["in_doc_not_migration"]:
        sys.exit(1)

    print("\n모든 검증 통과!")

if __name__ == "__main__":
    main()
```

### 2.4 CI/CD 통합

#### .github/workflows/validate-docs.yml

```yaml
name: Validate Docs Schema

on:
  pull_request:
    paths:
      - 'docs/*.md'
      - 'supabase/migrations/*.sql'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Run schema validation
        run: python scripts/validate_docs_schema.py

      - name: Comment on PR if mismatch
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '⚠️ 문서와 마이그레이션 스키마 불일치가 감지되었습니다.\n\n`python scripts/validate_docs_schema.py` 실행 결과를 확인하세요.'
            })
```

---

## 3. 문서 수정 프로세스

### 3.1 스키마 변경 시 (마이그레이션 먼저)

```
1. 마이그레이션 SQL 작성
   └── supabase/migrations/YYYYMMDDHHMMSS_description.sql

2. supabase db push 테스트
   └── 로컬 또는 preview 환경에서 검증

3. 문서 업데이트
   └── 해당 PRD 문서의 스키마 정의 섹션 수정
   └── 마이그레이션 이력 테이블에 추가

4. PR 생성
   └── CI에서 자동 검증

5. 머지 후 production 적용
```

### 3.2 문서 수정 시 (설계 변경)

```
1. PRD 문서 수정 (설계 의도)
   └── 비즈니스 요구사항 변경 사항 명시

2. 마이그레이션 SQL 작성
   └── 문서 변경에 맞춰 구현

3. 문서의 스키마 정의 섹션 동기화
   └── 마이그레이션 파일에서 복사

4. PR 생성 (문서 + 마이그레이션 함께)
```

---

## 4. 즉시 조치 사항

### 4.1 Critical 항목 해결

| 항목 | 조치 |
|------|------|
| json → public 트리거 | 마이그레이션 적용 확인 후 문서 상태 업데이트 |
| v_render_chip_display | 마이그레이션 기준으로 문서 수정 |
| CDC 미구현 | 문서에 "구현 예정" 명시, 별도 인프라 이슈 생성 |

### 4.2 문서 버전 동기화

각 문서에 다음 헤더 추가:

```markdown
**Schema Version**: 1.1.0
**Last Migration**: `20260120000000_json_public_sync_triggers.sql`
**Sync Status**: ✅ Verified (2026-01-16)
```

### 4.3 검증 스크립트 생성

```bash
# 즉시 생성
mkdir -p scripts
# validate_docs_schema.py 작성
```

---

## 5. 장기 개선 계획

### 5.1 Phase 1: 수동 동기화 (현재)
- 문서 수정 → 마이그레이션 수동 작성
- 검증 스크립트로 불일치 탐지

### 5.2 Phase 2: 반자동 동기화 (Q2 2026)
- 마이그레이션에서 문서 스니펫 자동 추출
- Claude Code로 문서 업데이트 자동 제안

### 5.3 Phase 3: 완전 자동화 (Q3 2026)
- Schema 정의 파일 (YAML/JSON) → 마이그레이션 + 문서 동시 생성
- Prisma schema 또는 TypeBox 활용 검토

---

## 6. 체크리스트

### 스키마 변경 시 체크리스트

- [ ] 마이그레이션 SQL 작성 완료
- [ ] 로컬 테스트 통과 (`supabase db push`)
- [ ] 관련 PRD 문서 업데이트
- [ ] 마이그레이션 이력 테이블 추가
- [ ] `python scripts/validate_docs_schema.py` 통과
- [ ] PR 리뷰 완료

---

## 7. 관련 이슈

- #1: PRD 문서와 Supabase DB 스키마 불일치 해결

---

## 8. 문서 그룹 및 인덱스

> **그룹 A**: GFX-AEP 매핑 대전략 (Master: 08-GFX-AEP-Mapping)

### 8.1 문서 계층

```
08-GFX-AEP-Mapping.md (Master - 대전략)
├── 09-DB-Sync-Guidelines.md (DB 동기화 구현)
│
└── DOCUMENT_SYNC_STRATEGY.md (본 문서 - 문서-코드 동기화)
    └── docs/*.md ↔ supabase/migrations/*.sql 일치 보장
```

### 8.2 관련 문서

| 문서 | 역할 | 관계 |
|------|------|------|
| **00-DOCUMENT-INDEX.md** | 전체 문서 인덱스 | 그룹/SSOT 정의 |
| **08-GFX-AEP-Mapping.md** | GFX-AEP 매핑 대전략 | Master 문서 |
| **09-DB-Sync-Guidelines.md** | DB 동기화 가이드 | 동일 그룹 종속 |
| 01-DATA_FLOW.md | 전체 데이터 흐름 | 그룹 B Master |

### 8.3 수정 가이드라인

본 문서는 문서-마이그레이션 동기화 전략을 정의합니다. 그룹 A 모든 문서에 적용됩니다.

> **SSOT 정책**: 마이그레이션 SQL (`supabase/migrations/*.sql`)이 진실의 소스.
