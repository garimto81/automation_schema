#!/usr/bin/env python
"""GFX JSON Schema Validation Script.

Validates all GFX JSON files against the database schema definitions.
Detects missing fields, type mismatches, and ENUM value issues.

Usage:
    python scripts/validate_gfx_schema.py [--json-dir PATH]
"""

from __future__ import annotations

import json
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

# =============================================================================
# DB Schema Definitions (Expected structure)
# =============================================================================

# ENUM values from database schema
DB_ENUMS = {
    "table_type": {
        "FEATURE_TABLE",
        "MAIN_TABLE",
        "FINAL_TABLE",
        "SIDE_TABLE",
        "UNKNOWN",
    },
    "game_variant": {
        "HOLDEM",
        "OMAHA",
        "OMAHA_HILO",
        "STUD",
        "STUD_HILO",
        "RAZZ",
        "DRAW",
        "MIXED",
    },
    "game_class": {"FLOP", "STUD", "DRAW", "MIXED"},
    "bet_structure": {"NOLIMIT", "POTLIMIT", "LIMIT", "SPREAD_LIMIT"},
    "event_type": {
        "FOLD",
        "CHECK",
        "CALL",
        "BET",
        "RAISE",
        "ALL_IN",
        "BOARD_CARD",
        "ANTE",
        "BLIND",
        "STRADDLE",
        "BRING_IN",
        "MUCK",
        "SHOW",
        "WIN",
    },
    "ante_type": {
        "NO_ANTE",
        "BB_ANTE_BB1ST",
        "BB_ANTE_BTN1ST",
        "ALL_ANTE",
        "DEAD_ANTE",
    },
}

# Expected JSON fields at each level
EXPECTED_SESSION_FIELDS = {
    "ID",
    "CreatedDateTimeUTC",
    "EventTitle",
    "SoftwareVersion",
    "Type",
    "Payouts",
    "Hands",
}

EXPECTED_HAND_FIELDS = {
    "HandNum",
    "Duration",
    "StartDateTimeUTC",
    "RecordingOffsetStart",
    "GameVariant",
    "GameClass",
    "BetStructure",
    "AnteAmt",
    "BombPotAmt",
    "NumBoards",
    "RunItNumTimes",
    "Description",
    "FlopDrawBlinds",
    "StudLimits",
    "Events",
    "Players",
}

EXPECTED_PLAYER_FIELDS = {
    "PlayerNum",
    "Name",
    "LongName",
    "HoleCards",
    "StartStackAmt",
    "EndStackAmt",
    "CumulativeWinningsAmt",
    "BlindBetStraddleAmt",
    "SittingOut",
    "EliminationRank",
    "VPIPPercent",
    "PreFlopRaisePercent",
    "AggressionFrequencyPercent",
    "WentToShowDownPercent",
}

EXPECTED_EVENT_FIELDS = {
    "EventType",
    "PlayerNum",
    "BetAmt",
    "Pot",
    "BoardCards",
    "BoardNum",
    "NumCardsDrawn",
    "DateTimeUTC",
}

EXPECTED_BLINDS_FIELDS = {
    "AnteType",
    "BigBlindAmt",
    "BigBlindPlayerNum",
    "SmallBlindAmt",
    "SmallBlindPlayerNum",
    "ButtonPlayerNum",
    "ThirdBlindAmt",
    "ThirdBlindPlayerNum",
    "BlindLevel",
}

# EventType mapping (JSON → DB)
EVENT_TYPE_MAP = {
    "FOLD": "FOLD",
    "CHECK": "CHECK",
    "CALL": "CALL",
    "BET": "BET",
    "RAISE": "RAISE",
    "ALL IN": "ALL_IN",
    "BOARD CARD": "BOARD_CARD",
}


# =============================================================================
# Validation Report
# =============================================================================


@dataclass
class ValidationReport:
    """Aggregated validation results."""

    files_analyzed: int = 0
    total_hands: int = 0
    total_players: int = 0
    total_events: int = 0

    # Field tracking
    session_fields_found: set[str] = field(default_factory=set)
    hand_fields_found: set[str] = field(default_factory=set)
    player_fields_found: set[str] = field(default_factory=set)
    event_fields_found: set[str] = field(default_factory=set)
    blinds_fields_found: set[str] = field(default_factory=set)

    # Value tracking
    event_types_found: set[str] = field(default_factory=set)
    game_variants_found: set[str] = field(default_factory=set)
    game_classes_found: set[str] = field(default_factory=set)
    bet_structures_found: set[str] = field(default_factory=set)
    table_types_found: set[str] = field(default_factory=set)
    ante_types_found: set[str] = field(default_factory=set)

    # Issues
    missing_in_db: dict[str, set[str]] = field(default_factory=lambda: defaultdict(set))
    enum_mismatches: dict[str, set[str]] = field(
        default_factory=lambda: defaultdict(set)
    )
    type_issues: list[str] = field(default_factory=list)
    special_cases: list[str] = field(default_factory=list)

    def print_report(self) -> None:
        """Print formatted validation report."""
        print("\n" + "=" * 70)
        print("GFX JSON Schema Validation Report")
        print("=" * 70)

        print(f"\nFiles Analyzed: {self.files_analyzed}")
        print(f"Total Hands: {self.total_hands}")
        print(f"Total Players: {self.total_players}")
        print(f"Total Events: {self.total_events}")

        # Session Level
        print("\n" + "-" * 40)
        print("[Session Level]")
        missing = self.session_fields_found - EXPECTED_SESSION_FIELDS
        extra = EXPECTED_SESSION_FIELDS - self.session_fields_found
        if missing:
            print(f"  Extra fields in JSON (not in schema): {missing}")
        if extra:
            print(f"  Missing in JSON (expected by schema): {extra}")
        if not missing and not extra:
            print("  All fields match schema definition")

        # Hand Level
        print("\n[Hand Level]")
        missing = self.hand_fields_found - EXPECTED_HAND_FIELDS
        extra = EXPECTED_HAND_FIELDS - self.hand_fields_found
        if missing:
            print(f"  Extra fields in JSON: {missing}")
        if extra:
            print(f"  Missing in JSON: {extra}")
        if not missing and not extra:
            print("  All fields match schema definition")

        # Player Level
        print("\n[Player Level]")
        missing = self.player_fields_found - EXPECTED_PLAYER_FIELDS
        extra = EXPECTED_PLAYER_FIELDS - self.player_fields_found
        if missing:
            print(f"  Extra fields in JSON: {missing}")
        if extra:
            print(f"  Missing in JSON: {extra}")
        if not missing and not extra:
            print("  All fields match schema definition")

        # Event Level
        print("\n[Event Level]")
        missing = self.event_fields_found - EXPECTED_EVENT_FIELDS
        extra = EXPECTED_EVENT_FIELDS - self.event_fields_found
        if missing:
            print(f"  Extra fields in JSON: {missing}")
        if extra:
            print(f"  Missing in JSON: {extra}")
        if not missing and not extra:
            print("  All fields match schema definition")

        # ENUM Validation
        print("\n" + "-" * 40)
        print("[ENUM Validation]")

        print(f"\n  EventType values found: {sorted(self.event_types_found)}")
        event_needs_mapping = self.event_types_found - DB_ENUMS["event_type"]
        if event_needs_mapping:
            print(f"    ** Needs mapping: {event_needs_mapping}")
            for val in event_needs_mapping:
                mapped = EVENT_TYPE_MAP.get(val, "UNKNOWN")
                print(f"       '{val}' -> '{mapped}'")
        else:
            print("    All values in DB ENUM")

        print(f"\n  GameVariant values found: {sorted(self.game_variants_found)}")
        variant_missing = self.game_variants_found - DB_ENUMS["game_variant"]
        if variant_missing:
            print(f"    ** Missing in DB ENUM: {variant_missing}")
        else:
            print("    All values in DB ENUM")

        print(f"\n  GameClass values found: {sorted(self.game_classes_found)}")
        class_missing = self.game_classes_found - DB_ENUMS["game_class"]
        if class_missing:
            print(f"    ** Missing in DB ENUM: {class_missing}")
        else:
            print("    All values in DB ENUM")

        print(f"\n  BetStructure values found: {sorted(self.bet_structures_found)}")
        bet_missing = self.bet_structures_found - DB_ENUMS["bet_structure"]
        if bet_missing:
            print(f"    ** Missing in DB ENUM: {bet_missing}")
        else:
            print("    All values in DB ENUM")

        print(f"\n  TableType values found: {sorted(self.table_types_found)}")
        table_missing = self.table_types_found - DB_ENUMS["table_type"]
        if table_missing:
            print(f"    ** Missing in DB ENUM: {table_missing}")
        else:
            print("    All values in DB ENUM")

        print(f"\n  AnteType values found: {sorted(self.ante_types_found)}")
        ante_missing = self.ante_types_found - DB_ENUMS["ante_type"]
        if ante_missing:
            print(f"    ** Missing in DB ENUM: {ante_missing}")
        else:
            print("    All values in DB ENUM")

        # Special Cases
        print("\n" + "-" * 40)
        print("[Special Cases & Warnings]")
        if self.special_cases:
            for case in self.special_cases:
                print(f"  ! {case}")
        else:
            print("  No special cases detected")

        # Type Issues
        if self.type_issues:
            print("\n[Type Issues]")
            for issue in self.type_issues[:10]:  # Limit output
                print(f"  - {issue}")
            if len(self.type_issues) > 10:
                print(f"  ... and {len(self.type_issues) - 10} more")

        print("\n" + "=" * 70)
        print("Validation Complete")
        print("=" * 70)


# =============================================================================
# Validation Functions
# =============================================================================


def validate_file(filepath: Path, report: ValidationReport) -> None:
    """Validate a single JSON file."""
    try:
        with open(filepath, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        report.type_issues.append(f"JSON parse error in {filepath.name}: {e}")
        return

    report.files_analyzed += 1

    # Session level
    report.session_fields_found.update(data.keys())

    # Check session ID
    if "ID" in data:
        session_id = data["ID"]
        if not isinstance(session_id, int):
            report.type_issues.append(
                f"{filepath.name}: ID is not int64 ({type(session_id).__name__})"
            )

    # Table type
    if "Type" in data:
        report.table_types_found.add(data["Type"])

    # Process hands
    for hand in data.get("Hands", []):
        report.total_hands += 1
        report.hand_fields_found.update(hand.keys())

        # ENUM values
        if "GameVariant" in hand:
            report.game_variants_found.add(hand["GameVariant"])
        if "GameClass" in hand:
            report.game_classes_found.add(hand["GameClass"])
        if "BetStructure" in hand:
            report.bet_structures_found.add(hand["BetStructure"])

        # Blinds
        blinds = hand.get("FlopDrawBlinds", {})
        report.blinds_fields_found.update(blinds.keys())
        if "AnteType" in blinds:
            report.ante_types_found.add(blinds["AnteType"])

        # Players
        for player in hand.get("Players", []):
            report.total_players += 1
            report.player_fields_found.update(player.keys())

            # Check HoleCards format
            hole_cards = player.get("HoleCards", [])
            if hole_cards and hole_cards[0] and " " in hole_cards[0]:
                if (
                    "HoleCards space-separated format detected"
                    not in report.special_cases
                ):
                    report.special_cases.append(
                        f"HoleCards space-separated format detected: {hole_cards[0]!r} "
                        "(needs split parsing)"
                    )

        # Events
        for event in hand.get("Events", []):
            report.total_events += 1
            report.event_fields_found.update(event.keys())

            event_type = event.get("EventType", "")
            report.event_types_found.add(event_type)

            # Check for space in event type
            if " " in event_type:
                if f"EventType with space: '{event_type}'" not in report.special_cases:
                    report.special_cases.append(
                        f"EventType with space: '{event_type}' -> needs mapping to "
                        f"'{EVENT_TYPE_MAP.get(event_type, 'UNKNOWN')}'"
                    )


def find_json_files(json_dir: Path) -> list[Path]:
    """Find all GFX JSON files recursively."""
    return list(json_dir.rglob("*.json"))


def main(json_dir: Path | None = None) -> ValidationReport:
    """Run validation on all JSON files."""
    if json_dir is None:
        # Default path
        json_dir = Path(r"c:\claude\automation_feature_table\gfx_json")

    if not json_dir.exists():
        print(f"Error: Directory not found: {json_dir}")
        return ValidationReport()

    json_files = find_json_files(json_dir)
    print(f"Found {len(json_files)} JSON files in {json_dir}")

    report = ValidationReport()

    for filepath in json_files:
        print(f"  Validating: {filepath.name}")
        validate_file(filepath, report)

    report.print_report()
    return report


if __name__ == "__main__":
    import sys

    json_dir = None
    if len(sys.argv) > 1:
        if sys.argv[1] == "--json-dir" and len(sys.argv) > 2:
            json_dir = Path(sys.argv[2])
        else:
            json_dir = Path(sys.argv[1])

    main(json_dir)
