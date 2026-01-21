"""GFX JSON to Database Normalizer.

Transforms PokerGFX JSON files into normalized database structures
ready for Supabase insertion.

Usage:
    from src.gfx_normalizer import GFXNormalizer

    normalizer = GFXNormalizer()
    result = normalizer.normalize_file(Path("path/to/file.json"))

    # Access normalized data
    session = result.session
    hands = result.hands
    players_by_hand = result.players  # list[list[NormalizedHandPlayer]]
    events_by_hand = result.events    # list[list[NormalizedEvent]]
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

# =============================================================================
# Data Classes (Normalized structures for DB insertion)
# =============================================================================


@dataclass
class NormalizedSession:
    """Normalized session data for gfx_sessions table."""

    session_id: int  # JSON "ID" field
    file_name: str
    file_hash: str  # SHA256 of file content
    table_type: str  # JSON "Type" field
    event_title: str
    software_version: str
    payouts: list[int]
    hand_count: int
    session_created_at: datetime | None
    raw_json: dict[str, Any]


@dataclass
class NormalizedHand:
    """Normalized hand data for gfx_hands table."""

    session_id: int
    hand_num: int
    game_variant: str
    game_class: str
    bet_structure: str
    duration_seconds: int
    start_time: datetime
    recording_offset_iso: str | None
    recording_offset_seconds: int | None
    num_boards: int
    run_it_num_times: int
    ante_amt: int
    bomb_pot_amt: int
    description: str
    blinds: dict[str, Any]
    stud_limits: dict[str, Any]
    pot_size: int
    player_count: int
    board_cards: list[str]
    winner_name: str | None
    winner_seat: int | None


@dataclass
class NormalizedHandPlayer:
    """Normalized player data for gfx_hand_players table."""

    seat_num: int
    player_name: str
    long_name: str
    player_hash: str  # For gfx_players lookup
    hole_cards: list[str]  # Parsed: ["10d", "9d"]
    has_shown: bool
    start_stack_amt: int
    end_stack_amt: int
    cumulative_winnings_amt: int
    blind_bet_straddle_amt: int
    sitting_out: bool
    elimination_rank: int
    is_winner: bool
    vpip_percent: float
    preflop_raise_percent: float
    aggression_frequency_percent: float
    went_to_showdown_percent: float


@dataclass
class NormalizedEvent:
    """Normalized event data for gfx_events table."""

    event_order: int
    event_type: str  # Mapped: "BOARD_CARD" not "BOARD CARD"
    player_num: int
    bet_amt: int
    pot: int
    board_cards: str | None
    board_num: int
    num_cards_drawn: int
    event_time: datetime | None


@dataclass
class NormalizedPlayer:
    """Normalized player master for gfx_players table."""

    player_hash: str
    name: str
    long_name: str


@dataclass
class NormalizationResult:
    """Complete normalization result for a single JSON file."""

    session: NormalizedSession
    hands: list[NormalizedHand]
    players: list[list[NormalizedHandPlayer]]  # Per-hand players
    events: list[list[NormalizedEvent]]  # Per-hand events
    unique_players: list[NormalizedPlayer]  # Deduplicated player masters


# =============================================================================
# GFX Normalizer Class
# =============================================================================


class GFXNormalizer:
    """Normalize GFX JSON data to database-ready structures.

    Handles all field mappings and transformations:
    - JSON "ID" -> session_id
    - EventType "BOARD CARD" -> "BOARD_CARD"
    - HoleCards ["10d 9d"] -> ["10d", "9d"]
    - Duration "PT35M37.2477537S" -> 2137 (seconds)
    """

    # EventType mapping: JSON value -> DB ENUM value
    EVENT_TYPE_MAP = {
        "FOLD": "FOLD",
        "CHECK": "CHECK",
        "CALL": "CALL",
        "BET": "BET",
        "RAISE": "RAISE",
        "ALL IN": "ALL_IN",
        "ALL_IN": "ALL_IN",
        "BOARD CARD": "BOARD_CARD",
        "BOARD_CARD": "BOARD_CARD",
        "ANTE": "ANTE",
        "BLIND": "BLIND",
        "STRADDLE": "STRADDLE",
        "BRING_IN": "BRING_IN",
        "MUCK": "MUCK",
        "SHOW": "SHOW",
        "WIN": "WIN",
    }

    def normalize_file(self, filepath: Path) -> NormalizationResult:
        """Normalize entire JSON file to DB structures.

        Args:
            filepath: Path to GFX JSON file

        Returns:
            NormalizationResult containing all normalized data
        """
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
            data = json.loads(content)

        file_hash = hashlib.sha256(content.encode()).hexdigest()

        # Normalize session (root level)
        session = self._normalize_session(data, filepath.name, file_hash)

        # Track unique players across all hands
        player_registry: dict[str, NormalizedPlayer] = {}

        hands: list[NormalizedHand] = []
        all_players: list[list[NormalizedHandPlayer]] = []
        all_events: list[list[NormalizedEvent]] = []

        for hand_data in data.get("Hands", []):
            hand = self._normalize_hand(hand_data, session.session_id)
            players = self._normalize_players(hand_data, player_registry)
            events = self._normalize_events(hand_data)

            # Update winner info based on players
            winner = self._find_winner(players)
            if winner:
                hand.winner_name = winner.player_name
                hand.winner_seat = winner.seat_num

            hands.append(hand)
            all_players.append(players)
            all_events.append(events)

        return NormalizationResult(
            session=session,
            hands=hands,
            players=all_players,
            events=all_events,
            unique_players=list(player_registry.values()),
        )

    # -------------------------------------------------------------------------
    # Session Level Normalization
    # -------------------------------------------------------------------------

    def _normalize_session(
        self,
        data: dict[str, Any],
        file_name: str,
        file_hash: str,
    ) -> NormalizedSession:
        """Normalize session-level data.

        Key mapping: JSON "ID" -> session_id
        """
        return NormalizedSession(
            session_id=data.get("ID", 0),  # JSON field is "ID"
            file_name=file_name,
            file_hash=file_hash,
            table_type=data.get("Type", "UNKNOWN"),
            event_title=data.get("EventTitle", ""),
            software_version=data.get("SoftwareVersion", ""),
            payouts=data.get("Payouts", [0] * 10),
            hand_count=len(data.get("Hands", [])),
            session_created_at=self._parse_datetime(data.get("CreatedDateTimeUTC")),
            raw_json=data,
        )

    # -------------------------------------------------------------------------
    # Hand Level Normalization
    # -------------------------------------------------------------------------

    def _normalize_hand(
        self,
        hand_data: dict[str, Any],
        session_id: int,
    ) -> NormalizedHand:
        """Normalize hand-level data."""
        events = hand_data.get("Events", [])
        players = hand_data.get("Players", [])

        # Extract board cards from BOARD CARD events
        board_cards = self._extract_board_cards(events)

        # Get final pot from last event with pot > 0
        pot_size = self._extract_final_pot(events)

        # Parse recording offset
        offset_iso = hand_data.get("RecordingOffsetStart")
        offset_seconds = self._parse_duration(offset_iso) if offset_iso else None

        return NormalizedHand(
            session_id=session_id,
            hand_num=hand_data.get("HandNum", 0),
            game_variant=hand_data.get("GameVariant", "HOLDEM"),
            game_class=hand_data.get("GameClass", "FLOP"),
            bet_structure=hand_data.get("BetStructure", "NOLIMIT"),
            duration_seconds=self._parse_duration(hand_data.get("Duration", "")),
            start_time=self._parse_datetime(hand_data.get("StartDateTimeUTC"))
            or datetime.now(),
            recording_offset_iso=offset_iso,
            recording_offset_seconds=offset_seconds,
            num_boards=hand_data.get("NumBoards", 1),
            run_it_num_times=hand_data.get("RunItNumTimes", 1),
            ante_amt=hand_data.get("AnteAmt", 0),
            bomb_pot_amt=hand_data.get("BombPotAmt", 0),
            description=hand_data.get("Description", ""),
            blinds=self._normalize_blinds(hand_data.get("FlopDrawBlinds", {})),
            stud_limits=hand_data.get("StudLimits", {}),
            pot_size=pot_size,
            player_count=len(players),
            board_cards=board_cards,
            winner_name=None,  # Set later from players
            winner_seat=None,
        )

    def _normalize_blinds(self, blinds_data: dict[str, Any]) -> dict[str, Any]:
        """Normalize FlopDrawBlinds object for JSONB storage."""
        if not blinds_data:
            return {}

        return {
            "ante_type": blinds_data.get("AnteType", "NO_ANTE"),
            "big_blind_amt": blinds_data.get("BigBlindAmt", 0),
            "big_blind_player_num": blinds_data.get("BigBlindPlayerNum", 0),
            "small_blind_amt": blinds_data.get("SmallBlindAmt", 0),
            "small_blind_player_num": blinds_data.get("SmallBlindPlayerNum", 0),
            "button_player_num": blinds_data.get("ButtonPlayerNum", 0),
            "third_blind_amt": blinds_data.get("ThirdBlindAmt", 0),
            "third_blind_player_num": blinds_data.get("ThirdBlindPlayerNum", 0),
            "blind_level": blinds_data.get("BlindLevel", 0),
        }

    # -------------------------------------------------------------------------
    # Player Level Normalization
    # -------------------------------------------------------------------------

    def _normalize_players(
        self,
        hand_data: dict[str, Any],
        player_registry: dict[str, NormalizedPlayer],
    ) -> list[NormalizedHandPlayer]:
        """Normalize all players in a hand."""
        players: list[NormalizedHandPlayer] = []

        for p in hand_data.get("Players", []):
            name = p.get("Name", "")
            long_name = p.get("LongName", "")
            player_hash = self._generate_player_hash(name, long_name)

            # Register unique player
            if player_hash not in player_registry:
                player_registry[player_hash] = NormalizedPlayer(
                    player_hash=player_hash,
                    name=name,
                    long_name=long_name,
                )

            # Parse hole cards: ["10d 9d"] -> ["10d", "9d"]
            hole_cards = self._parse_hole_cards(p.get("HoleCards", []))

            start = p.get("StartStackAmt", 0)
            end = p.get("EndStackAmt", 0)

            players.append(
                NormalizedHandPlayer(
                    seat_num=p.get("PlayerNum", 0),
                    player_name=name,
                    long_name=long_name,
                    player_hash=player_hash,
                    hole_cards=hole_cards,
                    has_shown=len(hole_cards) >= 2,
                    start_stack_amt=start,
                    end_stack_amt=end,
                    cumulative_winnings_amt=p.get("CumulativeWinningsAmt", 0),
                    blind_bet_straddle_amt=p.get("BlindBetStraddleAmt", 0),
                    sitting_out=p.get("SittingOut", False),
                    elimination_rank=p.get("EliminationRank", -1),
                    is_winner=end > start,
                    vpip_percent=p.get("VPIPPercent", 0),
                    preflop_raise_percent=p.get("PreFlopRaisePercent", 0),
                    aggression_frequency_percent=p.get("AggressionFrequencyPercent", 0),
                    went_to_showdown_percent=p.get("WentToShowDownPercent", 0),
                )
            )

        return players

    def _find_winner(
        self,
        players: list[NormalizedHandPlayer],
    ) -> NormalizedHandPlayer | None:
        """Find the player with highest winnings."""
        winners = [p for p in players if p.is_winner]
        if not winners:
            return None

        return max(winners, key=lambda p: p.cumulative_winnings_amt)

    # -------------------------------------------------------------------------
    # Event Level Normalization
    # -------------------------------------------------------------------------

    def _normalize_events(
        self,
        hand_data: dict[str, Any],
    ) -> list[NormalizedEvent]:
        """Normalize all events in a hand."""
        events: list[NormalizedEvent] = []

        for i, e in enumerate(hand_data.get("Events", [])):
            raw_type = e.get("EventType", "")
            # Map event type: "BOARD CARD" -> "BOARD_CARD"
            event_type = self.EVENT_TYPE_MAP.get(raw_type, raw_type)

            events.append(
                NormalizedEvent(
                    event_order=i,
                    event_type=event_type,
                    player_num=e.get("PlayerNum", 0),
                    bet_amt=e.get("BetAmt", 0),
                    pot=e.get("Pot", 0),
                    board_cards=e.get("BoardCards"),
                    board_num=e.get("BoardNum", 0),
                    num_cards_drawn=e.get("NumCardsDrawn", 0),
                    event_time=self._parse_datetime(e.get("DateTimeUTC")),
                )
            )

        return events

    # -------------------------------------------------------------------------
    # Helper Methods
    # -------------------------------------------------------------------------

    def _parse_datetime(self, dt_str: str | None) -> datetime | None:
        """Parse ISO 8601 datetime string."""
        if not dt_str:
            return None

        try:
            # Handle microseconds with varying precision
            # "2025-10-15T10:54:43.1992165Z" -> remove trailing Z, parse
            dt_str = dt_str.rstrip("Z")
            if "." in dt_str:
                main, frac = dt_str.split(".")
                # Truncate to 6 digits (microseconds)
                frac = frac[:6].ljust(6, "0")
                dt_str = f"{main}.{frac}"
            return datetime.fromisoformat(dt_str)
        except (ValueError, TypeError):
            return None

    def _parse_duration(self, duration: str | None) -> int:
        """Parse ISO 8601 Duration to seconds.

        Examples:
            "PT35M37.2477537S" -> 2137
            "PT19.5488032S" -> 19
            "P739538DT16H3M20.9005907S" -> very large number (recording offset)
        """
        if not duration:
            return 0

        total_seconds = 0.0

        # Days (D)
        if match := re.search(r"(\d+(?:\.\d+)?)D", duration, re.IGNORECASE):
            total_seconds += float(match.group(1)) * 86400

        # Hours (H)
        if match := re.search(r"(\d+(?:\.\d+)?)H", duration, re.IGNORECASE):
            total_seconds += float(match.group(1)) * 3600

        # Minutes (M) - only after T
        if match := re.search(r"T.*?(\d+(?:\.\d+)?)M", duration, re.IGNORECASE):
            total_seconds += float(match.group(1)) * 60

        # Seconds (S)
        if match := re.search(r"(\d+(?:\.\d+)?)S", duration, re.IGNORECASE):
            total_seconds += float(match.group(1))

        return int(total_seconds)

    def _parse_hole_cards(self, cards: list[str]) -> list[str]:
        """Parse hole cards from JSON format.

        JSON: ["10d 9d"] (space-separated single string)
        DB:   ["10d", "9d"] (array of individual cards)
        """
        if not cards or not cards[0] or cards[0] == "":
            return []

        # Split by whitespace
        return cards[0].split()

    def _generate_player_hash(self, name: str, long_name: str) -> str:
        """Generate unique player hash.

        Hash = MD5(lowercase(name):lowercase(long_name))
        """
        key = f"{name.lower().strip()}:{long_name.lower().strip()}"
        return hashlib.md5(key.encode()).hexdigest()

    def _extract_board_cards(self, events: list[dict[str, Any]]) -> list[str]:
        """Extract board cards from BOARD_CARD events."""
        cards = []
        for e in events:
            if e.get("EventType") in ("BOARD CARD", "BOARD_CARD"):
                card = e.get("BoardCards")
                if card:
                    cards.append(card)
        return cards

    def _extract_final_pot(self, events: list[dict[str, Any]]) -> int:
        """Extract final pot size from events."""
        pot = 0
        for e in events:
            if e.get("Pot", 0) > 0:
                pot = e["Pot"]
        return pot


# =============================================================================
# Convenience Functions
# =============================================================================


def normalize_gfx_file(filepath: Path | str) -> NormalizationResult:
    """Convenience function to normalize a single file.

    Args:
        filepath: Path to GFX JSON file

    Returns:
        NormalizationResult with all normalized data
    """
    normalizer = GFXNormalizer()
    return normalizer.normalize_file(Path(filepath))


def normalize_gfx_directory(
    dirpath: Path | str,
    pattern: str = "*.json",
) -> list[NormalizationResult]:
    """Normalize all JSON files in a directory.

    Args:
        dirpath: Directory containing GFX JSON files
        pattern: Glob pattern for JSON files

    Returns:
        List of NormalizationResult for each file
    """
    normalizer = GFXNormalizer()
    results = []

    for filepath in Path(dirpath).rglob(pattern):
        try:
            result = normalizer.normalize_file(filepath)
            results.append(result)
        except (json.JSONDecodeError, KeyError) as e:
            print(f"Error processing {filepath}: {e}")

    return results


# =============================================================================
# Main (for testing)
# =============================================================================

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        test_file = Path(sys.argv[1])
    else:
        test_file = Path(
            r"c:\claude\automation_feature_table\gfx_json\table-GG\1015"
            r"\PGFX_live_data_export GameID=638961224831992165.json"
        )

    print(f"Testing with: {test_file}")

    result = normalize_gfx_file(test_file)

    print(f"\nSession ID: {result.session.session_id}")
    print(f"File: {result.session.file_name}")
    print(f"Table Type: {result.session.table_type}")
    print(f"Hands: {len(result.hands)}")
    print(f"Unique Players: {len(result.unique_players)}")

    if result.hands:
        h = result.hands[0]
        print("\nFirst Hand:")
        print(f"  Hand #{h.hand_num}")
        print(f"  Duration: {h.duration_seconds}s")
        print(f"  Pot: {h.pot_size}")
        print(f"  Players: {h.player_count}")
        print(f"  Board: {h.board_cards}")

    if result.players and result.players[0]:
        p = result.players[0][0]
        print("\nFirst Player in First Hand:")
        print(f"  Name: {p.player_name}")
        print(f"  Seat: {p.seat_num}")
        print(f"  Hole Cards: {p.hole_cards}")
        print(f"  Start Stack: {p.start_stack_amt}")
        print(f"  End Stack: {p.end_stack_amt}")

    if result.events and result.events[0]:
        print("\nFirst 5 Events in First Hand:")
        for e in result.events[0][:5]:
            print(
                f"  [{e.event_order}] {e.event_type} P{e.player_num} Bet:{e.bet_amt} Pot:{e.pot}"
            )
