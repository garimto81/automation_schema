#!/usr/bin/env python3
"""Supabase 스키마 분석 스크립트"""

import re
from collections import defaultdict


def parse_schema(file_path):
    """스키마 덤프 파일 파싱"""

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. ENUM 타입 추출
    enums = {}
    enum_pattern = r'CREATE TYPE "public"\."(\w+)" AS ENUM \((.*?)\);'
    for match in re.finditer(enum_pattern, content, re.DOTALL):
        enum_name = match.group(1)
        values = [v.strip().strip("'") for v in match.group(2).split(",")]
        enums[enum_name] = values

    # 2. 테이블 구조 추출
    tables = {}
    table_pattern = r'CREATE TABLE (?:IF NOT EXISTS )?"public"\."(\w+)" \((.*?)\);'
    for match in re.finditer(table_pattern, content, re.DOTALL):
        table_name = match.group(1)
        columns_text = match.group(2)

        columns = []
        for line in columns_text.split("\n"):
            line = line.strip()
            if line and not line.startswith("CONSTRAINT"):
                # 컬럼 파싱
                col_match = re.match(r'"?(\w+)"?\s+(.+?)(?:,|$)', line)
                if col_match:
                    col_name = col_match.group(1)
                    col_type = col_match.group(2).strip().rstrip(",")
                    columns.append((col_name, col_type))

        tables[table_name] = columns

    # 3. Foreign Key 추출
    fks = []
    fk_pattern = r'ADD CONSTRAINT "(\w+)" FOREIGN KEY \("(\w+)"\) REFERENCES "public"\."(\w+)"\("(\w+)"\)(.*?);'
    for match in re.finditer(fk_pattern, content):
        fks.append(
            {
                "name": match.group(1),
                "from_table": match.group(1).split("_")[0],  # 추정
                "from_col": match.group(2),
                "to_table": match.group(3),
                "to_col": match.group(4),
                "options": match.group(5).strip(),
            }
        )

    # 4. 인덱스 추출
    indexes = defaultdict(list)
    idx_pattern = r'CREATE (?:UNIQUE )?INDEX "(\w+)" ON "public"\."(\w+)".*?\((.*?)\)'
    for match in re.finditer(idx_pattern, content):
        idx_name = match.group(1)
        table = match.group(2)
        cols = match.group(3)
        indexes[table].append({"name": idx_name, "columns": cols})

    # 5. 함수 추출
    functions = []
    func_pattern = r'CREATE (?:OR REPLACE )?FUNCTION "public"\."(\w+)"\((.*?)\) RETURNS'
    for match in re.finditer(func_pattern, content):
        functions.append(match.group(1))

    # 6. VIEW 추출
    views = []
    view_pattern = r'CREATE (?:OR REPLACE )?VIEW "public"\."(\w+)" AS'
    for match in re.finditer(view_pattern, content):
        if match.group(1) not in views:
            views.append(match.group(1))

    # 7. 트리거 추출
    triggers = defaultdict(list)
    trig_pattern = r'CREATE (?:OR REPLACE )?TRIGGER "(\w+)" (?:BEFORE|AFTER) (\w+(?: OR \w+)*) ON "public"\."(\w+)"'
    for match in re.finditer(trig_pattern, content):
        trig_name = match.group(1)
        event = match.group(2)
        table = match.group(3)
        triggers[table].append({"name": trig_name, "event": event})

    return {
        "enums": enums,
        "tables": tables,
        "foreign_keys": fks,
        "indexes": indexes,
        "functions": functions,
        "views": views,
        "triggers": triggers,
    }


def generate_markdown_report(data):
    """마크다운 보고서 생성"""

    md = []

    # 제목
    md.append("# Supabase 스키마 분석 보고서\n")
    md.append("분석 일시: 2026-01-16\n")
    md.append("프로젝트: automation_project (ohzdaflycmnbxkpvhxcu)\n\n")

    # 요약
    md.append("## 요약\n")
    md.append(
        f"총 {len(data['tables'])}개 테이블, {len(data['enums'])}개 ENUM, {len(data['views'])}개 VIEW, {len(data['functions'])}개 함수로 구성된 GFX-AEP 렌더링 시스템 스키마\n\n"
    )

    # ENUM 타입
    md.append("## 1. ENUM 타입 ({} 개)\n".format(len(data["enums"])))
    md.append("| ENUM 이름 | 값 개수 | 값 목록 |\n")
    md.append("|-----------|--------|--------|\n")
    for enum_name in sorted(data["enums"].keys()):
        values = data["enums"][enum_name]
        values_str = ", ".join(values[:5]) + ("..." if len(values) > 5 else "")
        md.append(f"| `{enum_name}` | {len(values)} | {values_str} |\n")
    md.append("\n")

    # 테이블 구조
    md.append("## 2. 테이블 구조 ({} 개)\n".format(len(data["tables"])))

    # GFX 테이블 그룹
    gfx_tables = sorted([t for t in data["tables"].keys() if t.startswith("gfx_")])
    wsop_tables = sorted([t for t in data["tables"].keys() if t.startswith("wsop_")])
    cue_tables = sorted([t for t in data["tables"].keys() if t.startswith("cue_")])
    other_tables = sorted(
        [
            t
            for t in data["tables"].keys()
            if not (
                t.startswith("gfx_") or t.startswith("wsop_") or t.startswith("cue_")
            )
        ]
    )

    md.append("### 2.1 GFX 테이블 ({} 개)\n".format(len(gfx_tables)))
    for table in gfx_tables:
        md.append(f"\n#### `{table}` ({len(data['tables'][table])} columns)\n")
        md.append("| 컬럼명 | 타입 |\n")
        md.append("|--------|------|\n")
        for col_name, col_type in data["tables"][table]:
            md.append(f"| `{col_name}` | {col_type} |\n")
    md.append("\n")

    md.append("### 2.2 WSOP 테이블 ({} 개)\n".format(len(wsop_tables)))
    for table in wsop_tables:
        md.append(f"\n#### `{table}` ({len(data['tables'][table])} columns)\n")
        md.append("| 컬럼명 | 타입 |\n")
        md.append("|--------|------|\n")
        for col_name, col_type in data["tables"][table][:10]:  # 최대 10개만
            md.append(f"| `{col_name}` | {col_type} |\n")
        if len(data["tables"][table]) > 10:
            md.append(f"| ... | ({len(data['tables'][table]) - 10} more) |\n")
    md.append("\n")

    md.append("### 2.3 CUE 테이블 ({} 개)\n".format(len(cue_tables)))
    for table in cue_tables:
        md.append(f"\n#### `{table}` ({len(data['tables'][table])} columns)\n")
        md.append("| 컬럼명 | 타입 |\n")
        md.append("|--------|------|\n")
        for col_name, col_type in data["tables"][table][:10]:
            md.append(f"| `{col_name}` | {col_type} |\n")
        if len(data["tables"][table]) > 10:
            md.append(f"| ... | ({len(data['tables'][table]) - 10} more) |\n")
    md.append("\n")

    md.append("### 2.4 기타 테이블 ({} 개)\n".format(len(other_tables)))
    for table in other_tables:
        cols_count = len(data["tables"][table])
        md.append(f"- `{table}` ({cols_count} columns)\n")
    md.append("\n")

    # Foreign Key
    md.append("## 3. Foreign Key 관계 ({} 개)\n".format(len(data["foreign_keys"])))
    md.append("| 제약조건 이름 | FROM | TO | 옵션 |\n")
    md.append("|--------------|------|----|----- |\n")
    for fk in data["foreign_keys"][:30]:  # 처음 30개만
        md.append(
            f"| `{fk['name']}` | `{fk['from_col']}` | `{fk['to_table']}.{fk['to_col']}` | {fk['options'][:20]} |\n"
        )
    if len(data["foreign_keys"]) > 30:
        md.append(f"| ... | ... | ... | ({len(data['foreign_keys']) - 30} more) |\n")
    md.append("\n")

    # 인덱스
    md.append("## 4. 인덱스 (주요 테이블)\n")
    for table in ["gfx_hands", "gfx_hand_players", "cue_items", "wsop_events"]:
        if table in data["indexes"]:
            md.append(f"\n### `{table}` ({len(data['indexes'][table])} indexes)\n")
            for idx in data["indexes"][table][:10]:
                md.append(f"- `{idx['name']}`: {idx['columns']}\n")
    md.append("\n")

    # VIEW
    md.append("## 5. VIEW ({} 개)\n".format(len(data["views"])))
    for view in sorted(set(data["views"])):
        md.append(f"- `{view}`\n")
    md.append("\n")

    # 함수
    md.append("## 6. 함수 ({} 개)\n".format(len(data["functions"])))
    format_funcs = [f for f in data["functions"] if f.startswith("format_")]
    get_funcs = [f for f in data["functions"] if f.startswith("get_")]
    other_funcs = [
        f
        for f in data["functions"]
        if not (f.startswith("format_") or f.startswith("get_"))
    ]

    md.append(f"\n### 포맷 함수 ({len(format_funcs)} 개)\n")
    for func in format_funcs:
        md.append(f"- `{func}()`\n")

    md.append(f"\n### 데이터 조회 함수 ({len(get_funcs)} 개)\n")
    for func in get_funcs:
        md.append(f"- `{func}()`\n")

    md.append(f"\n### 기타 함수 ({len(other_funcs)} 개)\n")
    for func in other_funcs[:15]:
        md.append(f"- `{func}()`\n")
    md.append("\n")

    # 트리거
    md.append("## 7. 트리거 (주요 테이블)\n")
    trigger_tables = [
        t for t in data["triggers"].keys() if len(data["triggers"][t]) > 0
    ]
    for table in sorted(trigger_tables)[:15]:
        triggers_list = data["triggers"][table]
        md.append(f"\n### `{table}` ({len(triggers_list)} triggers)\n")
        for trig in triggers_list:
            md.append(f"- `{trig['name']}` ({trig['event']})\n")
    md.append("\n")

    # 주요 발견사항
    md.append("## 8. 주요 발견사항\n\n")
    md.append("### 긍정적인 점\n")
    md.append("- **체계적인 ENUM 관리**: 29개 ENUM 타입으로 데이터 무결성 강화\n")
    md.append(
        "- **완전한 타임스탬프 추적**: 모든 테이블에 `created_at`, `updated_at` 자동 관리\n"
    )
    md.append(
        "- **GFX-AEP 매핑 시스템**: `gfx_aep_field_mappings` + `gfx_aep_compositions` 테이블로 렌더링 자동화\n"
    )
    md.append(
        "- **다층 플레이어 관리**: GFX/WSOP/Manual 플레이어 데이터 통합 (`player_link_mapping`, `player_overrides`)\n"
    )
    md.append(
        "- **렌더링 데이터 함수**: `get_chip_display_data()`, `get_elimination_data()` 등 v3 스키마 JSON 생성 함수\n\n"
    )

    md.append("### 개선 필요 사항\n")
    md.append("- **RLS 정책 부족**: `gfx_triggers` 외 대부분 테이블에 RLS 미적용\n")
    md.append(
        "- **인덱스 과다**: 일부 테이블(cue_items, gfx_events)에 10개+ 인덱스 → 성능 점검 필요\n"
    )
    md.append(
        "- **JSONB 컬럼 검증 부재**: `gfx_data`, `payload` 등 JSONB 컬럼에 CHECK 제약조건 없음\n"
    )
    md.append("- **Soft Delete 미구현**: `deleted_at` 컬럼 없음 → 데이터 복구 어려움\n")
    md.append(
        "- **파티셔닝 부재**: `gfx_events`, `activity_log` 같은 대용량 테이블 파티셔닝 고려\n\n"
    )

    md.append("### 특이사항\n")
    md.append(
        "- **Job Queue 시스템**: `job_queue` + `render_queue` + `notifications`로 백그라운드 작업 관리\n"
    )
    md.append(
        "- **실시간 동기화**: `sync_status`, `sync_history`, `sync_log`로 GFX/WSOP 데이터 동기화 추적\n"
    )
    md.append(
        "- **Cue Sheet 워크플로우**: `broadcast_sessions` → `cue_sheets` → `cue_items` → `gfx_triggers` 렌더링 파이프라인\n"
    )
    md.append(
        "- **플래그 경로 함수**: `get_flag_path('KR')` → `'Flag/Korea.png'` 자동 변환\n"
    )
    md.append(
        "- **BB 단위 변환**: `format_bbs(chips, bb)` 함수로 칩 스택을 BB 단위로 자동 표시\n\n"
    )

    return "".join(md)


if __name__ == "__main__":
    print("스키마 분석 중...")
    data = parse_schema("schema_dump.sql")
    print(f"파싱 완료: {len(data['tables'])} 테이블, {len(data['enums'])} ENUM")

    report = generate_markdown_report(data)

    with open("schema_analysis_report.md", "w", encoding="utf-8") as f:
        f.write(report)

    print("✅ schema_analysis_report.md 생성 완료")
