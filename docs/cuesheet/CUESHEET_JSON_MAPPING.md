# Cuesheet JSON 필드 매핑 정의서

**Version**: 1.0.0
**Date**: 2026-01-19
**기준 데이터**: WSOP SC Cyprus ME Day 3

---

## 1. 개요

Google Sheets 큐시트 데이터를 Supabase DB에 저장할 때 사용하는 JSON 필드 매핑 정의입니다.

### 1.1 주요 JSONB 필드

| 테이블 | 필드 | 용도 |
|--------|------|------|
| `broadcast_sessions` | `block_stats` | 블록별 통계 |
| `broadcast_sessions` | `commentators` | 해설자 정보 |
| `broadcast_sessions` | `settings` | 방송 설정 |
| `cue_items` | `gfx_data` | GFX 바인딩 데이터 |
| `cue_templates` | `data_schema` | 템플릿 필수 필드 |
| `cue_templates` | `sample_data` | 샘플 데이터 |

---

## 2. broadcast_sessions.block_stats

### 2.1 스키마 정의

```typescript
interface BlockStats {
  blocks: Block[];
  totals: BlockTotals;
}

interface Block {
  block_number: number;      // 1-21
  main_hands: number;        // MAIN 테이블 핸드 수
  sub_hands: number;         // SUB 테이블 핸드 수
  total_hands: number;       // MAIN + SUB
  virtual_count: number;     // 버추얼 GFX 수
  estimated_runtime: string; // "0:56:20"
  actual_runtime: string;    // "01:01:02"
  break_broadcast: string | null;  // 방송 휴식
  break_actual: string | null;     // 실제 휴식
}

interface BlockTotals {
  total_main: number;
  total_sub: number;
  total_hands: number;
  total_virtual: number;
  total_runtime: string;
}
```

### 2.2 Google Sheets 매핑 (INFO 시트)

| 시트 컬럼 | JSON 키 | 변환 규칙 |
|-----------|---------|-----------|
| A (BLOCK) | `block_number` | 직접 매핑 |
| B (MAIN) | `main_hands` | 직접 매핑 |
| C (SUB) | `sub_hands` | 직접 매핑 |
| D (HANDS) | `total_hands` | 직접 매핑 또는 계산 |
| E (VIRTUAL) | `virtual_count` | 직접 매핑 |
| F (Estimated RT) | `estimated_runtime` | 문자열 유지 |
| G (Actual RT) | `actual_runtime` | 문자열 유지 |
| H (BREAK 방송) | `break_broadcast` | "—" → null |
| I (Break 실제) | `break_actual` | "—" → null |

### 2.3 실제 데이터 예시

```json
{
  "blocks": [
    {
      "block_number": 1,
      "main_hands": 11,
      "sub_hands": 8,
      "total_hands": 19,
      "virtual_count": 5,
      "estimated_runtime": "0:56:20",
      "actual_runtime": "01:01:02",
      "break_broadcast": null,
      "break_actual": null
    },
    {
      "block_number": 3,
      "main_hands": 4,
      "sub_hands": 5,
      "total_hands": 9,
      "virtual_count": 2,
      "estimated_runtime": "0:25:00",
      "actual_runtime": "00:27:16",
      "break_broadcast": "0:15:00",
      "break_actual": "0:15:00"
    }
  ],
  "totals": {
    "total_main": 63,
    "total_sub": 71,
    "total_hands": 134,
    "total_virtual": 32,
    "total_runtime": "06:19:52"
  }
}
```

---

## 3. cue_items.gfx_data

### 3.1 GFX 템플릿별 JSON 스키마

#### 3.1.1 Mini Chip Table

**템플릿 코드**: `mini_chip_left`, `mini_chip_right`

```typescript
interface MiniChipTable {
  position: "LEFT" | "RIGHT";
  table_no: number;
  players: ChipPlayer[];
  blinds: string;
}

interface ChipPlayer {
  name: string;
  chips: number;
  is_winner?: boolean;
}
```

**실제 데이터:**
```json
{
  "position": "LEFT",
  "table_no": 24,
  "players": [
    {"name": "DAVID", "chips": 21240000},
    {"name": "J.SANGHYON CHEONG", "chips": 10030000, "is_winner": true},
    {"name": "JAEWON", "chips": 10030000},
    {"name": "S.CAMILO TORO HENAO", "chips": 10000000},
    {"name": "L.PARK", "chips": 10000000},
    {"name": "MIKE", "chips": 9980000},
    {"name": "YOHAN", "chips": 8750000}
  ],
  "blinds": "1K/2K - 2K (BB)"
}
```

#### 3.1.2 Mini Payouts Table

**템플릿 코드**: `mini_payouts`

```typescript
interface MiniPayouts {
  position: "LEFT" | "RIGHT";
  payouts: PayoutEntry[];
  blinds: string;
}

interface PayoutEntry {
  placement: string;        // "14TH-15TH", "22ND"
  player_name?: string;     // 특정 플레이어인 경우
  country?: string;
  amount: number;
}
```

**실제 데이터:**
```json
{
  "position": "LEFT",
  "payouts": [
    {"placement": "14TH-15TH", "amount": 42000},
    {"placement": "16TH-21ST", "amount": 35500},
    {"placement": "22ND", "player_name": "ZED LEE", "country": "KOREA", "amount": 35500}
  ],
  "blinds": "1K/2K - 2K (BB)"
}
```

#### 3.1.3 Feature Table Chip

**템플릿 코드**: `feature_table_chip`

```typescript
interface FeatureTableChip {
  table_no: number;
  players: FeaturePlayer[];
  blinds: string;
}

interface FeaturePlayer {
  seat: number;
  name: string;
  country: string;
  country_code?: string;
  chips: number;
  level?: number;
}
```

**실제 데이터:**
```json
{
  "table_no": 101,
  "players": [
    {"seat": 1, "name": "LIPAUKA", "country": "Belarus", "country_code": "BY", "chips": 2145000},
    {"seat": 2, "name": "ABDOLVAND", "country": "Ukraine", "country_code": "UA", "chips": 2030000},
    {"seat": 3, "name": "VOS", "country": "Netherlands", "country_code": "NL", "chips": 1685000}
  ],
  "blinds": "10K/20K - 20K (BB)"
}
```

#### 3.1.4 Player Profile (L3_Profile)

**템플릿 코드**: `player_profile`

```typescript
interface PlayerProfile {
  name: string;
  country: string;
  country_code: string;
  profile_image?: string;
  achievement?: string;
  ranking_info?: string;
  prize_info?: string;
  chips?: number;
  wsop_bracelets?: number;
}
```

**실제 데이터:**
```json
{
  "name": "MIKHAIL SHALAMOV",
  "country": "Russia",
  "country_code": "RU",
  "profile_image": "/images/players/shalamov.jpg",
  "achievement": "WSOP BRACELET WINNER",
  "ranking_info": "3RD ON RUSSIA ALL TIME MONEY LIST",
  "prize_info": "$2,084,179",
  "wsop_bracelets": 1
}
```

#### 3.1.5 Elimination

**템플릿 코드**: `eliminated`

```typescript
interface Elimination {
  player_name: string;
  country: string;
  country_code: string;
  placement: string;       // "42ND", "56TH"
  prize: number;
  hand_description?: string;  // "KK vs JJ"
  eliminator?: string;
}
```

**실제 데이터:**
```json
{
  "player_name": "OLIVER WEIS",
  "country": "Germany",
  "country_code": "DE",
  "placement": "52ND",
  "prize": 17500,
  "hand_description": "KK vs JJ - River J",
  "eliminator": "SPATARU"
}
```

#### 3.1.6 Elimination at Risk

**템플릿 코드**: `elimination_risk`

```typescript
interface EliminationRisk {
  player_name: string;
  country: string;
  country_code?: string;
  potential_placement: string;
  potential_prize: number;
  chips: number;
  bb_stack: number;
}
```

**실제 데이터:**
```json
{
  "player_name": "NIKOLAI FAL",
  "country": "Russia",
  "country_code": "RU",
  "potential_placement": "50TH",
  "potential_prize": 8700,
  "chips": 495000,
  "bb_stack": 6
}
```

#### 3.1.7 Leaderboard

**템플릿 코드**: `leaderboard`

```typescript
interface Leaderboard {
  title?: string;
  players_remaining: number;
  avg_stack?: number;
  players: LeaderboardPlayer[];
}

interface LeaderboardPlayer {
  rank: number;
  name: string;
  country: string;
  country_code: string;
  chips: number;
  bb: number;
}
```

**실제 데이터:**
```json
{
  "title": "WSOP SC Cyprus ME - Day 3 End",
  "players_remaining": 24,
  "avg_stack": 2625000,
  "players": [
    {"rank": 1, "name": "Jon Kyte", "country": "Norway", "country_code": "NO", "chips": 5510000, "bb": 69},
    {"rank": 2, "name": "Andrei Spataru", "country": "Romania", "country_code": "RO", "chips": 4905000, "bb": 61},
    {"rank": 3, "name": "Daniel Rezaei", "country": "Austria", "country_code": "AT", "chips": 4700000, "bb": 59}
  ]
}
```

#### 3.1.8 VPIP Stats

**템플릿 코드**: `vpip`

```typescript
interface VPIP {
  player_name: string;
  country: string;
  country_code?: string;
  vpip_percent: number;
  sample_hands?: number;
}
```

**실제 데이터:**
```json
{
  "player_name": "BAGIROV",
  "country": "Russia",
  "country_code": "RU",
  "vpip_percent": 72,
  "sample_hands": 50
}
```

#### 3.1.9 Chip Flow

**템플릿 코드**: `chip_flow`

```typescript
interface ChipFlow {
  player_name: string;
  country: string;
  country_code?: string;
  chip_history: number[];
  period: string;           // "LAST 20 HANDS"
  current_chips: number;
}
```

**실제 데이터:**
```json
{
  "player_name": "BAGIROV",
  "country": "Russia",
  "country_code": "RU",
  "chip_history": [685000, 785000, 1785000, 2785000, 3785000],
  "period": "LAST 20 HANDS",
  "current_chips": 3785000
}
```

#### 3.1.10 Chip Comparison

**템플릿 코드**: `chip_comparison`

```typescript
interface ChipComparison {
  player1: ComparisonPlayer;
  player2: ComparisonPlayer;
  context?: string;
}

interface ComparisonPlayer {
  name: string;
  country: string;
  country_code?: string;
  chips: number;
  bb: number;
}
```

---

## 4. chipcount 시트 → wsop_chip_counts 매핑

### 4.1 직접 컬럼 매핑

| 시트 컬럼 | DB 필드 | 타입 | 변환 |
|-----------|---------|------|------|
| A (Rank) | chip_rank | INTEGER | 직접 |
| B (PokerRoom) | poker_room | TEXT | 직접 |
| C (TableName) | table_name | TEXT | 직접 |
| D (TableId) | table_id | INTEGER | 직접 |
| E (TableNo) | table_no | INTEGER | 직접 |
| F (SeatId) | seat_id | INTEGER | 직접 |
| G (SeatNo) | seat_no | INTEGER | 직접 |
| H (PlayerId) | pokercaster_player_id | INTEGER | 직접 |
| I (PlayerName) | player_name | TEXT | 직접 |
| J (Nationality) | country_code | TEXT | 직접 (ISO 2자리) |
| K (Chipcount) | chip_count | BIGINT | 콤마 제거 |
| L (BB) | bb_stack | INTEGER | 직접 |

### 4.2 실제 데이터 예시

```json
{
  "chip_rank": 1,
  "poker_room": "WSOP",
  "table_name": "Feature Table",
  "table_id": 44186,
  "table_no": 101,
  "seat_id": 1001,
  "seat_no": 1,
  "pokercaster_player_id": 12345,
  "player_name": "Vadzim Lipauka",
  "country_code": "BY",
  "chip_count": 2145000,
  "bb_stack": 53
}
```

---

## 5. main/sub/virtual 시트 → cue_items 매핑

### 5.1 공통 필드 매핑

| 시트 컬럼 | DB 필드 | 타입 | 비고 |
|-----------|---------|------|------|
| FIELD | field_count | INTEGER | **신규** |
| Cyprus | recording_time | TIME | 현지 시간 |
| Seoul | seoul_time | TIME | **신규** |
| # | hand_number | INTEGER | - |
| 📋 | copy_status | TEXT | "복사완료" |
| File | file_name | TEXT | 패턴별 분류 |
| 🏆 | hand_rank | ENUM | A/B/B-/C/SOFT |
| Hand History | hand_history | TEXT | - |
| Edit Point | edit_point | TEXT | - |
| PD Note | pd_note | TEXT | - |
| Subtitle | subtitle_confirm | TEXT | virtual 시트 |

### 5.2 content_type 결정 규칙

| 시트 | File 패턴 | content_type |
|------|-----------|--------------|
| main | `A_XXXX` | 'main' |
| sub | `B_XXXX` | 'sub' |
| virtual | `*_SC*` | 'virtual' (soft content) |
| virtual | `*_VT*` | 'virtual' (table content) |
| virtual | `*_Opening*` | 'opening_sequence' |

### 5.3 파일명 파싱 함수

```python
import re

def parse_file_name(file_name: str) -> dict:
    """파일명에서 메타데이터 추출"""

    # MAIN 테이블 핸드
    if match := re.match(r'^A_(\d{4})$', file_name):
        return {
            "type": "main_hand",
            "hand_number": int(match.group(1))
        }

    # SUB 테이블 핸드
    if match := re.match(r'^B_(\d{4})$', file_name):
        return {
            "type": "sub_hand",
            "hand_number": int(match.group(1))
        }

    # 소프트 콘텐츠 (플레이어 프로필 등)
    if match := re.match(r'^(\d{4})_SC(\d{3})_(.+)$', file_name):
        return {
            "type": "soft_content",
            "time_code": match.group(1),
            "sequence": int(match.group(2)),
            "description": match.group(3)
        }

    # 버추얼 테이블
    if match := re.match(r'^(\d{4})_VT(\d{3})_(.+)$', file_name):
        return {
            "type": "virtual_table",
            "time_code": match.group(1),
            "sequence": int(match.group(2)),
            "description": match.group(3)
        }

    return {"type": "unknown", "raw": file_name}
```

---

## 6. 템플릿 시트 → cue_templates 매핑

### 6.1 템플릿 타입 매핑

| 시트 식별자 | DB template_type | 설명 |
|-------------|------------------|------|
| [LEFT]MINI_CHIP_TABLE | mini_chip_left | 좌측 미니 칩 테이블 |
| [RIGHT]MINI_CHIP_TABLE | mini_chip_right | 우측 미니 칩 테이블 |
| [LEFT]MINI_PAYOUTS_TABLE | mini_payouts | 좌측 상금 테이블 |
| FEATURE TABLE | feature_table_chip | 피처 테이블 칩카운트 |
| [ELIMINATION AT RISK] | elimination_risk | 탈락 위험 |
| [ELIMINATED] | eliminated | 탈락 표시 |
| L3_Profile | player_profile | 플레이어 프로필 |
| [VPIP] | vpip | VPIP 통계 |
| [CHIP FLOW] | chip_flow | 칩 변동 그래프 |
| [CHIP COMPARISON] | chip_comparison | 칩 비교 |
| [CHIPS IN PLAY] | chips_in_play | 총 칩 수량 |
| [BLINDS] | blinds | 블라인드 정보 |
| MONEY LIST | money_list | 역대 상금 순위 |

### 6.2 data_schema 정의

```json
{
  "mini_chip_left": {
    "required": ["table_no", "players", "blinds"],
    "properties": {
      "table_no": {"type": "integer"},
      "players": {
        "type": "array",
        "items": {
          "required": ["name", "chips"],
          "properties": {
            "name": {"type": "string"},
            "chips": {"type": "integer"},
            "is_winner": {"type": "boolean"}
          }
        }
      },
      "blinds": {"type": "string"}
    }
  },
  "player_profile": {
    "required": ["name", "country"],
    "properties": {
      "name": {"type": "string"},
      "country": {"type": "string"},
      "country_code": {"type": "string", "pattern": "^[A-Z]{2}$"},
      "achievement": {"type": "string"},
      "ranking_info": {"type": "string"},
      "prize_info": {"type": "string"}
    }
  }
}
```

---

## 7. 상금 구조 (payout 시트)

### 7.1 스키마 정의

```typescript
interface PayoutStructure {
  total_prize_pool: number;
  buy_in: number;
  entries: number;
  places_paid: number;
  payouts: PayoutTier[];
}

interface PayoutTier {
  placement_from: number;
  placement_to: number;
  amount: number;
  count: number;
}
```

### 7.2 실제 데이터

```json
{
  "total_prize_pool": 6860000,
  "buy_in": 5300,
  "entries": 1372,
  "places_paid": 206,
  "payouts": [
    {"placement_from": 1, "placement_to": 1, "amount": 1000000, "count": 1},
    {"placement_from": 2, "placement_to": 2, "amount": 670000, "count": 1},
    {"placement_from": 3, "placement_to": 3, "amount": 475000, "count": 1},
    {"placement_from": 4, "placement_to": 4, "amount": 345000, "count": 1},
    {"placement_from": 5, "placement_to": 5, "amount": 250000, "count": 1},
    {"placement_from": 6, "placement_to": 6, "amount": 185000, "count": 1},
    {"placement_from": 7, "placement_to": 7, "amount": 140000, "count": 1},
    {"placement_from": 8, "placement_to": 8, "amount": 107500, "count": 1},
    {"placement_from": 9, "placement_to": 9, "amount": 82000, "count": 1},
    {"placement_from": 10, "placement_to": 11, "amount": 64500, "count": 2},
    {"placement_from": 12, "placement_to": 15, "amount": 50400, "count": 4},
    {"placement_from": 16, "placement_to": 23, "amount": 40800, "count": 8},
    {"placement_from": 24, "placement_to": 31, "amount": 33400, "count": 8},
    {"placement_from": 32, "placement_to": 39, "amount": 27700, "count": 8},
    {"placement_from": 40, "placement_to": 47, "amount": 23400, "count": 8},
    {"placement_from": 48, "placement_to": 55, "amount": 20100, "count": 8},
    {"placement_from": 56, "placement_to": 63, "amount": 17500, "count": 8},
    {"placement_from": 64, "placement_to": 71, "amount": 15400, "count": 8},
    {"placement_from": 72, "placement_to": 79, "amount": 13800, "count": 8},
    {"placement_from": 80, "placement_to": 99, "amount": 12500, "count": 20},
    {"placement_from": 100, "placement_to": 117, "amount": 11400, "count": 18},
    {"placement_from": 118, "placement_to": 135, "amount": 10800, "count": 18},
    {"placement_from": 136, "placement_to": 206, "amount": 10500, "count": 71}
  ]
}
```

---

## 8. 시간대 및 포맷 변환

### 8.1 시간대 변환

```python
from datetime import time, timedelta

def cyprus_to_seoul(cyprus_time: time) -> time:
    """키프로스 시간 → 서울 시간 (여름 기준 +6시간)"""
    hours = cyprus_time.hour + 6
    if hours >= 24:
        hours -= 24
    return time(hours, cyprus_time.minute, cyprus_time.second)
```

### 8.2 칩 수량 포맷팅

```python
def format_chips(chips: int) -> str:
    """칩 수량 포맷팅"""
    if chips >= 1000000:
        return f"{chips / 1000000:.1f}M"
    elif chips >= 1000:
        return f"{chips / 1000:.0f}K"
    return str(chips)

# 예: 2145000 → "2.1M"
# 예: 345000 → "345K"
```

### 8.3 블라인드 파싱

```python
import re

def parse_blinds(blinds_str: str) -> dict:
    """블라인드 문자열 파싱"""
    # "6K/12K - 12K (BB)" 또는 "1K/2K - 2K (BB)"
    pattern = r'^(\d+[KM]?)/(\d+[KM]?)\s*-?\s*(\d+[KM]?)?\s*\(?BB\)?$'
    if match := re.match(pattern, blinds_str, re.IGNORECASE):
        return {
            "small_blind": match.group(1),
            "big_blind": match.group(2),
            "ante": match.group(3)
        }
    return {"raw": blinds_str}
```

---

## 9. 신규 필드 추가 (마이그레이션)

```sql
-- cue_items 테이블에 신규 필드 추가
ALTER TABLE cue_items ADD COLUMN IF NOT EXISTS field_count INTEGER;
ALTER TABLE cue_items ADD COLUMN IF NOT EXISTS seoul_time TIME;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_cue_items_field_count
ON cue_items(field_count) WHERE field_count IS NOT NULL;

-- 코멘트 추가
COMMENT ON COLUMN cue_items.field_count IS '해당 시점 남은 플레이어 수';
COMMENT ON COLUMN cue_items.seoul_time IS '서울 시간 (KST, UTC+9)';
```

---

## 10. 검증 쿼리

### 10.1 블록 통계 검증

```sql
-- 블록별 핸드 수 합계 검증
SELECT
  (block_stats->'totals'->>'total_hands')::int as json_total,
  (SELECT COUNT(*) FROM cue_items WHERE sheet_id = cs.id) as actual_count
FROM broadcast_sessions bs
JOIN cue_sheets cs ON cs.session_id = bs.id
WHERE cs.sheet_type = 'main_show';
```

### 10.2 GFX 데이터 스키마 검증

```sql
-- Mini Chip Table 필수 필드 검증
SELECT id, gfx_data
FROM cue_items
WHERE cue_type = 'mini_chip_table'
AND (
  gfx_data->>'table_no' IS NULL
  OR gfx_data->'players' IS NULL
  OR gfx_data->>'blinds' IS NULL
);
```

---

**문서 작성**: Claude Code
**검증**: WSOP SC Cyprus ME Day 3 실제 데이터 기반
