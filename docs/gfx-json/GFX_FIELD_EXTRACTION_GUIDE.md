# GFX 필드 추출 가이드

**버전**: 1.0.0
**최종 수정**: 2026-01-19

이 문서는 GFX JSON 데이터에서 각 필드를 추출하는 방법과 현장 데이터 요소를 설명합니다.

---

## 1. 추출 스크립트 사용법

### 1.1 기본 실행

```powershell
# 전체 통계 출력
python C:\claude\automation_schema\scripts\gfx_field_extractor.py --stats

# 결과 JSON 파일로 저장
python C:\claude\automation_schema\scripts\gfx_field_extractor.py --output result.json

# 특정 필드만 추출
python C:\claude\automation_schema\scripts\gfx_field_extractor.py --field "Hands[*].Players[*].Name"
```

### 1.2 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--input-dir` | JSON 파일 디렉토리 | `gfx_json_data/` |
| `--output` | 출력 파일 경로 | `gfx_extracted_fields.json` |
| `--field` | 특정 필드만 추출 | - |
| `--stats` | 통계만 출력 | - |
| `--json` | JSON 형식 출력 | - |

---

## 2. 필드별 추출 로직

### 2.1 Root Level 필드

```python
def extract_root_fields(data: dict) -> dict:
    return {
        "ID": data.get("ID"),                           # bigint
        "CreatedDateTimeUTC": data.get("CreatedDateTimeUTC"),  # ISO 8601
        "SoftwareVersion": data.get("SoftwareVersion"), # string
        "Type": data.get("Type"),                       # FEATURE_TABLE | FINAL_TABLE
        "Payouts": data.get("Payouts"),                 # array[int]
    }
```

**현장 데이터 요소**:
- `ID`: GFX 소프트웨어가 .NET DateTime.Ticks 기반으로 자동 생성
- `Type`: 방송 제작자가 설정 (피처 테이블 vs 파이널 테이블)

---

### 2.2 Hand Level 필드

```python
def extract_hand_fields(hand: dict) -> dict:
    return {
        # 기본 정보
        "HandNum": hand.get("HandNum"),                 # 세션 내 순번
        "StartDateTimeUTC": hand.get("StartDateTimeUTC"),
        "Duration": hand.get("Duration"),              # ISO 8601 Duration

        # 베팅 구조
        "AnteAmt": hand.get("AnteAmt"),                # 앤티 금액
        "BetStructure": hand.get("BetStructure"),      # NOLIMIT
        "GameVariant": hand.get("GameVariant"),        # HOLDEM

        # 블라인드
        "BigBlindAmt": hand.get("FlopDrawBlinds", {}).get("BigBlindAmt"),
        "SmallBlindAmt": hand.get("FlopDrawBlinds", {}).get("SmallBlindAmt"),
        "ButtonPlayerNum": hand.get("FlopDrawBlinds", {}).get("ButtonPlayerNum"),
    }
```

**현장 데이터 요소**:
- `BlindLevel`: 블라인드 레벨은 GFX에서 0으로 고정, 실제 레벨은 WSOP+ 데이터에서 가져옴
- `AnteAmt`: BB Ante 방식 (AnteAmt = BigBlindAmt)
- `Duration`: 핸드 종료 시 자동 계산

---

### 2.3 Player Level 필드

```python
def extract_player_fields(player: dict) -> dict:
    return {
        # 식별
        "PlayerNum": player.get("PlayerNum"),          # 좌석 번호 (1-9 또는 2-9)
        "Name": player.get("Name"),                    # 표시 이름
        "LongName": player.get("LongName"),            # 전체 이름

        # 칩 스택
        "StartStackAmt": player.get("StartStackAmt"),  # 핸드 시작 시 스택
        "EndStackAmt": player.get("EndStackAmt"),      # 핸드 종료 시 스택
        "CumulativeWinningsAmt": player.get("CumulativeWinningsAmt"),

        # 카드
        "HoleCards": player.get("HoleCards", []),      # ["ah kd"] 또는 [""]

        # 상태
        "SittingOut": player.get("SittingOut"),        # 자리 비움
        "EliminationRank": player.get("EliminationRank"),  # 탈락 순위 (-1: 생존)

        # 통계
        "VPIPPercent": player.get("VPIPPercent"),      # VPIP (%)
        "PreFlopRaisePercent": player.get("PreFlopRaisePercent"),  # PFR (%)
        "AggressionFrequencyPercent": player.get("AggressionFrequencyPercent"),  # AF
        "WentToShowDownPercent": player.get("WentToShowDownPercent"),  # WTSD
    }
```

**현장 데이터 요소**:
- `Name`: GFX 운영자가 수동 입력
- `LongName`: WSOP+ 데이터에서 병합 가능
- `HoleCards`: RFID/카드 인식 시스템 또는 수동 입력
- `StartStackAmt/EndStackAmt`: 칩 카운트 시스템 또는 자동 추적

---

### 2.4 Event Level 필드

```python
def extract_event_fields(event: dict) -> dict:
    return {
        "EventType": event.get("EventType"),           # 액션 타입
        "PlayerNum": event.get("PlayerNum"),           # 플레이어 (0: 보드카드)
        "BetAmt": event.get("BetAmt"),                 # 베팅 금액
        "Pot": event.get("Pot"),                       # 현재 팟
        "BoardCards": event.get("BoardCards"),         # 보드 카드 (BoardCard 이벤트만)
    }
```

**현장 데이터 요소**:
- `EventType`: GFX 소프트웨어가 버튼 클릭 또는 자동 감지로 기록
- `BetAmt`: 베팅 금액 입력 (수동 또는 칩 감지)
- `BoardCards`: 카드 인식 또는 수동 입력

---

## 3. 현장 데이터 수집 요소

### 3.1 사전 설정 (Pre-Session)

| 요소 | 필드 | 입력 방식 | 비고 |
|------|------|----------|------|
| 테이블 타입 | `Type` | 드롭다운 선택 | FEATURE_TABLE / FINAL_TABLE |
| 블라인드 구조 | `BigBlindAmt`, `SmallBlindAmt` | 숫자 입력 | 토너먼트 구조표 참조 |
| 앤티 타입 | `AnteType` | 고정값 | BB_ANTE_BB1ST |
| 플레이어 이름 | `Name` | 수동 입력 | 좌석별 입력 |

### 3.2 실시간 트래킹 (During Hand)

| 요소 | 필드 | 트래킹 방식 | 갱신 주기 |
|------|------|------------|----------|
| 칩 스택 | `StartStackAmt`, `EndStackAmt` | 자동/수동 | 핸드 시작/종료 |
| 딜러 버튼 | `ButtonPlayerNum` | 수동 선택 | 핸드 시작 |
| 홀 카드 | `HoleCards` | RFID/수동 | 카드 배분 시 |
| 액션 | `EventType`, `BetAmt` | 버튼 클릭 | 실시간 |
| 보드 카드 | `BoardCards` | RFID/수동 | 플랍/턴/리버 |
| 팟 크기 | `Pot` | 자동 계산 | 액션 후 |

### 3.3 통계 계산 (Automatic)

| 통계 | 계산 공식 | 갱신 주기 |
|------|----------|----------|
| VPIP | `자발적 참여 핸드 / 전체 핸드 × 100` | 핸드 종료 |
| PFR | `프리플랍 레이즈 핸드 / 전체 핸드 × 100` | 핸드 종료 |
| AF | `(베팅 + 레이즈) / 콜 × 100` | 핸드 종료 |
| WTSD | `쇼다운 도달 / 플랍 본 핸드 × 100` | 핸드 종료 |

---

## 4. 데이터 흐름

```
┌─────────────────────────────────────────────────────────────┐
│                      GFX 소프트웨어                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Pre-Session Setup                                   │   │
│  │  • 테이블 타입 선택                                  │   │
│  │  • 블라인드/앤티 설정                                │   │
│  │  • 플레이어 이름 입력                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Real-time Tracking                                  │   │
│  │  • 칩 스택 갱신                                      │   │
│  │  • 버튼 위치 이동                                    │   │
│  │  • 카드 입력 (홀/보드)                               │   │
│  │  • 액션 기록 (FOLD/BET/CALL/CHECK/ALL IN)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Auto Calculation                                    │   │
│  │  • 팟 크기 계산                                      │   │
│  │  • 통계 갱신 (VPIP, PFR, AF, WTSD)                  │   │
│  │  • Duration 계산                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Export                                              │   │
│  │  • PGFX_live_data_export GameID=XXXXXX.json         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         NAS 저장                            │
│  \\nas\broadcast\gfx_json\{source}\{date}\*.json           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase 통합                            │
│  • gfx_normalizer.py 실행                                   │
│  • gfx_sessions, gfx_hands, gfx_players, gfx_events 저장   │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 필드 추출 예시

### 5.1 특정 핸드의 모든 플레이어 스택

```python
# 스크립트 사용
python scripts/gfx_field_extractor.py --field "Hands[*].Players[*].StartStackAmt" --json

# 직접 파이썬 코드
import json
from pathlib import Path

file = Path("gfx_json_data/table-GG/1015/PGFX_live_data_export GameID=638961224831992165.json")
data = json.loads(file.read_text(encoding="utf-8"))

for hand in data["Hands"]:
    print(f"Hand #{hand['HandNum']}")
    for player in hand["Players"]:
        print(f"  {player['Name']}: {player['StartStackAmt']:,}")
```

### 5.2 특정 이벤트 타입 필터링

```python
# ALL IN 이벤트만 추출
events = []
for hand in data["Hands"]:
    for event in hand.get("Events", []):
        if event["EventType"] == "ALL IN":
            events.append({
                "hand_num": hand["HandNum"],
                "player_num": event["PlayerNum"],
                "bet_amt": event["BetAmt"],
                "pot": event["Pot"]
            })
```

### 5.3 홀 카드 파싱

```python
def parse_hole_cards(hole_cards_str: str) -> list[tuple[str, str]]:
    """
    홀 카드 문자열 파싱
    "ah kd" → [("a", "h"), ("k", "d")]
    """
    if not hole_cards_str:
        return []

    cards = []
    for card in hole_cards_str.split():
        if len(card) == 2:
            rank, suit = card[0], card[1]
        elif len(card) == 3:  # "10h"
            rank, suit = card[:2], card[2]
        else:
            continue
        cards.append((rank, suit))
    return cards

# 사용
hole_cards = player["HoleCards"][0]  # "ah kd"
parsed = parse_hole_cards(hole_cards)  # [("a", "h"), ("k", "d")]
```

### 5.4 Duration 파싱

```python
import re

def parse_duration(duration_str: str) -> float:
    """
    ISO 8601 Duration을 초 단위로 변환
    "PT3M26.9826834S" → 206.98
    """
    if not duration_str:
        return 0.0

    pattern = r"PT(?:(\d+)H)?(?:(\d+)M)?(?:([\d.]+)S)?"
    match = re.match(pattern, duration_str)
    if not match:
        return 0.0

    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = float(match.group(3) or 0)

    return hours * 3600 + minutes * 60 + seconds

# 사용
duration = parse_duration("PT3M26.9826834S")  # 206.98
```

---

## 6. DB 스키마 매핑

### 6.1 gfx_sessions

| JSON 필드 | DB 컬럼 | 타입 | 변환 |
|-----------|---------|------|------|
| `ID` | `game_id` | bigint | 그대로 |
| `CreatedDateTimeUTC` | `created_at` | timestamptz | ISO 8601 파싱 |
| `SoftwareVersion` | `software_version` | text | 그대로 |
| `Type` | `table_type` | text | 그대로 |

### 6.2 gfx_hands

| JSON 필드 | DB 컬럼 | 타입 | 변환 |
|-----------|---------|------|------|
| `HandNum` | `hand_number` | integer | 그대로 |
| `StartDateTimeUTC` | `started_at` | timestamptz | ISO 8601 파싱 |
| `Duration` | `duration_seconds` | numeric | Duration 파싱 |
| `AnteAmt` | `ante_amount` | bigint | 그대로 |
| `FlopDrawBlinds.BigBlindAmt` | `big_blind` | bigint | 그대로 |
| `FlopDrawBlinds.SmallBlindAmt` | `small_blind` | bigint | 그대로 |
| `FlopDrawBlinds.ButtonPlayerNum` | `button_position` | integer | 그대로 |

### 6.3 gfx_players

| JSON 필드 | DB 컬럼 | 타입 | 변환 |
|-----------|---------|------|------|
| `PlayerNum` | `seat_number` | integer | 그대로 |
| `Name` | `display_name` | text | 그대로 |
| `LongName` | `full_name` | text | null 처리 |
| `StartStackAmt` | `start_stack` | bigint | 그대로 |
| `EndStackAmt` | `end_stack` | bigint | 그대로 |
| `HoleCards` | `hole_cards` | text[] | 배열 변환 |
| `EliminationRank` | `elimination_rank` | integer | -1 → null |

### 6.4 gfx_events

| JSON 필드 | DB 컬럼 | 타입 | 변환 |
|-----------|---------|------|------|
| `EventType` | `action_type` | text | 그대로 |
| `PlayerNum` | `player_seat` | integer | 그대로 |
| `BetAmt` | `bet_amount` | bigint | 그대로 |
| `Pot` | `pot_size` | bigint | 그대로 |
| `BoardCards` | `board_card` | text | null 유지 |

---

## 부록: 스크립트 출력 예시

```
$ python scripts/gfx_field_extractor.py --stats

발견된 JSON 파일: 28개
필드 값 수집 중...
통계 계산 중...

================================================================================
GFX JSON 필드 통계 요약
================================================================================

### ROOT ###
--------------------------------------------------------------------------------
필드                                          총 수       null%      타입
--------------------------------------------------------------------------------
CreatedDateTimeUTC                            28         0.0%       string
EventTitle                                    28         100.0%     string
ID                                            28         0.0%       integer
Payouts                                       28         0.0%       array
SoftwareVersion                               28         0.0%       string
Type                                          28         0.0%       string

### PLAYERS ###
--------------------------------------------------------------------------------
필드                                          총 수       null%      타입
--------------------------------------------------------------------------------
Name                                          11961      0.0%       string
PlayerNum                                     11961      0.0%       integer
StartStackAmt                                 11961      0.0%       integer
EndStackAmt                                   11961      0.0%       integer
HoleCards                                     11961      0.0%       array
VPIPPercent                                   11961      0.0%       integer

================================================================================
```
