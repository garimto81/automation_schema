"""
table-pokercaster JSON 파일 스키마 분석 스크립트
각 폴더(1016-1021)의 JSON 파일에서 모든 필드를 추출하여 스키마 리포트 생성
"""

import json
from pathlib import Path
from collections import defaultdict
from typing import Any, Dict, Set
import sys

def get_value_sample(value: Any, max_len: int = 50) -> str:
    """값의 타입과 샘플을 반환"""
    if value is None:
        return "null"
    elif isinstance(value, bool):
        return f"boolean: {value}"
    elif isinstance(value, int):
        return f"integer: {value}"
    elif isinstance(value, float):
        return f"float: {value}"
    elif isinstance(value, str):
        sample = value[:max_len] + "..." if len(value) > max_len else value
        return f'string: "{sample}"'
    elif isinstance(value, list):
        if len(value) == 0:
            return "array: []"
        return f"array[{len(value)}]: [{type(value[0]).__name__}...]"
    elif isinstance(value, dict):
        return f"object: {{{len(value)} keys}}"
    return str(type(value).__name__)

def extract_fields(obj: Any, prefix: str = "") -> Dict[str, Set[str]]:
    """재귀적으로 모든 필드 추출 (타입 및 샘플 포함)"""
    fields = defaultdict(set)

    if isinstance(obj, dict):
        for key, value in obj.items():
            full_key = f"{prefix}.{key}" if prefix else key
            sample = get_value_sample(value)
            fields[full_key].add(sample)

            # 중첩 객체/배열 재귀 처리
            if isinstance(value, dict):
                nested = extract_fields(value, full_key)
                for k, v in nested.items():
                    fields[k].update(v)
            elif isinstance(value, list) and len(value) > 0:
                # 배열의 첫 번째 요소 기준으로 스키마 추출
                if isinstance(value[0], dict):
                    nested = extract_fields(value[0], f"{full_key}[]")
                    for k, v in nested.items():
                        fields[k].update(v)

    return fields

def analyze_json_file(file_path: Path) -> Dict[str, Set[str]]:
    """단일 JSON 파일 분석"""
    print(f"  분석 중: {file_path.name}")

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # 단일 라인 JSON 또는 일반 JSON 처리
            content = f.read()
            data = json.loads(content)
            return extract_fields(data)
    except Exception as e:
        print(f"  ⚠️  오류: {file_path.name} - {e}")
        return {}

def merge_fields(all_fields: Dict[str, Set[str]], new_fields: Dict[str, Set[str]]):
    """필드 딕셔너리 병합"""
    for key, values in new_fields.items():
        all_fields[key].update(values)

def main():
    base_path = Path(r"C:\claude\automation_schema\gfx_json_data\table-pokercaster")

    if not base_path.exists():
        print(f"❌ 경로가 존재하지 않습니다: {base_path}")
        return

    # 분석할 폴더 목록
    folders = ["1016", "1017", "1018", "1019", "1021"]

    all_fields = defaultdict(set)
    total_files = 0

    for folder in folders:
        folder_path = base_path / folder
        if not folder_path.exists():
            print(f"⚠️  폴더 없음: {folder}")
            continue

        print(f"\n[{folder}] 폴더 분석 중...")

        # JSON 파일만 필터링 (.txt 제외)
        json_files = [f for f in folder_path.glob("*.json")]

        if not json_files:
            print(f"  JSON 파일 없음")
            continue

        # 각 폴더당 최대 2개 파일만 샘플링 (성능 최적화)
        for json_file in json_files[:2]:
            fields = analyze_json_file(json_file)
            merge_fields(all_fields, fields)
            total_files += 1

    # 결과 출력
    print(f"\n{'='*80}")
    print(f"[결과] 전체 분석 완료: {total_files}개 파일")
    print(f"{'='*80}\n")

    # 카테고리별 필드 분류
    categories = {
        "Root Level": [],
        "Hands[]": [],
        "Hands[].Events[]": [],
        "Hands[].Players[]": [],
        "Hands[].FlopDrawBlinds": [],
        "Hands[].StudLimits": [],
        "Payouts[]": []
    }

    for field, samples in sorted(all_fields.items()):
        if field.startswith("Hands[].Events[]"):
            categories["Hands[].Events[]"].append((field, samples))
        elif field.startswith("Hands[].Players[]"):
            categories["Hands[].Players[]"].append((field, samples))
        elif field.startswith("Hands[].FlopDrawBlinds"):
            categories["Hands[].FlopDrawBlinds"].append((field, samples))
        elif field.startswith("Hands[].StudLimits"):
            categories["Hands[].StudLimits"].append((field, samples))
        elif field.startswith("Hands[]"):
            categories["Hands[]"].append((field, samples))
        elif field.startswith("Payouts"):
            categories["Payouts[]"].append((field, samples))
        else:
            categories["Root Level"].append((field, samples))

    # 리포트 생성
    report_lines = []
    report_lines.append("# table-pokercaster JSON 스키마 분석 리포트\n")
    report_lines.append(f"**분석 파일 수**: {total_files}개\n")
    report_lines.append(f"**분석 폴더**: {', '.join(folders)}\n")
    report_lines.append(f"**총 필드 수**: {len(all_fields)}개\n")
    report_lines.append("\n---\n")

    for category, fields in categories.items():
        if not fields:
            continue

        report_lines.append(f"\n## {category}\n")
        report_lines.append(f"**필드 수**: {len(fields)}개\n")
        report_lines.append("")

        for field, samples in sorted(fields):
            # 카테고리 prefix 제거
            display_field = field
            if category == "Hands[].Events[]":
                display_field = field.replace("Hands[].Events[].", "")
            elif category == "Hands[].Players[]":
                display_field = field.replace("Hands[].Players[].", "")
            elif category == "Hands[].FlopDrawBlinds":
                display_field = field.replace("Hands[].FlopDrawBlinds.", "")
            elif category == "Hands[].StudLimits":
                display_field = field.replace("Hands[].StudLimits.", "")
            elif category == "Hands[]":
                display_field = field.replace("Hands[].", "")

            samples_str = " | ".join(sorted(samples)[:3])  # 최대 3개 샘플
            report_lines.append(f"- **{display_field}**: {samples_str}")

    report = "\n".join(report_lines)

    # 콘솔 출력
    print(report)

    # 파일 저장
    output_file = Path(r"C:\claude\automation_schema\pokercaster_schema_report.md")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(report)

    print(f"\n[OK] 리포트 저장: {output_file}")

    # table-GG와 비교용 필드 목록 저장
    field_list_file = Path(r"C:\claude\automation_schema\pokercaster_fields.txt")
    with open(field_list_file, 'w', encoding='utf-8') as f:
        for field in sorted(all_fields.keys()):
            f.write(f"{field}\n")

    print(f"[OK] 필드 목록 저장: {field_list_file}")

if __name__ == "__main__":
    main()
