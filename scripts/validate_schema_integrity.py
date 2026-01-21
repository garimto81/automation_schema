"""
DB 스키마 무결성 검증 스크립트
마이그레이션 파일 분석하여 FK 관계, 뷰 의존성, 함수 참조 등을 검증합니다.
"""

import re
import json
from pathlib import Path
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass, field, asdict


@dataclass
class TableInfo:
    """테이블 정보"""
    name: str
    migration_file: str
    columns: List[str] = field(default_factory=list)
    foreign_keys: List[Dict[str, str]] = field(default_factory=list)
    depends_on: Set[str] = field(default_factory=set)


@dataclass
class ViewInfo:
    """뷰 정보"""
    name: str
    migration_file: str
    referenced_tables: Set[str] = field(default_factory=set)
    referenced_views: Set[str] = field(default_factory=set)


@dataclass
class FunctionInfo:
    """함수 정보"""
    name: str
    migration_file: str
    referenced_tables: Set[str] = field(default_factory=set)


@dataclass
class IntegrityReport:
    """무결성 검증 리포트"""
    migrations_count: int = 0
    tables: List[str] = field(default_factory=list)
    fk_relationships: List[Dict[str, str]] = field(default_factory=list)
    views: List[str] = field(default_factory=list)
    functions: List[str] = field(default_factory=list)
    issues: List[str] = field(default_factory=list)
    status: str = "PASS"


class SchemaIntegrityValidator:
    """스키마 무결성 검증기"""

    def __init__(self, migrations_dir: Path):
        self.migrations_dir = migrations_dir
        self.tables: Dict[str, TableInfo] = {}
        self.views: Dict[str, ViewInfo] = {}
        self.functions: Dict[str, FunctionInfo] = {}
        self.report = IntegrityReport()

    def analyze_migrations(self):
        """모든 마이그레이션 파일 분석"""
        migration_files = sorted(self.migrations_dir.glob("*.sql"))
        self.report.migrations_count = len(migration_files)

        for migration_file in migration_files:
            print(f"분석 중: {migration_file.name}")
            self._analyze_migration_file(migration_file)

    def _analyze_migration_file(self, file_path: Path):
        """개별 마이그레이션 파일 분석"""
        content = file_path.read_text(encoding="utf-8")

        # 테이블 생성 추출
        self._extract_tables(content, file_path.name)

        # 뷰 생성 추출
        self._extract_views(content, file_path.name)

        # 함수 생성 추출
        self._extract_functions(content, file_path.name)

    def _extract_tables(self, content: str, migration_file: str):
        """CREATE TABLE 문 추출"""
        # CREATE TABLE 패턴
        table_pattern = r"CREATE TABLE\s+(?:IF NOT EXISTS\s+)?(\w+)\s*\("
        fk_pattern = r"REFERENCES\s+(\w+)\s*\("

        for match in re.finditer(table_pattern, content, re.IGNORECASE):
            table_name = match.group(1)

            # 테이블 블록 추출 (괄호 매칭)
            start_pos = match.end()
            table_block = self._extract_block(content, start_pos)

            # TableInfo 생성
            table_info = TableInfo(
                name=table_name,
                migration_file=migration_file
            )

            # FK 추출
            for fk_match in re.finditer(fk_pattern, table_block, re.IGNORECASE):
                referenced_table = fk_match.group(1)
                table_info.foreign_keys.append({
                    "from": table_name,
                    "to": referenced_table
                })
                table_info.depends_on.add(referenced_table)

            self.tables[table_name] = table_info

    def _extract_views(self, content: str, migration_file: str):
        """CREATE VIEW 문 추출"""
        view_pattern = r"CREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+(\w+)\s+AS"

        for match in re.finditer(view_pattern, content, re.IGNORECASE):
            view_name = match.group(1)

            # 뷰 정의 블록 추출
            start_pos = match.end()
            view_block = self._extract_block_until_semicolon(content, start_pos)

            # ViewInfo 생성
            view_info = ViewInfo(
                name=view_name,
                migration_file=migration_file
            )

            # FROM/JOIN 절에서 테이블/뷰 참조 추출
            table_refs = self._extract_table_references(view_block)
            for ref in table_refs:
                if ref in self.tables:
                    view_info.referenced_tables.add(ref)
                elif ref in self.views:
                    view_info.referenced_views.add(ref)
                else:
                    # 아직 정의되지 않은 테이블일 수 있음
                    view_info.referenced_tables.add(ref)

            self.views[view_name] = view_info

    def _extract_functions(self, content: str, migration_file: str):
        """CREATE FUNCTION 문 추출"""
        func_pattern = r"CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(\w+)\s*\("

        for match in re.finditer(func_pattern, content, re.IGNORECASE):
            func_name = match.group(1)

            # 함수 정의 블록 추출
            start_pos = match.start()
            func_block = self._extract_function_block(content, start_pos)

            # FunctionInfo 생성
            func_info = FunctionInfo(
                name=func_name,
                migration_file=migration_file
            )

            # FROM/UPDATE/INSERT 절에서 테이블 참조 추출
            table_refs = self._extract_table_references(func_block)
            func_info.referenced_tables = set(
                ref for ref in table_refs if ref in self.tables
            )

            self.functions[func_name] = func_info

    def _extract_table_references(self, sql_block: str) -> Set[str]:
        """SQL 블록에서 테이블 참조 추출"""
        refs = set()

        # FROM 절
        from_pattern = r"\bFROM\s+(\w+)"
        for match in re.finditer(from_pattern, sql_block, re.IGNORECASE):
            refs.add(match.group(1))

        # JOIN 절
        join_pattern = r"\bJOIN\s+(\w+)"
        for match in re.finditer(join_pattern, sql_block, re.IGNORECASE):
            refs.add(match.group(1))

        # UPDATE 절
        update_pattern = r"\bUPDATE\s+(\w+)"
        for match in re.finditer(update_pattern, sql_block, re.IGNORECASE):
            refs.add(match.group(1))

        # INSERT INTO 절
        insert_pattern = r"\bINSERT\s+INTO\s+(\w+)"
        for match in re.finditer(insert_pattern, sql_block, re.IGNORECASE):
            refs.add(match.group(1))

        return refs

    def _extract_block(self, content: str, start_pos: int) -> str:
        """괄호로 감싸진 블록 추출"""
        depth = 1
        i = start_pos
        while i < len(content) and depth > 0:
            if content[i] == "(":
                depth += 1
            elif content[i] == ")":
                depth -= 1
            i += 1
        return content[start_pos:i]

    def _extract_block_until_semicolon(self, content: str, start_pos: int) -> str:
        """세미콜론까지 블록 추출"""
        end_pos = content.find(";", start_pos)
        if end_pos == -1:
            return content[start_pos:]
        return content[start_pos:end_pos]

    def _extract_function_block(self, content: str, start_pos: int) -> str:
        """함수 정의 블록 추출 ($$ ... $$ 또는 ; 까지)"""
        # $$ delimiter 찾기
        delimiter_start = content.find("$$", start_pos)
        if delimiter_start == -1:
            return self._extract_block_until_semicolon(content, start_pos)

        delimiter_end = content.find("$$", delimiter_start + 2)
        if delimiter_end == -1:
            return content[start_pos:]

        return content[start_pos:delimiter_end + 2]

    def validate(self) -> IntegrityReport:
        """무결성 검증 실행"""
        print("\n=== 무결성 검증 시작 ===\n")

        # 1. 테이블 목록 수집
        self.report.tables = sorted(self.tables.keys())
        print(f"총 테이블: {len(self.report.tables)}개")

        # 2. FK 관계 수집
        for table_info in self.tables.values():
            self.report.fk_relationships.extend(table_info.foreign_keys)
        print(f"총 FK 관계: {len(self.report.fk_relationships)}개")

        # 3. 뷰 목록 수집
        self.report.views = sorted(self.views.keys())
        print(f"총 뷰: {len(self.report.views)}개")

        # 4. 함수 목록 수집
        self.report.functions = sorted(self.functions.keys())
        print(f"총 함수: {len(self.report.functions)}개")

        # 5. FK 무결성 검증
        self._validate_foreign_keys()

        # 6. 뷰 의존성 검증
        self._validate_view_dependencies()

        # 7. 함수 의존성 검증
        self._validate_function_dependencies()

        # 8. 순환 참조 검증
        self._validate_circular_references()

        # 상태 결정
        if self.report.issues:
            self.report.status = "FAIL"
        else:
            self.report.status = "PASS"

        return self.report

    def _validate_foreign_keys(self):
        """FK 참조 무결성 검증"""
        print("\n[1] FK 참조 무결성 검증")
        for fk in self.report.fk_relationships:
            from_table = fk["from"]
            to_table = fk["to"]

            if to_table not in self.tables:
                issue = f"FK 참조 오류: {from_table} → {to_table} (테이블 {to_table} 미존재)"
                self.report.issues.append(issue)
                print(f"  [FAIL] {issue}")

        if not any("FK 참조 오류" in issue for issue in self.report.issues):
            print("  [OK] 모든 FK 참조 유효")

    def _validate_view_dependencies(self):
        """뷰 의존성 검증"""
        print("\n[2] 뷰 의존성 검증")
        for view_name, view_info in self.views.items():
            # 참조하는 테이블 검증
            for table_ref in view_info.referenced_tables:
                if table_ref not in self.tables and table_ref not in self.views:
                    issue = f"뷰 의존성 오류: {view_name} → {table_ref} (테이블/뷰 미존재)"
                    self.report.issues.append(issue)
                    print(f"  [FAIL] {issue}")

        if not any("뷰 의존성 오류" in issue for issue in self.report.issues):
            print("  [OK] 모든 뷰 의존성 유효")

    def _validate_function_dependencies(self):
        """함수 의존성 검증"""
        print("\n[3] 함수 의존성 검증")
        for func_name, func_info in self.functions.items():
            for table_ref in func_info.referenced_tables:
                if table_ref not in self.tables:
                    issue = f"함수 의존성 오류: {func_name} → {table_ref} (테이블 미존재)"
                    self.report.issues.append(issue)
                    print(f"  [FAIL] {issue}")

        if not any("함수 의존성 오류" in issue for issue in self.report.issues):
            print("  [OK] 모든 함수 의존성 유효")

    def _validate_circular_references(self):
        """순환 참조 검증"""
        print("\n[4] 순환 참조 검증")

        # 간단한 DFS 기반 순환 참조 검출
        def has_cycle(table: str, visited: Set[str], path: Set[str]) -> bool:
            if table in path:
                return True
            if table in visited:
                return False

            visited.add(table)
            path.add(table)

            table_info = self.tables.get(table)
            if table_info:
                for dep in table_info.depends_on:
                    if has_cycle(dep, visited, path):
                        return True

            path.remove(table)
            return False

        for table_name in self.tables:
            if has_cycle(table_name, set(), set()):
                issue = f"순환 참조 감지: {table_name} 테이블에서 시작"
                self.report.issues.append(issue)
                print(f"  [FAIL] {issue}")

        if not any("순환 참조 감지" in issue for issue in self.report.issues):
            print("  ✅ 순환 참조 없음")

    def generate_report(self, output_path: Path):
        """리포트 JSON 파일 생성"""
        report_dict = asdict(self.report)

        # Set을 List로 변환
        def convert_sets(obj):
            if isinstance(obj, dict):
                return {k: convert_sets(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_sets(item) for item in obj]
            elif isinstance(obj, set):
                return sorted(list(obj))
            else:
                return obj

        report_dict = convert_sets(report_dict)

        with output_path.open("w", encoding="utf-8") as f:
            json.dump(report_dict, f, indent=2, ensure_ascii=False)

        print(f"\n리포트 저장됨: {output_path}")


def main():
    """메인 실행"""
    migrations_dir = Path(r"C:\claude\automation_schema\supabase\migrations")
    output_path = Path(r"C:\claude\automation_schema\schema_integrity_report.json")

    validator = SchemaIntegrityValidator(migrations_dir)

    # 마이그레이션 분석
    validator.analyze_migrations()

    # 무결성 검증
    report = validator.validate()

    # 리포트 생성
    validator.generate_report(output_path)

    # 요약 출력
    print("\n" + "=" * 80)
    print("무결성 검증 요약")
    print("=" * 80)
    print(f"마이그레이션: {report.migrations_count}개")
    print(f"테이블: {len(report.tables)}개")
    print(f"FK 관계: {len(report.fk_relationships)}개")
    print(f"뷰: {len(report.views)}개")
    print(f"함수: {len(report.functions)}개")
    print(f"이슈: {len(report.issues)}개")
    print(f"상태: {report.status}")
    print("=" * 80)

    if report.issues:
        print("\n[WARNING] 발견된 이슈:")
        for i, issue in enumerate(report.issues, 1):
            print(f"  {i}. {issue}")
    else:
        print("\n[SUCCESS] 모든 검증 통과!")


if __name__ == "__main__":
    main()
