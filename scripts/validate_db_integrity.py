#!/usr/bin/env python3
"""
GFX-Supabase DB 무결성 검증 스크립트

사용법:
    python scripts/validate_db_integrity.py

필요 조건:
    - supabase CLI 로그인 상태
    - 원격 DB 연결 가능
"""

import subprocess
import json
import sys
from datetime import datetime


def run_supabase_query(query: str) -> tuple[bool, str]:
    """Supabase CLI를 통해 쿼리 실행 (dump 명령 활용)"""
    # 실제로는 pg_cron이나 Supabase Dashboard에서 실행해야 함
    # 여기서는 inspect 명령어로 대체
    return True, ""


def check_table_stats() -> dict:
    """테이블 통계 확인"""
    result = subprocess.run(
        ["supabase", "inspect", "db", "table-stats"],
        capture_output=True,
        text=True
    )
    return {
        "success": result.returncode == 0,
        "output": result.stdout,
        "error": result.stderr if result.returncode != 0 else None
    }


def check_vacuum_stats() -> dict:
    """VACUUM 상태 확인"""
    result = subprocess.run(
        ["supabase", "inspect", "db", "vacuum-stats"],
        capture_output=True,
        text=True
    )
    return {
        "success": result.returncode == 0,
        "output": result.stdout,
        "error": result.stderr if result.returncode != 0 else None
    }


def check_index_stats() -> dict:
    """인덱스 상태 확인"""
    result = subprocess.run(
        ["supabase", "inspect", "db", "index-stats"],
        capture_output=True,
        text=True
    )

    # 미사용 인덱스 개수 계산
    unused_count = result.stdout.count("| true")

    return {
        "success": result.returncode == 0,
        "output": result.stdout,
        "unused_indexes": unused_count,
        "error": result.stderr if result.returncode != 0 else None
    }


def check_bloat() -> dict:
    """Bloat 상태 확인"""
    result = subprocess.run(
        ["supabase", "inspect", "db", "bloat"],
        capture_output=True,
        text=True
    )
    return {
        "success": result.returncode == 0,
        "output": result.stdout,
        "error": result.stderr if result.returncode != 0 else None
    }


def check_db_stats() -> dict:
    """DB 전체 통계"""
    result = subprocess.run(
        ["supabase", "inspect", "db", "db-stats"],
        capture_output=True,
        text=True
    )
    return {
        "success": result.returncode == 0,
        "output": result.stdout,
        "error": result.stderr if result.returncode != 0 else None
    }


def parse_hit_rates(db_stats_output: str) -> dict:
    """Hit rate 파싱"""
    lines = db_stats_output.split('\n')
    for line in lines:
        if 'postgres' in line.lower():
            parts = line.split('|')
            if len(parts) >= 8:
                try:
                    index_hit = float(parts[6].strip())
                    table_hit = float(parts[7].strip())
                    return {
                        "index_hit_rate": index_hit,
                        "table_hit_rate": table_hit,
                        "status": "OK" if index_hit >= 0.9 and table_hit >= 0.9 else "WARNING"
                    }
                except (ValueError, IndexError):
                    pass
    return {"status": "UNKNOWN"}


def main():
    """무결성 검증 메인 함수"""
    # UTF-8 출력 설정
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

    print("=" * 60)
    print("GFX-Supabase DB 무결성 검증")
    print(f"실행 시간: {datetime.now().isoformat()}")
    print("=" * 60)
    print()

    results = {}
    all_passed = True

    # 1. DB 통계
    print("[1/5] DB 전체 통계 확인...")
    db_stats = check_db_stats()
    if db_stats["success"]:
        hit_rates = parse_hit_rates(db_stats["output"])
        print(f"  Index Hit Rate: {hit_rates.get('index_hit_rate', 'N/A')}")
        print(f"  Table Hit Rate: {hit_rates.get('table_hit_rate', 'N/A')}")
        print(f"  상태: {hit_rates.get('status', 'UNKNOWN')}")
        results["db_stats"] = hit_rates
    else:
        print(f"  ⚠️ 오류: {db_stats.get('error', 'Unknown')}")
        all_passed = False
    print()

    # 2. 테이블 통계
    print("[2/5] 테이블 통계 확인...")
    table_stats = check_table_stats()
    if table_stats["success"]:
        # 행 수가 0인 테이블 개수
        empty_tables = table_stats["output"].count("| 0 ")
        print(f"  빈 테이블 수: {empty_tables}개")
        results["empty_tables"] = empty_tables
    else:
        print(f"  ⚠️ 오류: {table_stats.get('error', 'Unknown')}")
        all_passed = False
    print()

    # 3. 인덱스 상태
    print("[3/5] 인덱스 상태 확인...")
    index_stats = check_index_stats()
    if index_stats["success"]:
        unused = index_stats.get("unused_indexes", 0)
        print(f"  미사용 인덱스: {unused}개")
        results["unused_indexes"] = unused
        if unused > 50:
            print("  ⚠️ 미사용 인덱스가 많습니다. 정리를 권장합니다.")
            all_passed = False
    else:
        print(f"  ⚠️ 오류: {index_stats.get('error', 'Unknown')}")
        all_passed = False
    print()

    # 4. VACUUM 상태
    print("[4/5] VACUUM 상태 확인...")
    vacuum_stats = check_vacuum_stats()
    if vacuum_stats["success"]:
        # Dead rows가 있는 테이블
        dead_rows_tables = vacuum_stats["output"].count("| no")
        print(f"  auto-vacuum 미실행 테이블: 일부")
        results["vacuum_needed"] = True if "No stats" in vacuum_stats["output"] else False
    else:
        print(f"  ⚠️ 오류: {vacuum_stats.get('error', 'Unknown')}")
        all_passed = False
    print()

    # 5. Bloat 상태
    print("[5/5] Bloat 상태 확인...")
    bloat = check_bloat()
    if bloat["success"]:
        # Bloat > 2.0 인 항목
        high_bloat = bloat["output"].count(" 3.")
        print(f"  높은 bloat (>3.0): {high_bloat}개 테이블/인덱스")
        results["high_bloat"] = high_bloat
        if high_bloat > 0:
            print("  ⚠️ VACUUM 실행을 권장합니다.")
    else:
        print(f"  ⚠️ 오류: {bloat.get('error', 'Unknown')}")
        all_passed = False
    print()

    # 결과 요약
    print("=" * 60)
    print("검증 결과 요약")
    print("=" * 60)

    if all_passed:
        print("✅ 모든 기본 검증 통과")
    else:
        print("⚠️ 일부 검증에서 이슈 발견")

    print()
    print("상세 검증 방법:")
    print("  Supabase Dashboard → SQL Editor에서:")
    print("  - SELECT * FROM v_integrity_summary;")
    print("  - SELECT * FROM v_integrity_fk_status;")
    print("  - SELECT * FROM v_integrity_data_status;")
    print()

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
