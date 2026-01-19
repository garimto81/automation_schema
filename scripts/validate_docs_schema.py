#!/usr/bin/env python3
"""
문서-마이그레이션 스키마 일치 검증 스크립트

Usage:
    python scripts/validate_docs_schema.py
    python scripts/validate_docs_schema.py --verbose  # 상세 출력
    python scripts/validate_docs_schema.py --report   # 보고서 생성
"""

import argparse
import io
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

# Windows 콘솔 UTF-8 출력 설정
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# 경로 설정
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
DOCS_DIR = PROJECT_ROOT / "docs"
MIGRATIONS_DIR = PROJECT_ROOT / "supabase" / "migrations"

SchemaType = Literal["table", "view", "function", "trigger", "index", "enum"]


@dataclass
class SchemaItem:
    name: str
    type: SchemaType
    schema: str  # public, json, etc.
    source_file: str
    line_number: int = 0


def extract_from_migrations() -> list[SchemaItem]:
    """마이그레이션 파일에서 스키마 항목 추출 (DROP 구문 고려)"""
    items: list[SchemaItem] = []
    dropped_items: set[tuple[str, str, str]] = set()  # (type, schema, name)

    if not MIGRATIONS_DIR.exists():
        print(f"경고: 마이그레이션 폴더 없음: {MIGRATIONS_DIR}")
        return items

    # 마이그레이션 파일을 시간순으로 처리 (파일명 정렬)
    for sql_file in sorted(MIGRATIONS_DIR.glob("*.sql")):
        content = sql_file.read_text(encoding="utf-8")
        lines = content.split("\n")

        for i, line in enumerate(lines, 1):
            # DROP TABLE - 삭제된 테이블 추적
            match = re.search(
                r"DROP TABLE (?:IF EXISTS )?(?:(\w+)\.)?(\w+)",
                line,
                re.IGNORECASE,
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.add(("table", schema, name))

            # DROP VIEW
            match = re.search(
                r"DROP VIEW (?:IF EXISTS )?(?:(\w+)\.)?(\w+)",
                line,
                re.IGNORECASE,
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.add(("view", schema, name))

            # DROP FUNCTION
            match = re.search(
                r"DROP FUNCTION (?:IF EXISTS )?(?:(\w+)\.)?(\w+)",
                line,
                re.IGNORECASE,
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.add(("function", schema, name))

            # DROP TYPE (ENUM)
            match = re.search(
                r"DROP TYPE (?:IF EXISTS )?(?:(\w+)\.)?(\w+)",
                line,
                re.IGNORECASE,
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.add(("enum", schema, name))

            # CREATE TABLE
            match = re.search(
                r"CREATE TABLE (?:IF NOT EXISTS )?(?:(\w+)\.)?(\w+)",
                line,
                re.IGNORECASE,
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                # DROP 후 CREATE된 경우 dropped에서 제거
                dropped_items.discard(("table", schema, name))
                items.append(SchemaItem(name, "table", schema, sql_file.name, i))

            # CREATE VIEW
            match = re.search(
                r"CREATE (?:OR REPLACE )?VIEW (?:(\w+)\.)?(\w+)", line, re.IGNORECASE
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.discard(("view", schema, name))
                items.append(SchemaItem(name, "view", schema, sql_file.name, i))

            # CREATE FUNCTION
            match = re.search(
                r"CREATE (?:OR REPLACE )?FUNCTION (?:(\w+)\.)?(\w+)",
                line,
                re.IGNORECASE,
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.discard(("function", schema, name))
                items.append(SchemaItem(name, "function", schema, sql_file.name, i))

            # CREATE TRIGGER
            match = re.search(
                r"CREATE (?:OR REPLACE )?TRIGGER (\w+)", line, re.IGNORECASE
            )
            if match:
                name = match.group(1)
                items.append(SchemaItem(name, "trigger", "public", sql_file.name, i))

            # CREATE TYPE (ENUM)
            match = re.search(
                r"CREATE TYPE (?:(\w+)\.)?(\w+) AS ENUM", line, re.IGNORECASE
            )
            if match:
                schema = match.group(1) or "public"
                name = match.group(2)
                dropped_items.discard(("enum", schema, name))
                items.append(SchemaItem(name, "enum", schema, sql_file.name, i))

    # 최종적으로 DROP된 항목 제외
    final_items = []
    for item in items:
        if (item.type, item.schema, item.name) not in dropped_items:
            final_items.append(item)

    return final_items


def extract_from_docs() -> list[SchemaItem]:
    """문서에서 스키마 정의 추출"""
    items: list[SchemaItem] = []

    # 제외할 문서 목록 (별도 프로젝트용)
    EXCLUDED_DOCS = {
        "06-AEP-Analysis-DB.md",  # automation_aep 프로젝트용
        "10-Internal-Reference.md",  # 내부 참조 문서 (SQL 코드 블록 없음)
    }

    if not DOCS_DIR.exists():
        print(f"경고: 문서 폴더 없음: {DOCS_DIR}")
        return items

    for md_file in DOCS_DIR.glob("*.md"):
        # 제외 문서 건너뛰기
        if md_file.name in EXCLUDED_DOCS:
            continue

        content = md_file.read_text(encoding="utf-8")

        # SQL 코드 블록 추출
        for match in re.finditer(r"```sql\n(.*?)```", content, re.DOTALL):
            sql_block = match.group(1)

            # CREATE TABLE
            for create_match in re.finditer(
                r"CREATE TABLE (?:IF NOT EXISTS )?(?:(\w+)\.)?(\w+)",
                sql_block,
                re.IGNORECASE,
            ):
                schema = create_match.group(1) or "public"
                name = create_match.group(2)
                items.append(SchemaItem(name, "table", schema, md_file.name, 0))

            # CREATE VIEW
            for create_match in re.finditer(
                r"CREATE (?:OR REPLACE )?VIEW (?:(\w+)\.)?(\w+)",
                sql_block,
                re.IGNORECASE,
            ):
                schema = create_match.group(1) or "public"
                name = create_match.group(2)
                items.append(SchemaItem(name, "view", schema, md_file.name, 0))

            # CREATE FUNCTION
            for create_match in re.finditer(
                r"CREATE (?:OR REPLACE )?FUNCTION (?:(\w+)\.)?(\w+)",
                sql_block,
                re.IGNORECASE,
            ):
                schema = create_match.group(1) or "public"
                name = create_match.group(2)
                items.append(SchemaItem(name, "function", schema, md_file.name, 0))

    return items


def compare_schemas(
    migration_items: list[SchemaItem], doc_items: list[SchemaItem]
) -> dict:
    """스키마 비교"""
    # 중복 제거 (같은 이름이 여러 파일에 있을 수 있음)
    migration_names = {f"{item.schema}.{item.name}" for item in migration_items}
    doc_names = {f"{item.schema}.{item.name}" for item in doc_items}

    return {
        "in_migration_only": migration_names - doc_names,
        "in_doc_only": doc_names - migration_names,
        "in_both": migration_names & doc_names,
        "migration_items": migration_items,
        "doc_items": doc_items,
    }


def print_report(comparison: dict, verbose: bool = False) -> int:
    """검증 결과 출력"""
    print("=" * 60)
    print("문서-마이그레이션 스키마 검증 결과")
    print("=" * 60)
    print()

    exit_code = 0

    # 문서에만 있는 항목 (Critical - 구현 누락 가능성)
    if comparison["in_doc_only"]:
        print("⚠️  Critical: 문서에만 있는 항목 (마이그레이션에 없음)")
        print("   → 구현이 누락되었거나, 문서가 최신 상태가 아님")
        for name in sorted(comparison["in_doc_only"]):
            print(f"   - {name}")
        print()
        exit_code = 1

    # 마이그레이션에만 있는 항목 (Info - 문서화 누락)
    if comparison["in_migration_only"]:
        print("ℹ️  Info: 마이그레이션에만 있는 항목 (문서에 없음)")
        print("   → 문서화가 누락되었거나, 내부 전용 항목")
        for name in sorted(comparison["in_migration_only"]):
            print(f"   - {name}")
        print()

    # 일치하는 항목
    print(f"✅ 일치하는 항목: {len(comparison['in_both'])}개")

    if verbose:
        print("\n--- 상세 정보 ---")
        print("\n마이그레이션 항목:")
        for item in comparison["migration_items"]:
            print(
                f"  [{item.type}] {item.schema}.{item.name} ({item.source_file}:{item.line_number})"
            )

        print("\n문서 항목:")
        for item in comparison["doc_items"]:
            print(f"  [{item.type}] {item.schema}.{item.name} ({item.source_file})")

    # 요약
    print()
    print("-" * 60)
    print("요약:")
    print(f"  - 마이그레이션 항목: {len(comparison['migration_items'])}개")
    print(f"  - 문서 항목: {len(comparison['doc_items'])}개")
    print(f"  - Critical (문서만): {len(comparison['in_doc_only'])}개")
    print(f"  - Info (마이그레이션만): {len(comparison['in_migration_only'])}개")
    print("-" * 60)

    if exit_code == 0:
        print("\n✅ 모든 검증 통과!")
    else:
        print("\n❌ 검증 실패 - 불일치 항목을 확인하세요.")

    return exit_code


def generate_markdown_report(comparison: dict) -> str:
    """마크다운 보고서 생성"""
    lines = [
        "# 문서-마이그레이션 스키마 검증 보고서",
        "",
        f"생성일: {__import__('datetime').datetime.now().isoformat()}",
        "",
        "## 요약",
        "",
        "| 항목 | 개수 |",
        "|------|------|",
        f"| 마이그레이션 항목 | {len(comparison['migration_items'])} |",
        f"| 문서 항목 | {len(comparison['doc_items'])} |",
        f"| 일치 | {len(comparison['in_both'])} |",
        f"| 문서만 (Critical) | {len(comparison['in_doc_only'])} |",
        f"| 마이그레이션만 (Info) | {len(comparison['in_migration_only'])} |",
        "",
    ]

    if comparison["in_doc_only"]:
        lines.extend(
            [
                "## Critical: 문서에만 있는 항목",
                "",
                "| 항목 | 조치 필요 |",
                "|------|----------|",
            ]
        )
        for name in sorted(comparison["in_doc_only"]):
            lines.append(f"| `{name}` | 마이그레이션 추가 또는 문서 수정 |")
        lines.append("")

    if comparison["in_migration_only"]:
        lines.extend(
            [
                "## Info: 마이그레이션에만 있는 항목",
                "",
                "| 항목 | 비고 |",
                "|------|------|",
            ]
        )
        for name in sorted(comparison["in_migration_only"]):
            lines.append(f"| `{name}` | 문서화 검토 필요 |")
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="문서-마이그레이션 스키마 검증")
    parser.add_argument("--verbose", "-v", action="store_true", help="상세 출력")
    parser.add_argument(
        "--report", "-r", action="store_true", help="마크다운 보고서 생성"
    )
    args = parser.parse_args()

    print(f"프로젝트 루트: {PROJECT_ROOT}")
    print(f"문서 폴더: {DOCS_DIR}")
    print(f"마이그레이션 폴더: {MIGRATIONS_DIR}")
    print()

    migration_items = extract_from_migrations()
    doc_items = extract_from_docs()

    comparison = compare_schemas(migration_items, doc_items)

    if args.report:
        report = generate_markdown_report(comparison)
        report_path = PROJECT_ROOT / "docs" / "SCHEMA_VALIDATION_REPORT.md"
        report_path.write_text(report, encoding="utf-8")
        print(f"보고서 생성됨: {report_path}")

    exit_code = print_report(comparison, args.verbose)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
