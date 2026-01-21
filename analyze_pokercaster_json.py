"""
GFX JSON (table-pokercaster) 필드 분석 스크립트
"""
import json
from pathlib import Path
from collections import defaultdict, Counter
from typing import Any, Dict, List, Set

def get_field_path(obj: Any, prefix: str = "") -> Dict[str, List[Any]]:
    """재귀적으로 모든 필드 경로와 값 추출"""
    fields = defaultdict(list)

    if isinstance(obj, dict):
        for key, value in obj.items():
            current_path = f"{prefix}.{key}" if prefix else key
            fields[current_path].append(value)

            # 중첩 구조 탐색
            if isinstance(value, (dict, list)):
                nested = get_field_path(value, current_path)
                for nested_path, nested_values in nested.items():
                    fields[nested_path].extend(nested_values)

    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            if isinstance(item, (dict, list)):
                nested = get_field_path(item, prefix)
                for nested_path, nested_values in nested.items():
                    fields[nested_path].extend(nested_values)
            else:
                fields[prefix].append(item)

    return fields

def get_type_name(value: Any) -> str:
    """값의 타입 판별"""
    if value is None:
        return "null"
    elif isinstance(value, bool):
        return "boolean"
    elif isinstance(value, int):
        return "integer"
    elif isinstance(value, float):
        return "number"
    elif isinstance(value, str):
        return "string"
    elif isinstance(value, list):
        return "array"
    elif isinstance(value, dict):
        return "object"
    else:
        return "unknown"

def analyze_files(file_paths: List[Path]) -> Dict:
    """여러 JSON 파일 통합 분석"""
    all_fields = defaultdict(list)
    file_count = 0

    for file_path in file_paths:
        if not file_path.exists():
            print(f"⚠️ 파일 없음: {file_path}")
            continue

        print(f"분석 중: {file_path.name}")

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            fields = get_field_path(data)
            for field_path, values in fields.items():
                all_fields[field_path].extend(values)

            file_count += 1
        except Exception as e:
            print(f"❌ 파일 읽기 실패: {file_path.name} - {e}")

    # 필드별 통계 생성
    field_stats = {}

    for field_path, values in sorted(all_fields.items()):
        total_count = len(values)
        null_count = sum(1 for v in values if v is None or v == "")
        non_null_values = [v for v in values if v is not None and v != ""]

        # 타입 분석
        type_counter = Counter(get_type_name(v) for v in values)
        primary_type = type_counter.most_common(1)[0][0] if type_counter else "unknown"

        # 샘플 값 추출 (고유값 우선, 최대 10개)
        sample_values = []
        if non_null_values:
            # 간단한 타입만 샘플링 (object/array 제외)
            simple_values = [v for v in non_null_values if not isinstance(v, (dict, list))]
            if simple_values:
                unique_values = list(dict.fromkeys(simple_values))[:10]
                sample_values = unique_values

        # 설명 힌트 추론
        description_hint = infer_description(field_path, sample_values, primary_type)

        field_stats[field_path] = {
            "type": primary_type,
            "type_distribution": dict(type_counter),
            "sample_values": sample_values,
            "null_ratio": round(null_count / total_count, 3) if total_count > 0 else 0.0,
            "total_occurrences": total_count,
            "description_hint": description_hint
        }

    return {
        "source": "table-pokercaster",
        "files_analyzed": file_count,
        "total_fields": len(field_stats),
        "fields": field_stats
    }

def infer_description(field_path: str, sample_values: List, field_type: str) -> str:
    """필드명과 샘플값으로 용도 추론"""
    path_lower = field_path.lower()

    # 필드명 기반 추론
    if 'id' in path_lower:
        return "고유 식별자"
    elif 'name' in path_lower:
        return "이름/명칭"
    elif 'time' in path_lower or 'date' in path_lower:
        return "시간/날짜 정보"
    elif 'amount' in path_lower or 'chip' in path_lower:
        return "칩 수량"
    elif 'pot' in path_lower:
        return "팟 관련 정보"
    elif 'card' in path_lower:
        return "카드 정보"
    elif 'player' in path_lower:
        return "플레이어 관련 정보"
    elif 'hand' in path_lower:
        return "핸드 정보"
    elif 'action' in path_lower:
        return "액션 정보"
    elif 'seat' in path_lower:
        return "좌석 관련"
    elif 'position' in path_lower:
        return "위치 정보"
    elif 'status' in path_lower or 'state' in path_lower:
        return "상태 정보"
    elif 'count' in path_lower or 'number' in path_lower:
        return "개수/번호"
    elif field_type == "boolean":
        return "플래그 (참/거짓)"

    return "미분류"

def main():
    # 분석 대상 파일 목록
    base_dir = Path(r"C:\claude\automation_schema\gfx_json_data\table-pokercaster")

    file_paths = [
        base_dir / "1016" / "PGFX_live_data_export GameID=638962090875783819.json",
        base_dir / "1017" / "PGFX_live_data_export GameID=638962967524560670.json",
        base_dir / "1018" / "PGFX_live_data_export GameID=638963847602984623.json",
        base_dir / "1019" / "PGFX_live_data_export GameID=638964779563363778.json",
        base_dir / "1021" / "PGFX_live_data_export GameID=638966318331324926.json",
    ]

    print("=" * 80)
    print("GFX JSON (table-pokercaster) 필드 분석")
    print("=" * 80)

    result = analyze_files(file_paths)

    # 결과 저장
    output_path = Path(r"C:\claude\automation_schema\pokercaster_fields_analysis.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    print(f"\n✅ 분석 완료")
    print(f"   - 파일 수: {result['files_analyzed']}")
    print(f"   - 필드 수: {result['total_fields']}")
    print(f"   - 결과 저장: {output_path}")

    # 주요 통계 출력
    print("\n" + "=" * 80)
    print("주요 필드 (샘플)")
    print("=" * 80)

    for idx, (field_path, stats) in enumerate(list(result['fields'].items())[:20], 1):
        print(f"\n{idx}. {field_path}")
        print(f"   타입: {stats['type']}")
        print(f"   Null 비율: {stats['null_ratio']:.1%}")
        print(f"   샘플값: {stats['sample_values'][:3]}")
        print(f"   용도: {stats['description_hint']}")

if __name__ == "__main__":
    main()
