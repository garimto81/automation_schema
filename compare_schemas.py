"""
table-pokercaster vs table-GG JSON 스키마 비교
"""

from pathlib import Path
import json

def load_field_list(file_path: Path) -> set:
    """필드 목록 파일 로드"""
    if not file_path.exists():
        return set()

    with open(file_path, 'r', encoding='utf-8') as f:
        return set(line.strip() for line in f if line.strip())

def main():
    # Pokercaster 필드 목록
    pokercaster_file = Path(r"C:\claude\automation_schema\pokercaster_fields.txt")
    pokercaster_fields = load_field_list(pokercaster_file)

    # GG 필드 목록 생성 (기존 분석 결과가 없으므로 수동으로 생성)
    # table-GG 샘플을 분석해서 필드 목록 추출
    base_path = Path(r"C:\claude\automation_schema\gfx_json_data\table-GG")

    if not base_path.exists():
        print(f"[ERROR] table-GG 경로 없음: {base_path}")
        return

    # GG 폴더에서 JSON 샘플 분석
    from collections import defaultdict

    def extract_fields(obj, prefix=""):
        fields = set()
        if isinstance(obj, dict):
            for key, value in obj.items():
                full_key = f"{prefix}.{key}" if prefix else key
                fields.add(full_key)

                if isinstance(value, dict):
                    fields.update(extract_fields(value, full_key))
                elif isinstance(value, list) and len(value) > 0:
                    if isinstance(value[0], dict):
                        fields.update(extract_fields(value[0], f"{full_key}[]"))
        return fields

    gg_fields = set()

    # 1020 폴더에서 샘플 추출
    folder_1020 = base_path / "1020"
    if folder_1020.exists():
        json_files = list(folder_1020.glob("*.json"))[:2]

        for json_file in json_files:
            print(f"[GG] 분석 중: {json_file.name}")
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    gg_fields.update(extract_fields(data))
            except Exception as e:
                print(f"  [ERROR] {e}")

    # 1019/new 폴더도 확인
    folder_1019_new = base_path / "1019" / "new"
    if folder_1019_new.exists():
        json_files = list(folder_1019_new.glob("*.json"))[:2]

        for json_file in json_files:
            print(f"[GG] 분석 중: {json_file.name}")
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    gg_fields.update(extract_fields(data))
            except Exception as e:
                print(f"  [ERROR] {e}")

    # GG 필드 목록 저장
    gg_fields_file = Path(r"C:\claude\automation_schema\gg_fields.txt")
    with open(gg_fields_file, 'w', encoding='utf-8') as f:
        for field in sorted(gg_fields):
            f.write(f"{field}\n")

    print(f"\n[OK] GG 필드 목록 저장: {gg_fields_file}")
    print(f"     총 {len(gg_fields)}개 필드")

    # 비교 분석
    print(f"\n{'='*80}")
    print(f"[비교] Pokercaster vs GG")
    print(f"{'='*80}\n")

    print(f"Pokercaster 필드 수: {len(pokercaster_fields)}")
    print(f"GG 필드 수: {len(gg_fields)}")

    # Pokercaster에만 있는 필드
    only_pokercaster = pokercaster_fields - gg_fields
    print(f"\n[Pokercaster 전용 필드] ({len(only_pokercaster)}개)")
    for field in sorted(only_pokercaster):
        print(f"  + {field}")

    # GG에만 있는 필드
    only_gg = gg_fields - pokercaster_fields
    print(f"\n[GG 전용 필드] ({len(only_gg)}개)")
    for field in sorted(only_gg):
        print(f"  - {field}")

    # 공통 필드
    common = pokercaster_fields & gg_fields
    print(f"\n[공통 필드] ({len(common)}개)")

    # 비교 리포트 생성
    report_lines = []
    report_lines.append("# table-pokercaster vs table-GG 스키마 비교\n")
    report_lines.append(f"**분석 일시**: 2026-01-19\n")
    report_lines.append(f"**Pokercaster 필드 수**: {len(pokercaster_fields)}개\n")
    report_lines.append(f"**GG 필드 수**: {len(gg_fields)}개\n")
    report_lines.append(f"**공통 필드 수**: {len(common)}개\n")
    report_lines.append("\n---\n")

    report_lines.append(f"\n## Pokercaster 전용 필드 ({len(only_pokercaster)}개)\n")
    report_lines.append("\n> GG에는 없고 Pokercaster에만 존재하는 필드\n")
    for field in sorted(only_pokercaster):
        report_lines.append(f"- `{field}`")

    report_lines.append(f"\n## GG 전용 필드 ({len(only_gg)}개)\n")
    report_lines.append("\n> Pokercaster에는 없고 GG에만 존재하는 필드\n")
    for field in sorted(only_gg):
        report_lines.append(f"- `{field}`")

    report_lines.append(f"\n## 공통 필드 ({len(common)}개)\n")
    report_lines.append("\n> 양쪽 모두에 존재하는 필드\n")

    # 카테고리별 분류
    categories = {
        "Root Level": [],
        "Hands[]": [],
        "Events[]": [],
        "Players[]": [],
        "FlopDrawBlinds": [],
        "StudLimits": []
    }

    for field in sorted(common):
        if field.startswith("Hands[].Events[]"):
            categories["Events[]"].append(field)
        elif field.startswith("Hands[].Players[]"):
            categories["Players[]"].append(field)
        elif field.startswith("Hands[].FlopDrawBlinds"):
            categories["FlopDrawBlinds"].append(field)
        elif field.startswith("Hands[].StudLimits"):
            categories["StudLimits"].append(field)
        elif field.startswith("Hands[]"):
            categories["Hands[]"].append(field)
        else:
            categories["Root Level"].append(field)

    for category, fields in categories.items():
        if fields:
            report_lines.append(f"\n### {category} ({len(fields)}개)\n")
            for field in fields:
                report_lines.append(f"- `{field}`")

    report = "\n".join(report_lines)

    # 리포트 저장
    output_file = Path(r"C:\claude\automation_schema\schema_comparison_report.md")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(report)

    print(f"\n[OK] 비교 리포트 저장: {output_file}")

if __name__ == "__main__":
    main()
