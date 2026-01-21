"""
GFX JSON 데이터 분석 스크립트 (table-GG 소스)
6개 JSON 파일의 구조, 필드, 데이터 타입, 샘플값 분석
"""

import json
from pathlib import Path
from collections import defaultdict
from typing import Any, Dict, List, Set
import sys

def extract_fields(obj: Any, parent_path: str = "") -> Dict[str, List[Any]]:
    """중첩 JSON 객체에서 모든 필드 경로와 값 추출"""
    fields = defaultdict(list)

    if isinstance(obj, dict):
        for key, value in obj.items():
            current_path = f"{parent_path}.{key}" if parent_path else key
            fields[current_path].append(value)

            # 중첩 객체 재귀 처리
            if isinstance(value, (dict, list)):
                nested = extract_fields(value, current_path)
                for nested_path, nested_values in nested.items():
                    fields[nested_path].extend(nested_values)

    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            # 배열 내부 객체는 [*] 표기
            if isinstance(item, dict):
                nested = extract_fields(item, f"{parent_path}[*]")
                for nested_path, nested_values in nested.items():
                    fields[nested_path].extend(nested_values)
            else:
                fields[f"{parent_path}[*]"].append(item)

    return fields

def infer_type(values: List[Any]) -> str:
    """값들로부터 데이터 타입 추론"""
    types = set()
    for v in values:
        if v is None:
            types.add("null")
        elif isinstance(v, bool):
            types.add("boolean")
        elif isinstance(v, int):
            types.add("integer")
        elif isinstance(v, float):
            types.add("number")
        elif isinstance(v, str):
            types.add("string")
        elif isinstance(v, list):
            types.add("array")
        elif isinstance(v, dict):
            types.add("object")

    # null 제외하고 주요 타입 반환
    non_null_types = types - {"null"}
    if not non_null_types:
        return "null"
    elif len(non_null_types) == 1:
        return list(non_null_types)[0]
    else:
        return "|".join(sorted(non_null_types))

def get_unique_samples(values: List[Any], max_samples: int = 10) -> List[Any]:
    """고유값 우선으로 샘플 추출"""
    # null 제외
    non_null = [v for v in values if v is not None]

    # 단순 타입만 샘플링 (dict/list 제외)
    simple_values = [v for v in non_null if not isinstance(v, (dict, list))]

    # 고유값 추출
    unique = []
    seen = set()
    for v in simple_values:
        # 문자열/숫자만 처리
        if isinstance(v, (str, int, float, bool)):
            str_v = str(v)
            if str_v not in seen:
                seen.add(str_v)
                unique.append(v)
                if len(unique) >= max_samples:
                    break

    return unique

def calculate_null_ratio(values: List[Any]) -> float:
    """null/빈값 비율 계산"""
    if not values:
        return 1.0

    null_count = sum(1 for v in values if v is None or v == "" or v == [])
    return null_count / len(values)

def infer_description(field_path: str, sample_values: List[Any]) -> str:
    """필드 경로와 샘플값으로 용도 추론"""
    path_lower = field_path.lower()

    # 경로 기반 추론
    if "datetime" in path_lower or "date" in path_lower:
        return "날짜/시간 정보"
    elif "amt" in path_lower or "amount" in path_lower:
        return "금액/수량"
    elif "num" in path_lower or "number" in path_lower:
        return "번호/숫자 식별자"
    elif "player" in path_lower:
        return "플레이어 관련 데이터"
    elif "card" in path_lower:
        return "카드 정보"
    elif "bet" in path_lower:
        return "베팅 정보"
    elif "pot" in path_lower:
        return "팟 금액"
    elif "blind" in path_lower:
        return "블라인드 정보"
    elif "event" in path_lower:
        return "게임 이벤트"
    elif "hand" in path_lower:
        return "핸드 데이터"
    elif "stack" in path_lower:
        return "스택 금액"
    elif "name" in path_lower:
        return "이름"
    elif "type" in path_lower:
        return "타입/분류"
    elif "percent" in path_lower:
        return "퍼센트 값"
    elif "rank" in path_lower:
        return "순위"
    else:
        return "기타"

def analyze_json_files(file_paths: List[Path]) -> Dict:
    """여러 JSON 파일 종합 분석"""
    all_fields = defaultdict(list)

    print(f"분석 시작: {len(file_paths)}개 파일")

    for idx, file_path in enumerate(file_paths, 1):
        print(f"  [{idx}/{len(file_paths)}] {file_path.name}")

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 필드 추출
            fields = extract_fields(data)
            for field_path, values in fields.items():
                all_fields[field_path].extend(values)

        except Exception as e:
            print(f"    [WARN] 에러: {e}")
            continue

    # 필드별 통계 생성
    field_stats = {}

    print(f"\n필드 분석 중... ({len(all_fields)}개 필드)")

    for field_path, values in sorted(all_fields.items()):
        data_type = infer_type(values)
        sample_values = get_unique_samples(values, max_samples=10)
        null_ratio = calculate_null_ratio(values)
        description = infer_description(field_path, sample_values)

        field_stats[field_path] = {
            "type": data_type,
            "sample_values": sample_values,
            "null_ratio": round(null_ratio, 3),
            "description_hint": description,
            "total_occurrences": len(values)
        }

    # 구조 추출 (최상위 키)
    structure = {}
    for field_path in all_fields.keys():
        if '.' not in field_path and '[*]' not in field_path:
            structure[field_path] = infer_type(all_fields[field_path])

    result = {
        "source": "table-GG",
        "files_analyzed": len(file_paths),
        "total_fields": len(field_stats),
        "structure": structure,
        "fields": field_stats
    }

    return result

def main():
    # 6개 파일 경로
    base_dir = Path(r"C:\claude\automation_schema\gfx_json_data\table-GG")

    file_paths = [
        base_dir / "1015" / "PGFX_live_data_export GameID=638961224831992165.json",
        base_dir / "1016" / "PGFX_live_data_export GameID=638962014211467634.json",
        base_dir / "1017" / "PGFX_live_data_export GameID=638962926097967686.json",
        base_dir / "1018" / "PGFX_live_data_export GameID=638963849867159576.json",
        base_dir / "1019" / "PGFX_live_data_export GameID=638964779338222042.json",
        base_dir / "1020" / "PGFX_live_data_export GameID=638965539561171011.json",
    ]

    # 파일 존재 확인
    existing_files = [f for f in file_paths if f.exists()]

    if not existing_files:
        print("[ERROR] 파일을 찾을 수 없습니다.")
        sys.exit(1)

    print(f"[OK] {len(existing_files)}/{len(file_paths)}개 파일 발견\n")

    # 분석 실행
    result = analyze_json_files(existing_files)

    # 결과 저장
    output_path = Path(r"C:\claude\automation_schema\gfx_table_gg_analysis.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    print(f"\n[DONE] 분석 완료: {output_path}")
    print(f"   - 파일 수: {result['files_analyzed']}")
    print(f"   - 필드 수: {result['total_fields']}")
    print(f"   - 최상위 구조: {list(result['structure'].keys())}")

if __name__ == "__main__":
    main()
