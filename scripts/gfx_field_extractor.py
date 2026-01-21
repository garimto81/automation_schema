"""
GFX JSON 필드 추출기

각 필드별 데이터 추출 및 통계 생성 스크립트.
28개 JSON 파일에서 60개 필드의 값을 추출하고 분석합니다.

Usage:
    python scripts/gfx_field_extractor.py [--input-dir DIR] [--output FILE]
    python scripts/gfx_field_extractor.py --field "Hands[*].Players[*].Name"
    python scripts/gfx_field_extractor.py --stats
"""

import json
import argparse
from pathlib import Path
from collections import defaultdict
from typing import Any, Generator
import re
from datetime import datetime


# 기본 경로
DEFAULT_INPUT_DIR = Path(r"C:\claude\automation_schema\gfx_json_data")
DEFAULT_OUTPUT = Path(r"C:\claude\automation_schema\gfx_extracted_fields.json")


# 필드 정의 (계층별)
FIELD_DEFINITIONS = {
    # Root Level
    "root": [
        "ID",
        "CreatedDateTimeUTC",
        "SoftwareVersion",
        "Type",
        "EventTitle",
        "Payouts",
    ],
    # Hands Level
    "hands": [
        "HandNum",
        "AnteAmt",
        "BetStructure",
        "BombPotAmt",
        "Description",
        "Duration",
        "GameClass",
        "GameVariant",
        "NumBoards",
        "RunItNumTimes",
        "StartDateTimeUTC",
        "RecordingOffsetStart",
    ],
    # FlopDrawBlinds
    "blinds": [
        "FlopDrawBlinds.AnteType",
        "FlopDrawBlinds.BigBlindAmt",
        "FlopDrawBlinds.BigBlindPlayerNum",
        "FlopDrawBlinds.BlindLevel",
        "FlopDrawBlinds.ButtonPlayerNum",
        "FlopDrawBlinds.SmallBlindAmt",
        "FlopDrawBlinds.SmallBlindPlayerNum",
        "FlopDrawBlinds.ThirdBlindAmt",
        "FlopDrawBlinds.ThirdBlindPlayerNum",
    ],
    # StudLimits
    "stud": [
        "StudLimits.BringInAmt",
        "StudLimits.BringInPlayerNum",
        "StudLimits.HighLimitAmt",
        "StudLimits.LowLimitAmt",
    ],
    # Players
    "players": [
        "PlayerNum",
        "Name",
        "LongName",
        "StartStackAmt",
        "EndStackAmt",
        "CumulativeWinningsAmt",
        "HoleCards",
        "SittingOut",
        "EliminationRank",
        "BlindBetStraddleAmt",
        "VPIPPercent",
        "PreFlopRaisePercent",
        "AggressionFrequencyPercent",
        "WentToShowDownPercent",
    ],
    # Events
    "events": [
        "EventType",
        "PlayerNum",
        "BetAmt",
        "Pot",
        "BoardNum",
        "BoardCards",
        "NumCardsDrawn",
        "DateTimeUTC",
    ],
}


def find_json_files(input_dir: Path) -> list[Path]:
    """JSON 파일 목록 반환"""
    return list(input_dir.rglob("*.json"))


def load_json(file_path: Path) -> dict | None:
    """JSON 파일 로드"""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"Error loading {file_path}: {e}")
        return None


def extract_value(data: dict, path: str) -> Any:
    """중첩 경로에서 값 추출 (예: 'FlopDrawBlinds.BigBlindAmt')"""
    keys = path.split(".")
    value = data
    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            return None
    return value


def extract_root_fields(data: dict) -> dict:
    """Root 레벨 필드 추출"""
    result = {}
    for field in FIELD_DEFINITIONS["root"]:
        result[field] = data.get(field)
    return result


def extract_hand_fields(hand: dict) -> dict:
    """Hand 레벨 필드 추출"""
    result = {}

    # 기본 Hand 필드
    for field in FIELD_DEFINITIONS["hands"]:
        result[field] = hand.get(field)

    # FlopDrawBlinds 필드
    for field in FIELD_DEFINITIONS["blinds"]:
        result[field] = extract_value(hand, field)

    # StudLimits 필드
    for field in FIELD_DEFINITIONS["stud"]:
        result[field] = extract_value(hand, field)

    return result


def extract_player_fields(player: dict) -> dict:
    """Player 레벨 필드 추출"""
    result = {}
    for field in FIELD_DEFINITIONS["players"]:
        result[field] = player.get(field)
    return result


def extract_event_fields(event: dict) -> dict:
    """Event 레벨 필드 추출"""
    result = {}
    for field in FIELD_DEFINITIONS["events"]:
        result[field] = event.get(field)
    return result


def collect_field_values(files: list[Path]) -> dict:
    """모든 파일에서 필드별 값 수집"""
    field_values = defaultdict(list)

    for file_path in files:
        data = load_json(file_path)
        if not data:
            continue

        source = "table-GG" if "table-GG" in str(file_path) else "table-pokercaster"

        # Root 필드
        root_fields = extract_root_fields(data)
        for field, value in root_fields.items():
            field_values[f"root.{field}"].append({
                "value": value,
                "source": source,
                "file": file_path.name
            })

        # Hands
        for hand_idx, hand in enumerate(data.get("Hands", [])):
            hand_fields = extract_hand_fields(hand)
            for field, value in hand_fields.items():
                field_values[f"hands.{field}"].append({
                    "value": value,
                    "source": source,
                    "hand_num": hand.get("HandNum", hand_idx + 1)
                })

            # Players
            for player in hand.get("Players", []):
                player_fields = extract_player_fields(player)
                for field, value in player_fields.items():
                    field_values[f"players.{field}"].append({
                        "value": value,
                        "source": source,
                        "player_num": player.get("PlayerNum")
                    })

            # Events
            for event_idx, event in enumerate(hand.get("Events", [])):
                event_fields = extract_event_fields(event)
                for field, value in event_fields.items():
                    field_values[f"events.{field}"].append({
                        "value": value,
                        "source": source,
                        "event_idx": event_idx
                    })

    return dict(field_values)


def calculate_statistics(field_values: dict) -> dict:
    """필드별 통계 계산"""
    stats = {}

    for field_path, values in field_values.items():
        raw_values = [v["value"] for v in values]
        total = len(raw_values)

        # null/빈값 비율
        null_count = sum(1 for v in raw_values if v is None or v == "" or v == [])
        null_ratio = null_count / total if total > 0 else 0

        # 타입 분석
        types = set()
        for v in raw_values:
            if v is None:
                types.add("null")
            elif isinstance(v, bool):
                types.add("boolean")
            elif isinstance(v, int):
                types.add("integer")
            elif isinstance(v, float):
                types.add("float")
            elif isinstance(v, str):
                types.add("string")
            elif isinstance(v, list):
                types.add("array")
            elif isinstance(v, dict):
                types.add("object")

        # 고유값 (최대 10개)
        unique_values = []
        seen = set()
        for v in raw_values:
            if v is None or v == "" or v == []:
                continue
            v_key = str(v) if isinstance(v, (list, dict)) else v
            if v_key not in seen:
                seen.add(v_key)
                unique_values.append(v)
                if len(unique_values) >= 10:
                    break

        # 수치형 통계
        numeric_stats = None
        numeric_values = [v for v in raw_values if isinstance(v, (int, float)) and v is not None]
        if numeric_values:
            numeric_stats = {
                "min": min(numeric_values),
                "max": max(numeric_values),
                "avg": sum(numeric_values) / len(numeric_values),
                "count": len(numeric_values)
            }

        stats[field_path] = {
            "total_occurrences": total,
            "null_ratio": round(null_ratio, 4),
            "types": list(types),
            "unique_values": unique_values,
            "numeric_stats": numeric_stats
        }

    return stats


def extract_specific_field(files: list[Path], field_path: str) -> list:
    """특정 필드만 추출"""
    results = []

    for file_path in files:
        data = load_json(file_path)
        if not data:
            continue

        source = "table-GG" if "table-GG" in str(file_path) else "table-pokercaster"

        # 경로 파싱
        parts = field_path.split(".")
        level = parts[0].replace("[*]", "")
        field = parts[-1] if len(parts) > 1 else parts[0]

        if level == "root" or not "[*]" in field_path:
            # Root 레벨
            value = extract_value(data, field_path.replace("root.", ""))
            results.append({
                "file": file_path.name,
                "source": source,
                "value": value
            })
        elif "Hands" in field_path:
            for hand_idx, hand in enumerate(data.get("Hands", [])):
                if "Players" in field_path:
                    for player in hand.get("Players", []):
                        value = player.get(field)
                        results.append({
                            "file": file_path.name,
                            "source": source,
                            "hand_num": hand.get("HandNum"),
                            "player_num": player.get("PlayerNum"),
                            "value": value
                        })
                elif "Events" in field_path:
                    for event_idx, event in enumerate(hand.get("Events", [])):
                        value = event.get(field)
                        results.append({
                            "file": file_path.name,
                            "source": source,
                            "hand_num": hand.get("HandNum"),
                            "event_idx": event_idx,
                            "value": value
                        })
                else:
                    # FlopDrawBlinds, StudLimits 또는 Hand 직접 필드
                    if "FlopDrawBlinds" in field_path:
                        value = extract_value(hand, f"FlopDrawBlinds.{field}")
                    elif "StudLimits" in field_path:
                        value = extract_value(hand, f"StudLimits.{field}")
                    else:
                        value = hand.get(field)
                    results.append({
                        "file": file_path.name,
                        "source": source,
                        "hand_num": hand.get("HandNum"),
                        "value": value
                    })

    return results


def print_stats_summary(stats: dict) -> None:
    """통계 요약 출력"""
    print("\n" + "=" * 80)
    print("GFX JSON 필드 통계 요약")
    print("=" * 80)

    # 레벨별 그룹화
    levels = {"root": [], "hands": [], "blinds": [], "stud": [], "players": [], "events": []}

    for field_path, stat in stats.items():
        level = field_path.split(".")[0]
        if "FlopDrawBlinds" in field_path:
            levels["blinds"].append((field_path, stat))
        elif "StudLimits" in field_path:
            levels["stud"].append((field_path, stat))
        elif level in levels:
            levels[level].append((field_path, stat))

    for level_name, fields in levels.items():
        if not fields:
            continue

        print(f"\n### {level_name.upper()} ###")
        print("-" * 80)
        print(f"{'필드':<45} {'총 수':<10} {'null%':<10} {'타입':<15}")
        print("-" * 80)

        for field_path, stat in sorted(fields):
            short_name = field_path.split(".")[-1]
            types = ", ".join(stat["types"])
            null_pct = f"{stat['null_ratio']*100:.1f}%"
            print(f"{short_name:<45} {stat['total_occurrences']:<10} {null_pct:<10} {types:<15}")

    print("\n" + "=" * 80)


def main():
    parser = argparse.ArgumentParser(description="GFX JSON 필드 추출기")
    parser.add_argument("--input-dir", type=Path, default=DEFAULT_INPUT_DIR,
                        help="입력 디렉토리")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                        help="출력 파일")
    parser.add_argument("--field", type=str,
                        help="특정 필드만 추출 (예: Hands[*].Players[*].Name)")
    parser.add_argument("--stats", action="store_true",
                        help="통계만 출력")
    parser.add_argument("--json", action="store_true",
                        help="JSON 형식으로 출력")

    args = parser.parse_args()

    # 파일 검색
    files = find_json_files(args.input_dir)
    print(f"발견된 JSON 파일: {len(files)}개")

    if args.field:
        # 특정 필드만 추출
        results = extract_specific_field(files, args.field)

        if args.json:
            print(json.dumps(results, indent=2, ensure_ascii=False))
        else:
            print(f"\n필드: {args.field}")
            print(f"총 레코드: {len(results)}")
            print("\n샘플 값 (최대 10개):")
            unique = []
            seen = set()
            for r in results:
                v = str(r["value"])
                if v not in seen:
                    seen.add(v)
                    unique.append(r)
                    if len(unique) >= 10:
                        break
            for r in unique:
                print(f"  - {r['value']}")
    else:
        # 전체 필드 수집 및 통계
        print("필드 값 수집 중...")
        field_values = collect_field_values(files)

        print("통계 계산 중...")
        stats = calculate_statistics(field_values)

        if args.stats:
            print_stats_summary(stats)
        else:
            # 결과 저장
            output_data = {
                "generated_at": datetime.now().isoformat(),
                "files_analyzed": len(files),
                "statistics": stats
            }

            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(output_data, indent=2, ensure_ascii=False, fp=f)

            print(f"\n결과 저장: {args.output}")
            print_stats_summary(stats)


if __name__ == "__main__":
    main()
