# 02. GFX JSON Database Schema

PokerGFX JSON 데이터 저장을 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 1.1.0
**Date**: 2026-01-16
**Project**: Feature Table Automation (FT-0001)

---

## 0. 스키마 관리 정책

### 0.1 Single Source of Truth (SSOT)

> **마이그레이션 SQL이 SSOT입니다. 이 문서는 설계/참조 문서입니다.**

| 계층 | 파일 | 역할 | 업데이트 주체 |
|:----:|------|------|:-------------:|
| **SSOT** | `supabase/migrations/*.sql` | 실행 가능한 DDL | 마이그레이션 기준 |
| 설계/참조 | `docs/02-GFX-JSON-DB.md` (이 문서) | 설계 명세 | 인간 (설계자) |
| 구현 | `src/*.py` | Python 모델 | 마이그레이션 기준 동기화 |
| 실행 | Supabase DB (public 스키마) | 실제 데이터 저장소 | Migration SQL 적용 |

### 0.2 변경 관리 프로세스

스키마 변경이 필요한 경우 아래 프로세스를 따릅니다:

```
┌─────────────────┐
│ 1. PRD 수정     │  ← 설계자가 이 문서 업데이트
│ (이 문서)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Migration SQL│  ← PRD 변경사항 반영
│ 업데이트        │     supabase/migrations/*.sql
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Python 모델  │  ← 필요 시 코드 업데이트
│ 업데이트        │     gfx_json/src/sync_agent/models/
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Supabase DB  │  ← supabase db push 또는
│ Migration 적용  │     ALTER TABLE 직접 실행
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. 검증 및 테스트│
└─────────────────┘
```

### 0.3 변경 체크리스트

스키마 변경 시 아래 항목을 확인합니다:

- [ ] PRD (이 문서) 업데이트 완료
- [ ] Migration SQL 동기화 (`supabase/migrations/20260113082406_01_gfx_schema.sql`)
- [ ] Python 모델 동기화 (해당하는 경우)
- [ ] Transformer 동기화 (해당하는 경우)
- [ ] `schema-analysis-report.md` 업데이트
- [ ] Supabase DB에 Migration 적용
- [ ] 테스트 통과 확인

### 0.4 관련 파일

| 파일 | 위치 | 설명 |
|------|------|------|
| Migration SQL | `C:\claude\automation_schema\supabase\migrations\20260113082406_01_gfx_schema.sql` | DDL 실행 파일 (SSOT) |
| GFX Normalizer | `C:\claude\automation_schema\src\gfx_normalizer.py` | JSON → 정규화 구조 변환 |
| 스키마 검증 | `C:\claude\automation_schema\scripts\validate_gfx_schema.py` | 스키마 검증 도구 |
| 분석 보고서 | `C:\claude\automation_schema\schema_analysis_report.md` | 정합성 분석 |

---

## 1. 개요

### 1.1 목적

PokerGFX에서 생성되는 JSON 파일을 정규화된 관계형 데이터베이스에 저장하여:
- 핸드별 검색 및 분석
- 플레이어 통계 집계
- 핸드 등급(A/B/C) 분류 및 방송 적격성 판단
- 녹화 오프셋 기반 비디오 편집 지점 추출

### 1.2 JSON 분석 요약

```
gfx_json/
├── table-GG/           # 테이블 GG
│   └── 1015~1021/      # 날짜별 폴더 (MMDD)
└── table-pokercaster/  # 테이블 pokercaster
    └── 1015~1021/
```

**파일 네이밍**: `PGFX_live_data_export GameID={int64}.json`

### 1.3 JSON 스키마 (중첩 구조)

```
Root (Session)
├── ID (int64)                  # PokerGFX GameID
├── CreatedDateTimeUTC          # ISO 8601
├── EventTitle                  # 이벤트 제목 (선택)
├── SoftwareVersion             # "PokerGFX 3.2"
├── Type                        # "FEATURE_TABLE"
├── Payouts[10]                 # 페이아웃 배열
└── Hands[]                     # 핸드 배열
    ├── HandNum                 # 핸드 번호
    ├── Duration                # ISO 8601 Duration
    ├── StartDateTimeUTC        # 핸드 시작 시간
    ├── RecordingOffsetStart    # 녹화 오프셋
    ├── GameVariant             # "HOLDEM"
    ├── GameClass               # "FLOP"
    ├── BetStructure            # "NOLIMIT"
    ├── AnteAmt, BombPotAmt     # 앤티/폭탄팟 금액
    ├── NumBoards, RunItNumTimes
    ├── FlopDrawBlinds          # 블라인드 정보 객체
    ├── StudLimits              # Stud 리밋 객체
    ├── Events[]                # 액션 배열
    │   ├── EventType           # FOLD/BET/CALL/CHECK/RAISE/ALL_IN/BOARD_CARD
    │   ├── PlayerNum           # 플레이어 번호 (1-10, 0=보드)
    │   ├── BetAmt              # 베팅 금액
    │   ├── Pot                 # 팟 크기
    │   └── BoardCards          # 보드 카드 (null 또는 "5d")
    └── Players[]               # 플레이어 배열
        ├── PlayerNum           # 시트 번호 (1-10)
        ├── Name, LongName      # 플레이어 이름
        ├── HoleCards[]         # 홀 카드 ([""] 또는 ["10d 9d"])
        ├── StartStackAmt       # 시작 스택
        ├── EndStackAmt         # 종료 스택
        ├── CumulativeWinningsAmt
        └── 통계 (VPIP%, PFR%, Aggression%, ShowdownPct)
```

### 1.3.1 필드별 실제 예시 데이터 (gfx_json_data 기준)

> **데이터 소스**: `gfx_json_data/table-GG/`, `gfx_json_data/table-pokercaster/` 폴더의 실제 JSON 파일에서 추출

#### Session Level 예시

| 필드 | 예시 데이터 | 설명 |
|------|-------------|------|
| **ID** | `638961224831992165`, `638961999170907267`, `638962014211467634`, `638962926097967686`, `638963849867159576` | Windows FileTime 기반 int64, 고유 세션 식별자 |
| **CreatedDateTimeUTC** | `2025-10-15T10:54:43.1992165Z`, `2025-10-16T08:25:17.0907267Z`, `2025-10-17T10:10:09.7967686Z` | ISO 8601 UTC 타임스탬프 |
| **EventTitle** | `""` (빈 문자열) | 토너먼트/이벤트 명칭 (선택적) |
| **SoftwareVersion** | `"PokerGFX 3.2"` | GFX 소프트웨어 버전 |
| **Type** | `"FEATURE_TABLE"` | 테이블 타입 ENUM |
| **Payouts** | `[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]` | 10개 고정 슬롯 페이아웃 배열 |

#### Hand Level 예시

| 필드 | 예시 데이터 | 설명 |
|------|-------------|------|
| **HandNum** | `1`, `2`, `3` | 세션 내 핸드 순번 |
| **Duration** | `"PT35M37.2477537S"`, `"PT19.5488032S"`, `"PT13M25.5865565S"`, `"PT1M23.1911258S"`, `"PT2M56.3404049S"` | ISO 8601 Duration 형식 |
| **GameVariant** | `"HOLDEM"` | 게임 종류 |
| **GameClass** | `"FLOP"` | 게임 클래스 |
| **BetStructure** | `"NOLIMIT"` | 베팅 구조 |
| **AnteAmt** | `0`, `200`, `2000`, `3000`, `15000` | 앤티 금액 (칩) |
| **BombPotAmt** | `0` | 폭탄팟 금액 |
| **StartDateTimeUTC** | `"2025-10-15T12:03:20.9005907Z"`, `"2025-10-16T08:27:15.0463609Z"` | 핸드 시작 시간 |
| **RecordingOffsetStart** | `"P739538DT16H3M20.9005907S"`, `"P739539DT12H27M15.0463609S"` | 녹화 오프셋 (ISO 8601 Duration) |
| **NumBoards** | `1` | 보드 수 |
| **RunItNumTimes** | `1` | Run it twice 횟수 |
| **Description** | `""` | 핸드 설명 (선택적) |

#### FlopDrawBlinds (블라인드 정보) 예시

| 필드 | 예시 데이터 | 설명 |
|------|-------------|------|
| **AnteType** | `"BB_ANTE_BB1ST"` | 앤티 타입 ENUM |
| **BigBlindAmt** | `800`, `180000`, `200`, `2000`, `3000` | 빅블라인드 금액 |
| **SmallBlindAmt** | `80`, `5000`, `100`, `1000`, `1500` | 스몰블라인드 금액 |
| **ButtonPlayerNum** | `1`, `7`, `2`, `4`, `5` | 버튼 위치 플레이어 번호 |
| **BlindLevel** | `0` | 블라인드 레벨 |

#### Player Level 예시

| 필드 | 예시 데이터 | 설명 |
|------|-------------|------|
| **PlayerNum** | `1`, `2`, `3`, `4` | 시트 번호 (1-10) |
| **Name** | `"jhkg"`, `"SAD"`, `"asd"`, `"SEAT 1"`, `"SEAT 2"` | 플레이어 표시명 |
| **LongName** | `"jhkg"`, `"SAD"`, `"asd"`, `""`, `"Cristian Ivanus"` | 플레이어 전체 이름 |
| **HoleCards** | `[""]`, `["10d 9d"]`, `["qd 8h"]`, `["kd 10d"]`, `["9c 5d"]` | 홀 카드 (공백 구분 단일 문자열) |
| **StartStackAmt** | `1224444`, `2455123`, `3151166`, `4000000`, `8000000` | 시작 스택 (칩) |
| **EndStackAmt** | `1224444`, `2455123`, `3151166`, `4000000`, `7995000` | 종료 스택 (칩) |
| **CumulativeWinningsAmt** | `0`, `-5000`, `5000`, `-175000`, `15300` | 누적 승/패 금액 |
| **VPIPPercent** | `0`, `100`, `50`, `66`, `33` | VPIP 통계 (%) |
| **PreFlopRaisePercent** | `0`, `100`, `50`, `66`, `33` | PFR 통계 (%) |
| **AggressionFrequencyPercent** | `0`, `72`, `20`, `60`, `50` | 어그레션 통계 (%) |
| **WentToShowDownPercent** | `0`, `100` | 쇼다운 진출률 (%) |
| **SittingOut** | `false` | Sitting Out 여부 |
| **EliminationRank** | `-1` | 탈락 순위 (-1 = 미탈락) |
| **BlindBetStraddleAmt** | `0` | 블라인드/스트래들 금액 |

#### Event Level 예시

| 필드 | 예시 데이터 | 설명 |
|------|-------------|------|
| **EventType** | `"FOLD"`, `"CALL"`, `"BET"`, `"CHECK"`, `"ALL IN"`, `"BOARD CARD"` | 액션 타입 (**주의**: 공백 포함) |
| **PlayerNum** | `0`, `1`, `2`, `3`, `4`, `5` | 플레이어 번호 (0 = 보드/딜러) |
| **BetAmt** | `0`, `180000`, `500`, `700`, `2200` | 베팅 금액 |
| **Pot** | `0`, `185000`, `365000`, `545000`, `725000` | 팟 크기 |
| **BoardCards** | `null`, `"6d"`, `"6s"`, `"6h"`, `"6c"`, `"jh"` | 보드 카드 (단일 카드) |
| **BoardNum** | `0` | 보드 번호 (Run it twice 시 사용) |
| **NumCardsDrawn** | `0` | Draw 게임용 드로우 카드 수 |
| **DateTimeUTC** | `null` | 이벤트 시간 (대부분 null) |

> **중요 파싱 주의사항**:
> - `EventType`에 공백이 포함됨: `"ALL IN"` → DB ENUM `ALL_IN`, `"BOARD CARD"` → `BOARD_CARD`
> - `HoleCards`는 단일 문자열 배열: `["10d 9d"]` → 파싱 후 `["10d", "9d"]`로 분리
> - `BoardCards`는 BOARD_CARD 이벤트에서만 값이 존재, 그 외는 `null`

### 1.4 JSON Field → DB Column 매핑표

> **주의**: JSON 필드명과 DB 컬럼명이 다릅니다. 파싱 시 반드시 아래 매핑을 참조하세요.

#### 1.4.1 Session Level (gfx_sessions)

| JSON 필드 | DB 컬럼 | 타입 변환 | 비고 |
|-----------|---------|-----------|------|
| **`ID`** | `session_id` | int64 → BIGINT | **핵심 매핑** (필드명 주의!) |
| `CreatedDateTimeUTC` | `session_created_at` | ISO 8601 → TIMESTAMPTZ | |
| `Type` | `table_type` | string → ENUM | 'FEATURE_TABLE', 'UNKNOWN' 등 |
| `EventTitle` | `event_title` | string → TEXT | 빈 문자열 가능 |
| `SoftwareVersion` | `software_version` | string → TEXT | |
| `Payouts` | `payouts` | int[10] → INTEGER[] | 고정 10개 슬롯 |
| `Hands.length` | `hand_count` | 계산 → INTEGER | `len(Hands)` |
| *파일명* | `file_name` | 추출 → TEXT | 파서에서 추출 |
| *SHA256* | `file_hash` | 계산 → TEXT | 파서에서 계산 |
| *전체 JSON* | `raw_json` | object → JSONB | 원본 보존 |

**파싱 예시**:
```python
# ✅ 올바른 방법
session_id = data["ID"]  # JSON 필드명은 "ID"

# ❌ 잘못된 방법 (KeyError 발생)
session_id = data["session_id"]  # JSON에 이 필드 없음!
```

#### 1.4.2 Hand Level (gfx_hands)

| JSON 필드 | DB 컬럼 | 타입 변환 | 비고 |
|-----------|---------|-----------|------|
| *parent.ID* | `session_id` | BIGINT | FK (부모 세션의 ID) |
| `HandNum` | `hand_num` | int → INTEGER | |
| `GameVariant` | `game_variant` | string → ENUM | 'HOLDEM' 등 |
| `GameClass` | `game_class` | string → ENUM | 'FLOP' 등 |
| `BetStructure` | `bet_structure` | string → ENUM | 'NOLIMIT' 등 |
| `Duration` | `duration_seconds` | ISO 8601 Duration → INTEGER | 파싱 필요 |
| `StartDateTimeUTC` | `start_time` | ISO 8601 → TIMESTAMPTZ | |
| `RecordingOffsetStart` | `recording_offset_iso` | string → TEXT | 원본 보존 |
| `RecordingOffsetStart` | `recording_offset_seconds` | ISO 8601 Duration → BIGINT | 파싱 |
| `NumBoards` | `num_boards` | int → INTEGER | |
| `RunItNumTimes` | `run_it_num_times` | int → INTEGER | |
| `AnteAmt` | `ante_amt` | int → BIGINT | 칩 금액 |
| `BombPotAmt` | `bomb_pot_amt` | int → BIGINT | 칩 금액 |
| `Description` | `description` | string → TEXT | |
| `FlopDrawBlinds` | `blinds` | object → JSONB | 전체 객체 저장 |
| `StudLimits` | `stud_limits` | object → JSONB | 전체 객체 저장 |
| *Events[-1].Pot* | `pot_size` | 계산 → BIGINT | 마지막 이벤트 Pot |
| *len(Players)* | `player_count` | 계산 → INTEGER | |

**Duration 파싱 예시**:
```python
# "PT35M37.2477537S" → 2137 (초)
import re
def parse_duration(duration: str) -> int:
    total = 0
    if m := re.search(r'(\d+(?:\.\d+)?)M', duration):
        total += float(m.group(1)) * 60
    if m := re.search(r'(\d+(?:\.\d+)?)S', duration):
        total += float(m.group(1))
    return int(total)
```

#### 1.4.3 Event Level (gfx_events)

| JSON 필드 | DB 컬럼 | 타입 변환 | 변환 주의 |
|-----------|---------|-----------|----------|
| *배열 인덱스* | `event_order` | int → INTEGER | |
| `EventType` | `event_type` | string → ENUM | **`"BOARD CARD"` → `BOARD_CARD`** |
| `PlayerNum` | `player_num` | int → INTEGER | 0 = board |
| `BetAmt` | `bet_amt` | int → BIGINT | 칩 금액 |
| `Pot` | `pot` | int → BIGINT | 칩 금액 |
| `BoardCards` | `board_cards` | string → TEXT | 단일 카드 |
| `BoardNum` | `board_num` | int → INTEGER | |
| `NumCardsDrawn` | `num_cards_drawn` | int → INTEGER | |
| `DateTimeUTC` | `event_time` | string → TIMESTAMPTZ | null 가능 |

**EventType 변환 규칙**:
```python
EVENT_TYPE_MAP = {
    "FOLD": "FOLD",
    "CHECK": "CHECK",
    "CALL": "CALL",
    "BET": "BET",
    "RAISE": "RAISE",
    "ALL IN": "ALL_IN",      # 공백 → 언더스코어
    "BOARD CARD": "BOARD_CARD",  # 공백 → 언더스코어
}
```

#### 1.4.4 Player Level (gfx_hand_players)

| JSON 필드 | DB 컬럼 | 타입 변환 | 변환 주의 |
|-----------|---------|-----------|----------|
| `PlayerNum` | `seat_num` | int → INTEGER | CHECK (1-10) |
| `Name` | `player_name` | string → TEXT | |
| `LongName` | *gfx_players 참조* | string → TEXT | |
| `HoleCards` | `hole_cards` | string[] → TEXT[] | **공백 분리 필요** |
| *hole_cards 유무* | `has_shown` | bool → BOOLEAN | 계산 |
| `StartStackAmt` | `start_stack_amt` | int → BIGINT | 칩 금액 |
| `EndStackAmt` | `end_stack_amt` | int → BIGINT | 칩 금액 |
| `CumulativeWinningsAmt` | `cumulative_winnings_amt` | int → BIGINT | 칩 금액 |
| `BlindBetStraddleAmt` | `blind_bet_straddle_amt` | int → BIGINT | 칩 금액 |
| `SittingOut` | `sitting_out` | bool → BOOLEAN | |
| `EliminationRank` | `elimination_rank` | int → INTEGER | -1 = 미탈락 |
| *stack 증가 여부* | `is_winner` | bool → BOOLEAN | 계산 |
| `VPIPPercent` | `vpip_percent` | float → NUMERIC(5,2) | |
| `PreFlopRaisePercent` | `preflop_raise_percent` | float → NUMERIC(5,2) | |
| `AggressionFrequencyPercent` | `aggression_frequency_percent` | float → NUMERIC(5,2) | |
| `WentToShowDownPercent` | `went_to_showdown_percent` | float → NUMERIC(5,2) | |

**HoleCards 파싱 규칙**:
```python
# JSON: ["10d 9d"] (공백으로 구분된 단일 문자열)
# DB:   ["10d", "9d"] (개별 카드 배열)

def parse_hole_cards(cards: list[str]) -> list[str]:
    if not cards or cards[0] == "":
        return []
    return cards[0].split()  # "10d 9d" → ["10d", "9d"]
```

#### 1.4.5 Player Master (gfx_players)

| JSON 필드 | DB 컬럼 | 타입 변환 | 비고 |
|-----------|---------|-----------|------|
| *MD5(Name:LongName)* | `player_hash` | 계산 → TEXT | UNIQUE |
| `Name` | `name` | string → TEXT | |
| `LongName` | `long_name` | string → TEXT | |

**Player Hash 생성**:
```python
import hashlib
def generate_player_hash(name: str, long_name: str) -> str:
    key = f"{name.lower().strip()}:{long_name.lower().strip()}"
    return hashlib.md5(key.encode()).hexdigest()
```

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PokerGFX Database Schema                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐       ┌──────────────────────┐
│   gfx_players        │       │    gfx_sessions      │
│   (플레이어 마스터)    │       │    (세션/게임 단위)    │
├──────────────────────┤       ├──────────────────────┤
│ PK id: uuid          │       │ PK id: uuid          │
│    player_hash: text │◄──┐   │ UK session_id: int8  │───┐
│    name: text        │   │   │ UK file_hash: text   │   │
│    long_name: text   │   │   │    file_name: text   │   │
│    total_hands: int  │   │   │    table_type: enum  │   │
│    first_seen_at: ts │   │   │    event_title: text │   │
│    last_seen_at: ts  │   │   │    software_version  │   │
│    created_at: ts    │   │   │    payouts: int[]    │   │
│    updated_at: ts    │   │   │    hand_count: int   │   │
└──────────────────────┘   │   │    session_start: ts │   │
                           │   │    nas_path: text    │   │
                           │   │    sync_status: enum │   │
                           │   │    raw_json: jsonb   │   │
                           │   │    created_at: ts    │   │
                           │   └──────────────────────┘   │
                           │              │               │
                           │              │ 1:N           │
                           │              ▼               │
                           │   ┌──────────────────────┐   │
                           │   │     gfx_hands        │   │
                           │   │    (핸드 단위)        │   │
                           │   ├──────────────────────┤   │
                           │   │ PK id: uuid          │   │
                           │   │ FK session_id: int8  │◄──┘
                           │   │    hand_num: int     │
                           │   │    game_variant: enum│
                           │   │    game_class: enum  │
                           │   │    bet_structure:enum│
                           │   │    duration_seconds  │
                           │   │    start_time: ts    │
                           │   │    recording_offset  │
                           │   │    ante_amt: int     │
                           │   │    bomb_pot_amt: int │
                           │   │    blinds: jsonb     │
                           │   │    pot_size: int     │
                           │   │    board_cards: text[]│
                           │   │    winner_name: text │
                           │   │    created_at: ts    │
                           │   └──────────────────────┘
                           │              │
                           │              │ 1:N
        ┌──────────────────┴──────────────┼──────────────────┐
        │                                 │                  │
        ▼                                 ▼                  ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  gfx_hand_players    │  │    gfx_events        │  │    hand_grades       │
│  (핸드별 플레이어)     │  │   (액션/이벤트)       │  │   (핸드 등급)         │
├──────────────────────┤  ├──────────────────────┤  ├──────────────────────┤
│ PK id: uuid          │  │ PK id: uuid          │  │ PK id: uuid          │
│ FK hand_id: uuid     │  │ FK hand_id: uuid     │  │ FK hand_id: uuid     │
│ FK player_id: uuid   │  │    event_order: int  │  │    grade: char(1)    │
│    seat_num: int     │  │    event_type: enum  │  │    has_premium_hand  │
│    player_name: text │  │    player_num: int   │  │    has_long_playtime │
│    hole_cards: text[]│  │    bet_amt: int      │  │    has_premium_board │
│    start_stack: int  │  │    pot: int          │  │    conditions_met    │
│    end_stack: int    │  │    board_cards: text │  │    broadcast_eligible│
│    cumulative_win    │  │    board_num: int    │  │    graded_by: text   │
│    sitting_out: bool │  │    created_at: ts    │  │    graded_at: ts     │
│    is_winner: bool   │  └──────────────────────┘  └──────────────────────┘
│    vpip_percent      │
│    created_at: ts    │
└──────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `gfx_sessions` 1:N `gfx_hands` | 세션당 여러 핸드 |
| `gfx_hands` 1:N `gfx_events` | 핸드당 여러 액션 |
| `gfx_hands` 1:N `gfx_hand_players` | 핸드당 최대 10명 |
| `gfx_hands` 1:1 `hand_grades` | 핸드당 1개 등급 |
| `gfx_players` 1:N `gfx_hand_players` | 플레이어당 여러 핸드 참여 |

---

## 3. Enum 타입 정의

```sql
-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 테이블 타입 (게임 종류)
CREATE TYPE table_type AS ENUM (
    'FEATURE_TABLE',    -- 피처 테이블 (방송용)
    'MAIN_TABLE',       -- 메인 테이블
    'FINAL_TABLE',      -- 파이널 테이블
    'SIDE_TABLE',       -- 사이드 테이블
    'UNKNOWN'           -- 미분류
);

-- 게임 변형
CREATE TYPE game_variant AS ENUM (
    'HOLDEM',           -- Texas Hold'em
    'OMAHA',            -- Omaha
    'OMAHA_HILO',       -- Omaha Hi-Lo
    'STUD',             -- 7-Card Stud
    'STUD_HILO',        -- Stud Hi-Lo
    'RAZZ',             -- Razz
    'DRAW',             -- 5-Card Draw
    'MIXED'             -- Mixed games
);

-- 게임 클래스
CREATE TYPE game_class AS ENUM (
    'FLOP',             -- Hold'em, Omaha (커뮤니티 카드)
    'STUD',             -- 7-Card Stud
    'DRAW',             -- 5-Card Draw
    'MIXED'             -- Mixed games
);

-- 베팅 구조
CREATE TYPE bet_structure AS ENUM (
    'NOLIMIT',          -- No Limit
    'POTLIMIT',         -- Pot Limit
    'LIMIT',            -- Fixed Limit
    'SPREAD_LIMIT'      -- Spread Limit
);

-- 이벤트 타입 (액션)
CREATE TYPE event_type AS ENUM (
    'FOLD',             -- 폴드
    'CHECK',            -- 체크
    'CALL',             -- 콜
    'BET',              -- 베팅
    'RAISE',            -- 레이즈
    'ALL_IN',           -- 올인
    'BOARD_CARD',       -- 보드 카드 공개
    'ANTE',             -- 앤티
    'BLIND',            -- 블라인드
    'STRADDLE',         -- 스트래들
    'BRING_IN',         -- 브링인 (Stud)
    'MUCK',             -- 카드 버림
    'SHOW',             -- 카드 공개
    'WIN'               -- 팟 획득
);

-- 동기화 상태
CREATE TYPE sync_status AS ENUM (
    'pending',          -- 처리 대기
    'synced',           -- 동기화 완료
    'updated',          -- 업데이트됨
    'failed',           -- 실패
    'archived'          -- 아카이브됨
);

-- 앤티 타입
CREATE TYPE ante_type AS ENUM (
    'NO_ANTE',          -- 앤티 없음
    'BB_ANTE_BB1ST',    -- BB 앤티 (BB 먼저)
    'BB_ANTE_BTN1ST',   -- BB 앤티 (버튼 먼저)
    'ALL_ANTE',         -- 전원 앤티
    'DEAD_ANTE'         -- 데드 앤티
);
```

---

## 4. 테이블 DDL

### 4.1 gfx_players (플레이어 마스터)

```sql
-- ============================================================================
-- gfx_players: 플레이어 마스터 테이블 (중복 제거)
-- 동일 플레이어를 여러 세션/핸드에서 참조
-- ============================================================================

CREATE TABLE gfx_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 플레이어 식별 (name + long_name 해시로 중복 방지)
    player_hash TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    long_name TEXT DEFAULT '',

    -- 누적 통계 (추후 집계용)
    total_hands_played INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,

    -- 타임스탬프
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_gfx_players_name ON gfx_players(name);
CREATE INDEX idx_gfx_players_hash ON gfx_players(player_hash);
```

### 4.2 gfx_sessions (세션/게임 단위)

```sql
-- ============================================================================
-- gfx_sessions: PokerGFX 게임 세션 저장
-- 원본 JSON 전체를 raw_json에 보관 (감사 추적)
-- ============================================================================

CREATE TABLE gfx_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- PokerGFX 세션 식별자 (Windows FileTime 기반 int64)
    session_id BIGINT NOT NULL UNIQUE,

    -- 파일 정보
    file_name TEXT NOT NULL,
    file_hash TEXT NOT NULL UNIQUE,  -- SHA256 (중복 방지)
    nas_path TEXT,                    -- 원본 NAS 경로

    -- 세션 메타데이터
    table_type table_type NOT NULL DEFAULT 'UNKNOWN',
    event_title TEXT DEFAULT '',
    software_version TEXT DEFAULT '',
    payouts INTEGER[] DEFAULT ARRAY[]::INTEGER[],

    -- 집계 필드
    hand_count INTEGER DEFAULT 0,
    player_count INTEGER DEFAULT 0,
    total_duration_seconds INTEGER DEFAULT 0,

    -- 시간 정보
    session_created_at TIMESTAMPTZ,   -- CreatedDateTimeUTC from JSON
    session_start_time TIMESTAMPTZ,   -- 첫 핸드 시작 시간
    session_end_time TIMESTAMPTZ,     -- 마지막 핸드 종료 시간

    -- 원본 JSON 저장
    raw_json JSONB NOT NULL,

    -- 동기화 상태
    sync_status sync_status DEFAULT 'pending',
    sync_error TEXT,

    -- 타임스탬프
    processed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_gfx_sessions_session_id ON gfx_sessions(session_id);
CREATE INDEX idx_gfx_sessions_file_hash ON gfx_sessions(file_hash);
CREATE INDEX idx_gfx_sessions_table_type ON gfx_sessions(table_type);
CREATE INDEX idx_gfx_sessions_created_at ON gfx_sessions(session_created_at DESC);
CREATE INDEX idx_gfx_sessions_sync_status ON gfx_sessions(sync_status);
CREATE INDEX idx_gfx_sessions_processed_at ON gfx_sessions(processed_at DESC);

-- JSONB 인덱스 (선택적)
CREATE INDEX idx_gfx_sessions_raw_json_type
    ON gfx_sessions USING GIN ((raw_json -> 'Type'));
```

### 4.3 gfx_hands (핸드 단위)

```sql
-- ============================================================================
-- gfx_hands: 개별 핸드 데이터
-- 세션의 Hands[] 배열을 정규화하여 저장
-- ============================================================================

CREATE TABLE gfx_hands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 세션 참조 (session_id는 BIGINT)
    session_id BIGINT NOT NULL,

    -- 핸드 식별
    hand_num INTEGER NOT NULL,

    -- 게임 정보
    game_variant game_variant DEFAULT 'HOLDEM',
    game_class game_class DEFAULT 'FLOP',
    bet_structure bet_structure DEFAULT 'NOLIMIT',

    -- 시간 정보
    duration_seconds INTEGER DEFAULT 0,
    start_time TIMESTAMPTZ NOT NULL,
    recording_offset_iso TEXT,        -- ISO 8601 Duration (원본 보존)
    recording_offset_seconds BIGINT,  -- 변환된 초 단위

    -- 게임 설정
    num_boards INTEGER DEFAULT 1,
    run_it_num_times INTEGER DEFAULT 1,
    ante_amt BIGINT DEFAULT 0,       -- 칩 금액: BIGINT (오버플로우 방지)
    bomb_pot_amt BIGINT DEFAULT 0,   -- 칩 금액: BIGINT (오버플로우 방지)
    description TEXT DEFAULT '',

    -- 블라인드 정보 (JSONB로 유연하게 저장)
    blinds JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "ante_type": "BB_ANTE_BB1ST",
        "big_blind_amt": 180000,
        "big_blind_player_num": 3,
        "small_blind_amt": 5000,
        "small_blind_player_num": 2,
        "button_player_num": 1,
        "third_blind_amt": 0,
        "blind_level": 0
    }
    */

    -- Stud 전용 리밋 (JSONB)
    stud_limits JSONB DEFAULT '{}'::JSONB,

    -- 집계 필드
    pot_size BIGINT DEFAULT 0,       -- 칩 금액: BIGINT (오버플로우 방지)
    player_count INTEGER DEFAULT 0,
    showdown_count INTEGER DEFAULT 0,

    -- 보드 카드 (배열)
    board_cards TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 승자 정보
    winner_name TEXT,
    winner_seat INTEGER,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_session_hand UNIQUE (session_id, hand_num)
);

-- 인덱스
CREATE INDEX idx_gfx_hands_session_id ON gfx_hands(session_id);
CREATE INDEX idx_gfx_hands_hand_num ON gfx_hands(hand_num);
CREATE INDEX idx_gfx_hands_start_time ON gfx_hands(start_time DESC);
CREATE INDEX idx_gfx_hands_pot_size ON gfx_hands(pot_size DESC);
CREATE INDEX idx_gfx_hands_game_variant ON gfx_hands(game_variant);
CREATE INDEX idx_gfx_hands_duration ON gfx_hands(duration_seconds DESC);

-- 보드 카드 검색용 GIN 인덱스
CREATE INDEX idx_gfx_hands_board_cards ON gfx_hands USING GIN (board_cards);
```

### 4.4 gfx_hand_players (핸드별 플레이어 상태)

```sql
-- ============================================================================
-- gfx_hand_players: 핸드별 플레이어 상태
-- 각 핸드에서의 플레이어 스택, 카드, 통계 저장
-- ============================================================================

CREATE TABLE gfx_hand_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조
    hand_id UUID NOT NULL REFERENCES gfx_hands(id) ON DELETE CASCADE,
    player_id UUID REFERENCES gfx_players(id) ON DELETE SET NULL,

    -- 시트 정보
    seat_num INTEGER NOT NULL CHECK (seat_num BETWEEN 1 AND 10),
    player_name TEXT NOT NULL,  -- 비정규화 (조회 성능)

    -- 홀 카드 (쇼다운 시만 존재)
    hole_cards TEXT[] DEFAULT ARRAY[]::TEXT[],
    has_shown BOOLEAN DEFAULT FALSE,

    -- 스택 정보 (칩 금액: 모두 BIGINT - 오버플로우 방지)
    start_stack_amt BIGINT DEFAULT 0,
    end_stack_amt BIGINT DEFAULT 0,
    cumulative_winnings_amt BIGINT DEFAULT 0,
    blind_bet_straddle_amt BIGINT DEFAULT 0,

    -- 상태
    sitting_out BOOLEAN DEFAULT FALSE,
    elimination_rank INTEGER DEFAULT -1,  -- -1 = not eliminated
    is_winner BOOLEAN DEFAULT FALSE,

    -- 통계 (핸드 종료 시점 기준)
    vpip_percent NUMERIC(5,2) DEFAULT 0,
    preflop_raise_percent NUMERIC(5,2) DEFAULT 0,
    aggression_frequency_percent NUMERIC(5,2) DEFAULT 0,
    went_to_showdown_percent NUMERIC(5,2) DEFAULT 0,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_hand_seat UNIQUE (hand_id, seat_num)
);

-- 인덱스
CREATE INDEX idx_gfx_hand_players_hand_id ON gfx_hand_players(hand_id);
CREATE INDEX idx_gfx_hand_players_player_id ON gfx_hand_players(player_id);
CREATE INDEX idx_gfx_hand_players_seat ON gfx_hand_players(seat_num);
CREATE INDEX idx_gfx_hand_players_winner ON gfx_hand_players(is_winner) WHERE is_winner = TRUE;
CREATE INDEX idx_gfx_hand_players_shown ON gfx_hand_players(has_shown) WHERE has_shown = TRUE;

-- 홀 카드 검색용 GIN 인덱스
CREATE INDEX idx_gfx_hand_players_cards ON gfx_hand_players USING GIN (hole_cards);
```

### 4.5 gfx_events (액션/이벤트)

```sql
-- ============================================================================
-- gfx_events: 핸드 내 액션/이벤트 시퀀스
-- FOLD, BET, CALL, RAISE, ALL_IN, BOARD_CARD 등
-- ============================================================================

CREATE TABLE gfx_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 핸드 참조
    hand_id UUID NOT NULL REFERENCES gfx_hands(id) ON DELETE CASCADE,

    -- 이벤트 순서 (핸드 내)
    event_order INTEGER NOT NULL,

    -- 이벤트 정보
    event_type event_type NOT NULL,
    player_num INTEGER DEFAULT 0,  -- 0 = 보드 카드

    -- 베팅 정보 (칩 금액: BIGINT - 오버플로우 방지)
    bet_amt BIGINT DEFAULT 0,
    pot BIGINT DEFAULT 0,

    -- 보드 카드 (BOARD_CARD 이벤트 시)
    board_cards TEXT,  -- 단일 카드 문자열 (예: "6d")
    board_num INTEGER DEFAULT 0,

    -- Draw 게임용
    num_cards_drawn INTEGER DEFAULT 0,

    -- 시간 (있을 경우)
    event_time TIMESTAMPTZ,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_hand_event_order UNIQUE (hand_id, event_order)
);

-- 인덱스
CREATE INDEX idx_gfx_events_hand_id ON gfx_events(hand_id);
CREATE INDEX idx_gfx_events_type ON gfx_events(event_type);
CREATE INDEX idx_gfx_events_player ON gfx_events(player_num) WHERE player_num > 0;
CREATE INDEX idx_gfx_events_board ON gfx_events(event_type) WHERE event_type = 'BOARD_CARD';
CREATE INDEX idx_gfx_events_order ON gfx_events(hand_id, event_order);
```

### 4.6 hand_grades (핸드 등급)

```sql
-- ============================================================================
-- hand_grades: 핸드 등급 분류 결과
-- grading/grader.py와 연동
-- ============================================================================

CREATE TABLE hand_grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 핸드 참조
    hand_id UUID NOT NULL REFERENCES gfx_hands(id) ON DELETE CASCADE,

    -- 등급 (A/B/C)
    grade CHAR(1) NOT NULL CHECK (grade IN ('A', 'B', 'C')),

    -- 등급 조건
    has_premium_hand BOOLEAN DEFAULT FALSE,     -- HandRank <= 4
    has_long_playtime BOOLEAN DEFAULT FALSE,    -- duration >= threshold
    has_premium_board_combo BOOLEAN DEFAULT FALSE,  -- board rank <= 7
    conditions_met INTEGER NOT NULL CHECK (conditions_met BETWEEN 0 AND 3),

    -- 방송 적격성
    broadcast_eligible BOOLEAN DEFAULT FALSE,

    -- 편집 포인트 제안
    suggested_edit_start_offset INTEGER,  -- 초 단위
    edit_start_confidence NUMERIC(3,2),

    -- 등급 부여 정보
    graded_by TEXT,  -- 'auto', 'manual', 'ai'
    graded_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 유니크 제약
    CONSTRAINT uq_hand_grade UNIQUE (hand_id)
);

-- 인덱스
CREATE INDEX idx_hand_grades_grade ON hand_grades(grade);
CREATE INDEX idx_hand_grades_eligible ON hand_grades(broadcast_eligible)
    WHERE broadcast_eligible = TRUE;
CREATE INDEX idx_hand_grades_hand_id ON hand_grades(hand_id);
```

### 4.7 sync_log (동기화 로그)

```sql
-- ============================================================================
-- sync_log: NAS 파일 동기화 추적
-- ============================================================================

CREATE TABLE sync_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 파일 정보
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    file_size_bytes BIGINT,

    -- 작업 정보
    operation TEXT NOT NULL,  -- created, modified, deleted
    status TEXT DEFAULT 'processing',  -- processing, success, failed, skipped

    -- 결과
    session_id UUID REFERENCES gfx_sessions(id),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 인덱스
CREATE INDEX idx_sync_log_hash ON sync_log(file_hash);
CREATE INDEX idx_sync_log_status ON sync_log(status);
CREATE INDEX idx_sync_log_created ON sync_log(created_at DESC);
```

---

## 5. 뷰 정의

### 5.1 v_recent_hands (최근 핸드 뷰)

```sql
-- ============================================================================
-- v_recent_hands: 최근 핸드 + 등급 정보 뷰
-- ============================================================================

CREATE OR REPLACE VIEW v_recent_hands AS
SELECT
    h.id,
    h.session_id,
    h.hand_num,
    h.game_variant,
    h.bet_structure,
    h.duration_seconds,
    h.start_time,
    h.pot_size,
    h.board_cards,
    h.winner_name,
    h.player_count,
    h.showdown_count,
    s.table_type,
    s.event_title,
    g.grade,
    g.broadcast_eligible,
    g.conditions_met
FROM gfx_hands h
LEFT JOIN gfx_sessions s ON h.session_id = s.session_id
LEFT JOIN hand_grades g ON h.id = g.hand_id
ORDER BY h.start_time DESC;
```

### 5.2 v_showdown_players (쇼다운 플레이어 뷰)

```sql
-- ============================================================================
-- v_showdown_players: 쇼다운 플레이어 (홀카드 공개)
-- ============================================================================

CREATE OR REPLACE VIEW v_showdown_players AS
SELECT
    hp.id,
    hp.hand_id,
    hp.player_name,
    hp.seat_num,
    hp.hole_cards,
    hp.start_stack_amt,
    hp.end_stack_amt,
    hp.cumulative_winnings_amt,
    hp.is_winner,
    h.hand_num,
    h.board_cards,
    h.pot_size,
    h.session_id
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
WHERE hp.has_shown = TRUE
ORDER BY h.start_time DESC, hp.seat_num;
```

### 5.3 v_session_summary (세션 요약 뷰)

```sql
-- ============================================================================
-- v_session_summary: 세션 요약 통계
-- ============================================================================

CREATE OR REPLACE VIEW v_session_summary AS
SELECT
    s.id,
    s.session_id,
    s.file_name,
    s.table_type,
    s.event_title,
    s.hand_count,
    s.total_duration_seconds,
    s.session_created_at,
    s.sync_status,
    COUNT(CASE WHEN g.grade = 'A' THEN 1 END) AS grade_a_count,
    COUNT(CASE WHEN g.grade = 'B' THEN 1 END) AS grade_b_count,
    COUNT(CASE WHEN g.grade = 'C' THEN 1 END) AS grade_c_count,
    COUNT(CASE WHEN g.broadcast_eligible THEN 1 END) AS eligible_count
FROM gfx_sessions s
LEFT JOIN gfx_hands h ON s.session_id = h.session_id
LEFT JOIN hand_grades g ON h.id = g.hand_id
GROUP BY s.id, s.session_id, s.file_name, s.table_type,
         s.event_title, s.hand_count, s.total_duration_seconds,
         s.session_created_at, s.sync_status
ORDER BY s.session_created_at DESC;
```

---

## 6. 함수 및 트리거

### 6.1 updated_at 자동 갱신

```sql
-- ============================================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_gfx_sessions_updated_at
    BEFORE UPDATE ON gfx_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gfx_hands_updated_at
    BEFORE UPDATE ON gfx_hands
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gfx_players_updated_at
    BEFORE UPDATE ON gfx_players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### 6.2 플레이어 해시 생성

```sql
-- ============================================================================
-- 함수: 플레이어 고유 해시 생성
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_player_hash(p_name TEXT, p_long_name TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN md5(LOWER(TRIM(COALESCE(p_name, ''))) || ':' || LOWER(TRIM(COALESCE(p_long_name, ''))));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 6.3 세션 통계 업데이트

```sql
-- ============================================================================
-- 함수: 세션 통계 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_session_stats(p_session_id BIGINT)
RETURNS VOID AS $$
BEGIN
    UPDATE gfx_sessions
    SET
        hand_count = (
            SELECT COUNT(*) FROM gfx_hands WHERE session_id = p_session_id
        ),
        total_duration_seconds = (
            SELECT COALESCE(SUM(duration_seconds), 0)
            FROM gfx_hands WHERE session_id = p_session_id
        ),
        session_start_time = (
            SELECT MIN(start_time) FROM gfx_hands WHERE session_id = p_session_id
        ),
        session_end_time = (
            SELECT MAX(start_time + (duration_seconds || ' seconds')::INTERVAL)
            FROM gfx_hands WHERE session_id = p_session_id
        ),
        updated_at = NOW()
    WHERE session_id = p_session_id;
END;
$$ LANGUAGE plpgsql;
```

### 6.4 ISO 8601 Duration 파싱

```sql
-- ============================================================================
-- 함수: ISO 8601 Duration을 초 단위로 변환
-- 입력 예: "PT39.2342715S", "PT35M37.2477537S"
-- ============================================================================

CREATE OR REPLACE FUNCTION parse_iso8601_duration(duration TEXT)
RETURNS NUMERIC AS $$
DECLARE
    days_match TEXT[];
    hours_match TEXT[];
    minutes_match TEXT[];
    seconds_match TEXT[];
    total_seconds NUMERIC := 0;
BEGIN
    IF duration IS NULL OR duration = '' THEN
        RETURN 0;
    END IF;

    -- 일 (D)
    days_match := regexp_match(duration, '(\d+(?:\.\d+)?)D', 'i');
    IF days_match IS NOT NULL THEN
        total_seconds := total_seconds + (days_match[1]::NUMERIC * 86400);
    END IF;

    -- 시간 (H)
    hours_match := regexp_match(duration, '(\d+(?:\.\d+)?)H', 'i');
    IF hours_match IS NOT NULL THEN
        total_seconds := total_seconds + (hours_match[1]::NUMERIC * 3600);
    END IF;

    -- 분 (M) - T 이후에만
    minutes_match := regexp_match(duration, 'T.*?(\d+(?:\.\d+)?)M', 'i');
    IF minutes_match IS NOT NULL THEN
        total_seconds := total_seconds + (minutes_match[1]::NUMERIC * 60);
    END IF;

    -- 초 (S)
    seconds_match := regexp_match(duration, '(\d+(?:\.\d+)?)S', 'i');
    IF seconds_match IS NOT NULL THEN
        total_seconds := total_seconds + seconds_match[1]::NUMERIC;
    END IF;

    RETURN total_seconds;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## 7. 인덱스 전략 및 쿼리 패턴

### 7.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 최근 세션 조회 | `ORDER BY session_created_at DESC` | `idx_gfx_sessions_created_at` |
| 파일 중복 체크 | `WHERE file_hash = ?` | `idx_gfx_sessions_file_hash` (UNIQUE) |
| 세션별 핸드 조회 | `WHERE session_id = ?` | `idx_gfx_hands_session_id` |
| 핸드별 이벤트 조회 | `WHERE hand_id = ? ORDER BY event_order` | `idx_gfx_events_order` |
| 방송 적격 핸드 | `WHERE broadcast_eligible = TRUE` | `idx_hand_grades_eligible` (partial) |
| 프리미엄 보드 검색 | `WHERE 'Ah' = ANY(board_cards)` | `idx_gfx_hands_board_cards` (GIN) |
| 쇼다운 플레이어 | `WHERE has_shown = TRUE` | `idx_gfx_hand_players_shown` (partial) |
| 플레이어별 핸드 | `WHERE player_id = ?` | `idx_gfx_hand_players_player_id` |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- gfx_sessions.id, gfx_hands.id, gfx_events.id, gfx_players.id, gfx_hand_players.id

-- Unique Constraints
-- gfx_sessions.session_id, gfx_sessions.file_hash
-- gfx_players.player_hash
-- (session_id, hand_num), (hand_id, seat_num), (hand_id, event_order)

-- B-tree Indexes (범위/정렬 쿼리)
-- gfx_sessions: session_created_at DESC, processed_at DESC
-- gfx_hands: start_time DESC, pot_size DESC, duration_seconds DESC
-- gfx_events: (hand_id, event_order)

-- GIN Indexes (배열/JSONB 검색)
-- gfx_hands.board_cards
-- gfx_hand_players.hole_cards
-- gfx_sessions.raw_json (선택적)

-- Partial Indexes (조건부 최적화)
-- hand_grades.broadcast_eligible WHERE TRUE
-- gfx_hand_players.is_winner WHERE TRUE
-- gfx_hand_players.has_shown WHERE TRUE
-- gfx_events.event_type WHERE 'BOARD_CARD'
```

---

## 8. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE gfx_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_hands ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_hand_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- gfx_players 정책
-- ============================================================================
CREATE POLICY "gfx_players_select_authenticated"
    ON gfx_players FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_players_insert_service"
    ON gfx_players FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "gfx_players_update_service"
    ON gfx_players FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- gfx_sessions 정책
-- ============================================================================
CREATE POLICY "gfx_sessions_select_authenticated"
    ON gfx_sessions FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_sessions_insert_service"
    ON gfx_sessions FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "gfx_sessions_update_service"
    ON gfx_sessions FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- gfx_hands 정책
-- ============================================================================
CREATE POLICY "gfx_hands_select_authenticated"
    ON gfx_hands FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_hands_insert_service"
    ON gfx_hands FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- gfx_hand_players 정책
-- ============================================================================
CREATE POLICY "gfx_hand_players_select_authenticated"
    ON gfx_hand_players FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_hand_players_insert_service"
    ON gfx_hand_players FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- gfx_events 정책
-- ============================================================================
CREATE POLICY "gfx_events_select_authenticated"
    ON gfx_events FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_events_insert_service"
    ON gfx_events FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- hand_grades 정책
-- ============================================================================
CREATE POLICY "hand_grades_select_authenticated"
    ON hand_grades FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "hand_grades_insert_service"
    ON hand_grades FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "hand_grades_update_service"
    ON hand_grades FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- sync_log 정책
-- ============================================================================
CREATE POLICY "sync_log_select_authenticated"
    ON sync_log FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "sync_log_all_service"
    ON sync_log FOR ALL
    USING (auth.role() = 'service_role');
```

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. gfx_players 테이블 생성
3. gfx_sessions 테이블 생성
4. gfx_hands 테이블 생성
5. gfx_hand_players 테이블 생성
6. gfx_events 테이블 생성
7. hand_grades 테이블 생성
8. sync_log 테이블 생성
9. 뷰 생성 (CREATE VIEW)
10. 함수 생성 (CREATE FUNCTION)
11. 트리거 생성 (CREATE TRIGGER)
12. 인덱스 생성 (CREATE INDEX)
13. RLS 정책 적용 (ALTER TABLE, CREATE POLICY)
```

### Rollback 순서 (역순)

```
1. RLS 정책 삭제 (DROP POLICY)
2. 인덱스 삭제 (DROP INDEX)
3. 트리거 삭제 (DROP TRIGGER)
4. 함수 삭제 (DROP FUNCTION)
5. 뷰 삭제 (DROP VIEW)
6. 테이블 삭제 (역순: sync_log → hand_grades → gfx_events → ...)
7. ENUM 타입 삭제 (DROP TYPE)
```

---

## 10. 제약조건 요약

| 테이블 | 제약조건 | 설명 |
|--------|----------|------|
| `gfx_sessions` | `session_id UNIQUE` | PokerGFX ID 중복 방지 |
| `gfx_sessions` | `file_hash UNIQUE` | 파일 중복 동기화 방지 |
| `gfx_hands` | `(session_id, hand_num) UNIQUE` | 세션 내 핸드 번호 중복 방지 |
| `gfx_hand_players` | `(hand_id, seat_num) UNIQUE` | 핸드 내 시트 중복 방지 |
| `gfx_hand_players` | `seat_num BETWEEN 1 AND 10` | 유효 시트 번호 |
| `gfx_events` | `(hand_id, event_order) UNIQUE` | 이벤트 순서 중복 방지 |
| `hand_grades` | `grade IN ('A','B','C')` | 유효 등급 값 |
| `hand_grades` | `conditions_met BETWEEN 0 AND 3` | 유효 조건 수 |

---

## 11. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `src/database/supabase_repository.py` | Repository 패턴 | 모든 테이블 |
| `src/primary/pokergfx_file_parser.py` | JSON 파싱 | gfx_sessions, gfx_hands |
| `src/models/hand.py` | 도메인 모델 | gfx_hands, gfx_hand_players |
| `src/grading/grader.py` | 등급 분류 | hand_grades |
| `src/sync_agent/sync_service.py` | NAS 동기화 | sync_log |

---

## Appendix: 카드 표기법

### 카드 랭크

| 표기 | 랭크 |
|------|------|
| 2-9 | 숫자 |
| 10 | Ten |
| j | Jack |
| q | Queen |
| k | King |
| a | Ace |

### 수트 (Suit)

| 표기 | 수트 |
|------|------|
| s | Spade |
| h | Heart |
| d | Diamond |
| c | Club |

### 예시

- `as` = Ace of Spades
- `10d` = Ten of Diamonds
- `kh` = King of Hearts

---

## 12. json 스키마 → public 스키마 연결 전략

### 12.1 현재 상황

Supabase DB에 두 개의 독립적인 GFX 관련 스키마가 존재:

| 스키마 | 테이블 수 | 목적 | 생성 방식 |
|--------|:--------:|------|-----------|
| `json` | 6개 | PokerGFX RFID 실시간 파싱 | 수동 (Supabase 대시보드) |
| `public` | 32개 | AEP 그래픽 렌더링 | 마이그레이션 파일 |

**문제점**: 두 스키마가 서로 연결되지 않아 데이터 활용 불가

### 12.2 테이블 매핑

| json 스키마 | public 스키마 | 필드 차이 |
|------------|--------------|----------|
| `json.gfx_sessions` | `public.gfx_sessions` | gfx_id ↔ session_id |
| `json.hands` | `public.gfx_hands` | hand_number ↔ hand_num |
| `json.hand_players` | `public.gfx_hand_players` | 대부분 일치 |
| `json.hand_actions` | `public.gfx_events` | 상세 필드 추가 필요 |
| `json.hand_cards` | (신규) `public.gfx_hand_cards` | public에 없음 |
| `json.hand_results` | (신규) `public.gfx_hand_results` | public에 없음 |

### 12.3 스키마 역할 분리 (수정된 전략)

> **중요**: `json` 스키마는 GFX JSON 파일의 고정 포맷을 그대로 반영하므로 **변경 불가**.
> JSON 파일 구조와 불일치 위험을 방지하기 위해 json 스키마는 원본 그대로 보존합니다.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        데이터 흐름 (수정된 전략)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   GFX JSON File                                                     │
│        │                                                            │
│        ▼                                                            │
│   ┌─────────────────┐                                               │
│   │  json 스키마     │  ← 원본 보존 (수정 금지)                       │
│   │  (Source)       │    GFX 파일 구조 1:1 매핑                      │
│   │  - gfx_sessions │                                               │
│   │  - hands        │                                               │
│   │  - hand_players │                                               │
│   │  - hand_actions │                                               │
│   │  - hand_cards   │                                               │
│   │  - hand_results │                                               │
│   └────────┬────────┘                                               │
│            │                                                        │
│            │  트리거 동기화 (INSERT/UPDATE 시 자동)                   │
│            ▼                                                        │
│   ┌─────────────────┐                                               │
│   │  public 스키마   │  ← AEP 렌더링용 확장 스키마                    │
│   │  (Target)       │    추가 컬럼, 계산 필드 포함                    │
│   │  - gfx_sessions │                                               │
│   │  - gfx_hands    │                                               │
│   │  - gfx_hand_*   │                                               │
│   │  - gfx_events   │                                               │
│   └────────┬────────┘                                               │
│            │                                                        │
│            ▼                                                        │
│   ┌─────────────────┐                                               │
│   │  AEP 렌더링 뷰   │                                               │
│   │  v_render_*     │                                               │
│   └─────────────────┘                                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

| 스키마 | 역할 | 수정 가능 | 데이터 소스 |
|--------|------|:---------:|-------------|
| `json` | GFX 파일 원본 저장 | ❌ 금지 | gfx_json 파서 |
| `public` | AEP 렌더링용 확장 | ✅ 가능 | json 스키마 동기화 |

### 12.4 구현 계획 (수정됨)

| Phase | 작업 | 상태 |
|-------|------|:----:|
| 1 | public 스키마 확장 (ALTER TABLE) | ✅ 완료 |
| 2 | 신규 테이블 추가 (gfx_hand_cards, gfx_hand_results) | ✅ 완료 |
| 3 | 동기화 트리거 생성 (json → public) | 📋 예정 |
| 4 | 기존 데이터 마이그레이션 | 📋 예정 |

> **Phase 5 (json 스키마 폐기) 제거됨**: json 스키마는 GFX 파일 원본으로 영구 보존

### 12.5 스키마 확장 SQL

#### gfx_hands 확장
```sql
ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    grade char(1) CHECK (grade IN ('A','B','C','D','F')),
    is_premium boolean DEFAULT false,
    is_showdown boolean DEFAULT false,
    grade_factors jsonb DEFAULT '{}',
    flop_cards jsonb,
    turn_card varchar(3),
    river_card varchar(3);
```

#### 신규 테이블: gfx_hand_cards
```sql
CREATE TABLE public.gfx_hand_cards (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id uuid NOT NULL REFERENCES public.gfx_hands(id) ON DELETE CASCADE,
    card_rank varchar(2) NOT NULL,
    card_suit char(1) NOT NULL,
    card_type varchar(20) NOT NULL,
    seat_number integer,
    card_order integer,
    created_at timestamptz DEFAULT now()
);
```

#### 신규 테이블: gfx_hand_results
```sql
CREATE TABLE public.gfx_hand_results (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id uuid NOT NULL REFERENCES public.gfx_hands(id) ON DELETE CASCADE,
    seat_number integer NOT NULL,
    is_winner boolean NOT NULL,
    won_amount numeric(12,2),
    hand_rank varchar(50),
    rank_value integer,
    best_five jsonb,
    created_at timestamptz DEFAULT now()
);
```

### 12.6 gfx_json 코드 수정

**필드 매핑 레이어**:
```python
# field_mapper.py
FIELD_MAPPING = {
    "gfx_sessions": {"gfx_id": "session_id", "source_file": "file_name"},
    "gfx_hands": {"hand_number": "hand_num"},
    "gfx_hand_players": {"start_stack": "start_stack_amt"},
    "gfx_events": {"action_order": "event_order", "bet_amount": "bet_amt"}
}
```

### 12.7 동기화 트리거 (Phase 3 예정)

json 스키마에 데이터가 INSERT/UPDATE될 때 public 스키마로 자동 동기화:

```sql
-- 예시: json.hands → public.gfx_hands 동기화 트리거
CREATE OR REPLACE FUNCTION sync_json_hands_to_public()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.gfx_hands (
        hand_num,
        session_id,
        grade,
        is_premium,
        is_showdown,
        -- 추가 필드...
    )
    VALUES (
        NEW.hand_number,
        NEW.session_id,
        NEW.grade,
        NEW.is_premium,
        NEW.is_showdown,
        -- 추가 필드...
    )
    ON CONFLICT (hand_num, session_id) DO UPDATE SET
        grade = EXCLUDED.grade,
        is_premium = EXCLUDED.is_premium,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_hands_to_public
    AFTER INSERT OR UPDATE ON json.hands
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_hands_to_public();
```

> **참고**: 상세 트리거 구현은 별도 마이그레이션 파일로 작성 예정

### 12.8 스키마 보존 정책

| 정책 | 내용 |
|------|------|
| **json 스키마** | 영구 보존 - GFX 파일 원본 구조 유지 |
| **public 스키마** | 확장 가능 - AEP 렌더링 요구사항에 맞게 수정 |
| **동기화 방향** | json → public (단방향) |
| **충돌 처리** | public 스키마 데이터 덮어쓰기 (json이 SSOT) |
