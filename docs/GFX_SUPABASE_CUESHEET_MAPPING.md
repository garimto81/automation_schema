# GFX JSON → Supabase → Cuesheet 통합 매핑 문서

**Version**: 1.5.0
**Date**: 2026-01-19
**Status**: Active

### Changelog
- **v1.5.0** (2026-01-19): 데이터 소스 수정 - table_no 경로 추출, LongName 대문자, Leaderboard rank 칩순 계산, WSOP+ 통합 제공 반영
- **v1.4.0** (2026-01-19): 국가 정보 소스 확정 (WSOP+ 제공)
- **v1.3.0** (2026-01-19): Appendix C gfx_data 키 상세 매핑 추가
- **v1.2.0** (2026-01-19): Appendix F Cuesheet 변환 스크립트 명세 추가
- **v1.1.0** (2026-01-19): Appendix C-E 3계층 비교, 미제공 데이터, 검증 체크리스트 추가

---

## 1. 개요

### 1.1 목적

3계층 데이터 구조(GFX JSON → Supabase DB → Cuesheet)의 무결한 연결을 정의합니다.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    3계층 데이터 매핑 아키텍처                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Layer 1: GFX JSON │     │  Layer 2: Supabase  │     │  Layer 3: Cuesheet  │
│   (원본 데이터)       │────▶│   (중앙 저장소)       │────▶│   (방송 출력)        │
├─────────────────────┤     ├─────────────────────┤     ├─────────────────────┤
│ • PokerGFX 파일     │     │ • gfx_sessions      │     │ • broadcast_sessions│
│ • RFID 실시간 데이터 │     │ • gfx_hands         │     │ • cue_sheets        │
│ • 핸드 히스토리      │     │ • gfx_hand_players  │     │ • cue_items         │
│ • 플레이어 통계      │     │ • gfx_events        │     │ • gfx_triggers      │
│                     │     │ • unified_* views   │     │ • cue_templates     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
         │                           │                           │
         │  NAS 동기화               │  AEP 렌더링                │
         └───────────────────────────┼───────────────────────────┘
                                     │
                                     ▼
                            ┌─────────────────────┐
                            │     AEP 출력        │
                            │   (26개 컴포지션)    │
                            └─────────────────────┘
```

### 1.2 SSOT 정책

| 계층 | SSOT | 역할 |
|:----:|------|------|
| 1 | `supabase/migrations/*.sql` | 스키마 정의 (진실의 소스) |
| 2 | `docs/**/*.md` | 설계/참조 문서 |
| 3 | 실제 DB (Supabase) | 런타임 데이터 저장 |

> **원칙**: 마이그레이션과 문서가 다르면 **마이그레이션이 정답**

---

## 2. Layer 1 → Layer 2: GFX JSON → Supabase 매핑

### 2.1 핵심 매핑 테이블

#### 2.1.1 Session Level

| GFX JSON 필드 | Supabase 컬럼 | 변환 규칙 |
|---------------|---------------|-----------|
| `ID` | `gfx_sessions.session_id` | int64 → BIGINT |
| `CreatedDateTimeUTC` | `gfx_sessions.session_created_at` | ISO 8601 → TIMESTAMPTZ |
| `Type` | `gfx_sessions.table_type` | string → ENUM |
| `EventTitle` | `gfx_sessions.event_title` | string → TEXT |
| `SoftwareVersion` | `gfx_sessions.software_version` | string → TEXT |
| `Payouts` | `gfx_sessions.payouts` | int[10] → INTEGER[] |
| `Hands.length` | `gfx_sessions.hand_count` | 계산값 |
| *파일명* | `gfx_sessions.file_name` | 파서 추출 |
| *SHA256* | `gfx_sessions.file_hash` | 파서 계산 |
| *전체 JSON* | `gfx_sessions.raw_json` | JSONB 원본 보존 |

#### 2.1.2 Hand Level

| GFX JSON 필드 | Supabase 컬럼 | 변환 규칙 |
|---------------|---------------|-----------|
| `HandNum` | `gfx_hands.hand_num` | int → INTEGER |
| `Duration` | `gfx_hands.duration_seconds` | ISO 8601 Duration → INTEGER (초) |
| `StartDateTimeUTC` | `gfx_hands.start_time` | ISO 8601 → TIMESTAMPTZ |
| `RecordingOffsetStart` | `gfx_hands.recording_offset_iso` | 원본 보존 |
| `RecordingOffsetStart` | `gfx_hands.recording_offset_seconds` | 파싱 → BIGINT |
| `GameVariant` | `gfx_hands.game_variant` | ENUM: 'HOLDEM' |
| `BetStructure` | `gfx_hands.bet_structure` | ENUM: 'NOLIMIT' |
| `AnteAmt` | `gfx_hands.ante_amt` | int → BIGINT |
| `FlopDrawBlinds` | `gfx_hands.blinds` | object → JSONB |
| `Events[-1].Pot` | `gfx_hands.pot_size` | 마지막 이벤트 Pot |

#### 2.1.3 Player Level

| GFX JSON 필드 | Supabase 컬럼 | 변환 규칙 |
|---------------|---------------|-----------|
| `PlayerNum` | `gfx_hand_players.seat_num` | int → INTEGER (CHECK 1-10) |
| `Name` | `gfx_hand_players.player_name` | string → TEXT |
| `LongName` | `gfx_players.long_name` | 마스터 테이블 참조 |
| `HoleCards` | `gfx_hand_players.hole_cards` | **`["10d 9d"]` → `["10d", "9d"]`** |
| `StartStackAmt` | `gfx_hand_players.start_stack_amt` | int → BIGINT |
| `EndStackAmt` | `gfx_hand_players.end_stack_amt` | int → BIGINT |
| `VPIPPercent` | `gfx_hand_players.vpip_percent` | float → NUMERIC(5,2) |

#### 2.1.4 Event Level

| GFX JSON 필드 | Supabase 컬럼 | 변환 규칙 |
|---------------|---------------|-----------|
| `EventType` | `gfx_events.event_type` | **`"ALL IN"` → `ALL_IN`** |
| `PlayerNum` | `gfx_events.player_num` | int → INTEGER (0=board) |
| `BetAmt` | `gfx_events.bet_amt` | int → BIGINT |
| `Pot` | `gfx_events.pot` | int → BIGINT |
| `BoardCards` | `gfx_events.board_cards` | string → TEXT |

### 2.2 중요 변환 규칙

```python
# EventType 공백 → 언더스코어 변환
EVENT_TYPE_MAP = {
    "FOLD": "FOLD",
    "CHECK": "CHECK",
    "CALL": "CALL",
    "BET": "BET",
    "RAISE": "RAISE",
    "ALL IN": "ALL_IN",        # ⚠️ 공백 포함
    "BOARD CARD": "BOARD_CARD" # ⚠️ 공백 포함
}

# HoleCards 파싱 (공백 분리)
def parse_hole_cards(cards: list[str]) -> list[str]:
    if not cards or cards[0] == "":
        return []
    return cards[0].split()  # "10d 9d" → ["10d", "9d"]

# Duration ISO 8601 파싱
def parse_duration(duration: str) -> int:
    # "PT35M37.2477537S" → 2137 (초)
    total = 0
    if m := re.search(r'(\d+(?:\.\d+)?)M', duration):
        total += float(m.group(1)) * 60
    if m := re.search(r'(\d+(?:\.\d+)?)S', duration):
        total += float(m.group(1))
    return int(total)
```

---

## 3. Layer 2 → Layer 3: Supabase → Cuesheet 매핑

### 3.1 통합 뷰 활용

Cuesheet는 Supabase의 **통합 뷰(Unified Views)**를 통해 데이터를 조회합니다.

```sql
-- 플레이어 데이터 통합 조회
SELECT * FROM unified_players;

-- 칩 데이터 통합 조회
SELECT * FROM unified_chip_data;

-- 이벤트 데이터 통합 조회
SELECT * FROM unified_events;
```

### 3.2 핵심 매핑 테이블

#### 3.2.1 Session → Broadcast Session

| Supabase (통합 뷰) | Cuesheet DB | 변환 규칙 |
|-------------------|-------------|-----------|
| `unified_events.source_id` | `broadcast_sessions.event_id` | UUID 참조 |
| `unified_events.name` | `broadcast_sessions.event_name` | 직접 매핑 |
| `unified_events.start_date` | `broadcast_sessions.broadcast_date` | DATE |
| *별도 입력* | `broadcast_sessions.session_code` | "WSOP-2024-ME-D3" 형식 |
| *별도 입력* | `broadcast_sessions.block_stats` | JSONB (아래 참조) |

#### 3.2.2 Chip Data → cue_items.gfx_data

| Supabase 컬럼 | Cuesheet gfx_data 키 | 용도 |
|---------------|---------------------|------|
| `unified_chip_data.player_name` | `players[].name` | Mini Chip Table |
| `unified_chip_data.chip_count` | `players[].chips` | 칩 표시 |
| `unified_chip_data.rank` | `players[].rank` | Leaderboard |
| `unified_chip_data.country_code` | `players[].country_code` | 국가 표시 |

#### 3.2.3 Hand Data → cue_items

| Supabase 컬럼 | Cuesheet 컬럼 | 용도 |
|---------------|--------------|------|
| `gfx_hands.hand_num` | `cue_items.hand_number` | 핸드 번호 |
| `gfx_hands.pot_size` | `cue_items.gfx_data.pot_size` | 팟 크기 표시 |
| `gfx_hands.blinds` | `cue_items.blind_level` | 블라인드 정보 |
| `gfx_hands.board_cards` | `cue_items.gfx_data.board` | 보드 카드 |

### 3.3 GFX Template 매핑

| Cuesheet Template | Supabase 데이터 소스 | AEP 컴포지션 |
|-------------------|---------------------|--------------|
| `mini_chip_left` | `unified_chip_data` | MiniChipTable_L |
| `mini_chip_right` | `unified_chip_data` | MiniChipTable_R |
| `leaderboard` | `unified_chip_data` | ChipCount_Leaderboard |
| `player_profile` | `gfx_players` + `player_overrides` | L3_Profile |
| `elimination` | `gfx_hand_players.elimination_rank` | Elimination_GFX |
| `vpip` | `gfx_hand_players.vpip_percent` | VPIP_Stats |
| `chip_flow` | `gfx_hand_players` (다중 핸드) | ChipFlow_Graph |

---

## 4. 데이터 흐름 상세

### 4.1 실시간 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         실시간 데이터 파이프라인                               │
└─────────────────────────────────────────────────────────────────────────────┘

  [PokerGFX/RFID]            [NAS Storage]           [Supabase DB]
       │                          │                       │
       │  1. JSON 생성            │                       │
       ├─────────────────────────▶│                       │
       │                          │  2. 파일 동기화        │
       │                          ├──────────────────────▶│
       │                          │                       │
       │                          │       ┌───────────────┴───────────────┐
       │                          │       │                               │
       │                          │       ▼                               ▼
       │                          │  [gfx_sessions]               [gfx_hands]
       │                          │       │                               │
       │                          │       │                               │
       │                          │       ▼                               ▼
       │                          │  [gfx_players]            [gfx_hand_players]
       │                          │       │                               │
       │                          │       └───────────────┬───────────────┘
       │                          │                       │
       │                          │                       ▼
       │                          │               [unified_* views]
       │                          │                       │
       │                          │                       │ 3. 통합 조회
       │                          │                       ▼
       │                          │               [Cuesheet System]
       │                          │                       │
       │                          │                       │ 4. GFX 트리거
       │                          │                       ▼
       │                          │                  [AEP 렌더링]
```

### 4.2 칩카운트 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         칩카운트 데이터 소스 매핑                             │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │   unified_chip_data │
                    │     (통합 뷰)        │
                    └──────────┬──────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ wsop_chip_counts│  │ gfx_hand_players│  │     (삭제됨)     │
│  (WSOP+ 공식)   │  │  (GFX 실시간)   │  │ chip_snapshots  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                    │
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ 토너먼트 공식    │  │ 핸드별 실시간    │
│ 칩 카운트       │  │ 스택 변동       │
└─────────────────┘  └─────────────────┘

※ chip_snapshots 테이블 삭제됨 (2026-01-16)
  → wsop_chip_counts / gfx_hand_players 직접 조회
```

---

## 5. GFX Template별 데이터 매핑

### 5.1 Mini Chip Table

**데이터 소스 체인:**
```
gfx_hand_players → unified_chip_data → cue_items.gfx_data → MiniChipTable AEP
```

**매핑 스키마:**
```typescript
interface MiniChipTable {
  position: "LEFT" | "RIGHT";
  table_no: number;
  players: Array<{
    name: string;           // ← gfx_hand_players.player_name
    chips: number;          // ← gfx_hand_players.end_stack_amt
    is_winner?: boolean;    // ← gfx_hand_players.is_winner
  }>;
  blinds: string;           // ← gfx_hands.blinds JSONB
}
```

### 5.2 Leaderboard

**데이터 소스 체인:**
```
wsop_chip_counts → unified_chip_data → cue_items.gfx_data → Leaderboard AEP
```

**매핑 스키마:**
```typescript
interface Leaderboard {
  title: string;
  players_remaining: number;
  avg_stack: number;
  players: Array<{
    rank: number;           // ← wsop_chip_counts.rank
    name: string;           // ← wsop_players.name
    country: string;        // ← wsop_players.country_code
    chips: number;          // ← wsop_chip_counts.chip_count
    bb: number;             // ← 계산: chips / big_blind
  }>;
}
```

### 5.3 Player Profile (L3_Profile)

**데이터 소스 체인:**
```
gfx_players + player_overrides + profile_images → cue_items.gfx_data → L3_Profile AEP
```

**매핑 스키마:**
```typescript
interface PlayerProfile {
  name: string;             // ← gfx_players.name (+ player_overrides.display_name)
  country: string;          // ← player_overrides.nationality (우선) 또는 추론
  country_code: string;     // ← ISO 2자리 코드
  profile_image: string;    // ← profile_images.file_path
  achievement: string;      // ← player_overrides.bio
  chips?: number;           // ← gfx_hand_players.end_stack_amt
  wsop_bracelets?: number;  // ← wsop_players 또는 player_overrides
}
```

### 5.4 Elimination

**데이터 소스 체인:**
```
gfx_hand_players (elimination_rank) → cue_items.gfx_data → Elimination AEP
```

**매핑 스키마:**
```typescript
interface Elimination {
  player_name: string;      // ← gfx_hand_players.player_name
  country: string;          // ← player_overrides 또는 추론
  placement: string;        // ← gfx_hand_players.elimination_rank → "42ND"
  prize: number;            // ← payout 시트 참조
  hand_description: string; // ← gfx_hands 분석 (예: "KK vs JJ")
  eliminator?: string;      // ← 핸드 분석으로 추론
}
```

### 5.5 VPIP Stats

**데이터 소스 체인:**
```
gfx_hand_players (vpip_percent) → cue_items.gfx_data → VPIP AEP
```

**매핑 스키마:**
```typescript
interface VPIP {
  player_name: string;      // ← gfx_hand_players.player_name
  country: string;          // ← player_overrides
  vpip_percent: number;     // ← gfx_hand_players.vpip_percent
  sample_hands: number;     // ← 핸드 카운트
}
```

---

## 6. 데이터 무결성 검증

### 6.1 Layer 간 FK 관계

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Cross-Layer FK 관계도                              │
└─────────────────────────────────────────────────────────────────────────────┘

Layer 1 (GFX)                Layer 2 (Supabase)              Layer 3 (Cuesheet)
─────────────                ──────────────────              ──────────────────

gfx_sessions.session_id ────▶ gfx_hands.session_id
                              │
                              └────▶ gfx_hand_players.hand_id
                                     │
                                     └────▶ gfx_players.id (FK)

                              unified_events ──────────────▶ broadcast_sessions.event_id
                                                            │
                                                            └─▶ cue_sheets.session_id
                                                                │
                                                                └─▶ cue_items.sheet_id
                                                                    │
                                                                    └─▶ gfx_triggers.cue_item_id

wsop_events.id ────────────────────────────────────────────▶ broadcast_sessions.event_id (Soft FK)
```

### 6.2 검증 쿼리

```sql
-- 1. GFX Session → Hands 무결성
SELECT COUNT(*) AS orphan_hands
FROM gfx_hands h
LEFT JOIN gfx_sessions s ON h.session_id = s.session_id
WHERE s.id IS NULL;

-- 2. Hand → Players 무결성
SELECT COUNT(*) AS orphan_players
FROM gfx_hand_players hp
LEFT JOIN gfx_hands h ON hp.hand_id = h.id
WHERE h.id IS NULL;

-- 3. Cuesheet → Broadcast Session 무결성
SELECT COUNT(*) AS orphan_sheets
FROM cue_sheets cs
LEFT JOIN broadcast_sessions bs ON cs.session_id = bs.id
WHERE bs.id IS NULL;

-- 4. Cue Item → Template 무결성
SELECT COUNT(*) AS orphan_items
FROM cue_items ci
LEFT JOIN cue_templates ct ON ci.template_id = ct.id
WHERE ci.template_id IS NOT NULL AND ct.id IS NULL;
```

### 6.3 데이터 타입 일관성

| 필드 유형 | GFX JSON | Supabase | Cuesheet |
|----------|----------|----------|----------|
| 칩 금액 | int64 | **BIGINT** | BIGINT |
| 시간 | ISO 8601 | TIMESTAMPTZ | TIMESTAMPTZ |
| Duration | ISO 8601 Duration | INTEGER (초) | INTEGER |
| 플레이어 ID | N/A | UUID | UUID (FK) |
| 시트 번호 | int (1-10) | INTEGER CHECK (1-10) | INTEGER |

---

## 7. 동기화 전략

### 7.1 동기화 방향

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          동기화 방향 및 트리거                               │
└─────────────────────────────────────────────────────────────────────────────┘

                         단방향 동기화
GFX JSON ─────────────────────────────────────────▶ Supabase DB
   │                                                    │
   │  NAS 파일 감시 (watchdog)                         │
   │  sync_status 추적                                 │
   │                                                    │
   └────────────────────────────────────────────────────┤
                                                        │
                                                        ▼
                                                  Cuesheet 조회
                                                  (읽기 전용)
```

### 7.2 sync_status 매핑

```sql
-- 초기 동기화 상태
INSERT INTO sync_status (source, entity_type, status, sync_interval_minutes) VALUES
('gfx', 'sessions', 'pending', 60),
('gfx', 'hands', 'pending', 60),
('gfx', 'players', 'pending', 60),
('wsop', 'events', 'pending', 30),
('wsop', 'players', 'pending', 30),
('wsop', 'chip_counts', 'pending', 15),
('cuesheet', 'broadcast_sessions', 'pending', 60),
('cuesheet', 'cue_sheets', 'pending', 60),
('cuesheet', 'cue_items', 'pending', 30);
```

---

## 8. 오류 처리 및 복구

### 8.1 Layer 1 오류 (GFX JSON)

| 오류 유형 | 원인 | 복구 방법 |
|----------|------|----------|
| 파싱 실패 | 잘못된 JSON 형식 | `sync_log.error_message`에 기록, 재시도 |
| 중복 세션 | 동일 file_hash | UPSERT (ON CONFLICT UPDATE) |
| 누락 필드 | JSON 버전 차이 | DEFAULT 값 적용 |

### 8.2 Layer 2 오류 (Supabase)

| 오류 유형 | 원인 | 복구 방법 |
|----------|------|----------|
| FK 위반 | 참조 대상 미존재 | 부모 레코드 먼저 INSERT |
| 타입 불일치 | 잘못된 변환 | 로그 기록, 수동 검토 |
| RLS 차단 | 권한 부족 | service_role 사용 |

### 8.3 Layer 3 오류 (Cuesheet)

| 오류 유형 | 원인 | 복구 방법 |
|----------|------|----------|
| 템플릿 누락 | template_id 불일치 | ON DELETE SET NULL |
| GFX 데이터 불완전 | 필수 필드 누락 | 기본값 또는 경고 |
| 렌더링 실패 | AEP 오류 | `gfx_triggers.error_message` |

---

## 9. 관련 문서

| 문서 | 경로 | 역할 |
|------|------|------|
| GFX JSON 스키마 | `docs/gfx-json/02-GFX-JSON-DB.md` | Layer 1 정의 |
| Supabase 오케스트레이션 | `docs/supabase/07-Supabase-Orchestration.md` | Layer 2 정의 |
| Cuesheet 스키마 | `docs/cuesheet/05-Cuesheet-DB.md` | Layer 3 정의 |
| Cuesheet JSON 매핑 | `docs/cuesheet/CUESHEET_JSON_MAPPING.md` | gfx_data 상세 |
| GFX-AEP 매핑 | `docs/ae/08-GFX-AEP-Mapping.md` | AEP 컴포지션 연결 |
| DB 동기화 가이드 | `docs/supabase/09-DB-Sync-Guidelines.md` | 동기화 정책 |

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-01-19 | 초기 작성: 3계층 매핑 정의 |
| 1.1.0 | 2026-01-19 | Appendix C-E 추가: 실제 샘플 데이터 기반 3계층 직관적 매핑, GFX JSON 미제공 데이터 목록 |
| 1.2.0 | 2026-01-19 | Appendix F 추가: Cuesheet gfx_data 변환 전략 및 스크립트 명세 |
| 1.3.0 | 2026-01-19 | Appendix C 전면 개편: GFX 템플릿별 완전 매핑 (gfx_data 키/값 상세), 데이터 소스 명시 |
| 1.4.0 | 2026-01-19 | 국가 정보 소스 수정: GFX JSON에 없음 → PokerCaster chipcount 시트 (Nationality 컬럼) |

---

## Appendix A: 데이터 소스 우선순위

### A.1 플레이어 정보

```
1. player_overrides (Manual)      ← 최우선: 수동 보정
2. wsop_players (WSOP+)           ← 공식 토너먼트 데이터
3. gfx_players (GFX)              ← 실시간 추출 데이터
```

### A.2 칩 카운트

```
1. gfx_hand_players.end_stack_amt ← 핸드 종료 시점 정확한 스택
2. wsop_chip_counts.chip_count    ← 토너먼트 공식 칩카운트
```

### A.3 이벤트/세션 정보

```
1. wsop_events (WSOP+)            ← 공식 토너먼트 메타
2. gfx_sessions (GFX)             ← 방송 세션 추출
3. broadcast_sessions (Cuesheet)  ← 방송 제작 입력
```

---

## Appendix B: 검증 스크립트

```python
# scripts/validate_layer_mapping.py

import asyncio
from supabase import create_client

async def validate_gfx_to_supabase():
    """Layer 1 → Layer 2 무결성 검증"""
    # orphan hands 체크
    result = await supabase.rpc('check_orphan_hands').execute()
    assert result.data[0]['count'] == 0, "Orphan hands detected!"

async def validate_supabase_to_cuesheet():
    """Layer 2 → Layer 3 무결성 검증"""
    # orphan cue_sheets 체크
    result = await supabase.rpc('check_orphan_sheets').execute()
    assert result.data[0]['count'] == 0, "Orphan sheets detected!"

async def validate_all_layers():
    """전체 계층 무결성 검증"""
    await validate_gfx_to_supabase()
    await validate_supabase_to_cuesheet()
    print("All layer mappings validated successfully!")
```

---

## Appendix C: 3계층 직관적 매핑 테이블 (실제 샘플 데이터 + gfx_data 상세)

> **목적**: GFX JSON 실제 데이터 → Supabase 저장 → Cuesheet `gfx_data` JSONB 필드 매핑을 **정확하게** 확인

### C.1 GFX 템플릿별 완전 매핑 (핵심)

> **데이터 소스 범례**:
> - ✅ **GFX**: PokerGFX JSON에서 직접 수집
> - 🌐 **WSOP+**: WSOP+ 시스템에서 제공 (국가, 이미지, 성취 등)
> - 🔄 **계산**: 수집 데이터 기반 계산
> - 📁 **경로**: 파일 경로에서 추출

#### C.1.1 MiniChipTable (mini_chip_left / mini_chip_right)

**샘플 GFX JSON → Supabase → gfx_data 완전 매핑:**

| 데이터 소스 | GFX JSON 필드 | 샘플 값 | Supabase 컬럼 | gfx_data 키 | gfx_data 샘플 값 |
|:-----------:|---------------|---------|---------------|-------------|------------------|
| ✅ GFX | `Hand.HandNum` | `1` | `gfx_hands.hand_num` | - | (cue_items.hand_number) |
| ✅ GFX | `FlopDrawBlinds.*` | `{sb:20K,bb:40K,ante:40K}` | `gfx_hands.blinds` | `blinds` | `"20K/40K - 40K (BB)"` |
| ✅ GFX | `Players[].PlayerNum` | `1` | `gfx_hand_players.seat_num` | `players[].seat` | `1` |
| ✅ GFX | `Players[].LongName` | `Konstantin Voronin` | `gfx_hand_players.player_name` | `players[].name` | `"KONSTANTIN VORONIN"` ⬆️ |
| ✅ GFX | `Players[].EndStackAmt` | `1585000` | `gfx_hand_players.end_stack_amt` | `players[].chips` | `1585000` |
| ✅ GFX | `Players[].IsWinner` | `false` | `gfx_hand_players.is_winner` | `players[].is_winner` | `false` |
| 📁 경로 | *파일 경로* | `table-GG/1019/...` | `gfx_sessions.table_name` | `table_no` | `"GG"` (경로에서 추출) |
| 수동 | - | - | - | `position` | `"LEFT"` / `"RIGHT"` |

> **📁 table_no 추출 로직**: 파일 경로 `gfx_json_data/table-{테이블명}/...`에서 테이블명 추출
> **⬆️ player name**: `LongName` 필드를 대문자로 변환하여 사용

**완성된 gfx_data 예시:**
```json
{
  "position": "LEFT",
  "table_no": "GG",
  "blinds": "20K/40K - 40K (BB)",
  "players": [
    {"name": "KONSTANTIN VORONIN", "chips": 1585000, "is_winner": false},
    {"name": "TOSOC", "chips": 2080000, "is_winner": false},
    {"name": "LUDOVIC GEILICH", "chips": 3735000, "is_winner": false},
    {"name": "RYAN LENG", "chips": 2950000, "is_winner": true}
  ]
}
```

---

#### C.1.2 Leaderboard (Feature Table 기준)

> **핵심**: Leaderboard는 **Feature Table의 플레이어 칩 정보**를 기준으로 생성
> rank는 칩 크기 순으로 **자동 계산** (별도 순위 데이터 불필요)

**샘플 데이터 → Supabase → gfx_data 완전 매핑:**

| 데이터 소스 | 필드 | 샘플 값 | Supabase 컬럼 | gfx_data 키 | gfx_data 샘플 값 |
|:-----------:|------|---------|---------------|-------------|------------------|
| 🔄 계산 | - | - | ORDER BY chips DESC | `players[].rank` | `1, 2, 3...` (칩 순) |
| ✅ GFX | `Players[].LongName` | `Konstantin Voronin` | `gfx_hand_players.player_name` | `players[].name` | `"KONSTANTIN VORONIN"` ⬆️ |
| 🌐 WSOP+ | - | `Russia` | `wsop_players.nationality` | `players[].country` | `"Russia"` |
| 🌐 WSOP+ | - | `RU` | `wsop_players.country_code` | `players[].country_code` | `"RU"` |
| ✅ GFX | `Players[].EndStackAmt` | `5940000` | `gfx_hand_players.end_stack_amt` | `players[].chips` | `5940000` |
| 🔄 계산 | - | - | chips / big_blind | `players[].bb` | `148` |
| 🔄 계산 | - | - | COUNT(players) | `players_remaining` | `9` |
| 🔄 계산 | - | - | SUM(chips) / COUNT | `avg_stack` | `2625000` |
| 수동 | - | - | - | `title` | `"Feature Table"` |

> **🔄 rank 계산**: GFX Feature Table 플레이어들의 `EndStackAmt`를 높은 순으로 정렬하여 rank 부여
> **🌐 국가 정보**: WSOP+에서 플레이어-국가 매핑 테이블 제공

**완성된 gfx_data 예시:**
```json
{
  "title": "Feature Table - Day 3",
  "players_remaining": 9,
  "avg_stack": 2847222,
  "players": [
    {"rank": 1, "name": "ALEX FOXEN", "country": "USA", "country_code": "US", "chips": 5940000, "bb": 148},
    {"rank": 2, "name": "LUDOVIC GEILICH", "country": "UK", "country_code": "GB", "chips": 3735000, "bb": 93},
    {"rank": 3, "name": "KORAY ALDEMIR", "country": "Germany", "country_code": "DE", "chips": 3580000, "bb": 89}
  ]
}
```

**✅ GFX만으로 Leaderboard 생성 가능** (국가 정보는 WSOP+ 매핑 테이블 필요)

---

#### C.1.3 PlayerProfile (L3_Profile) - WSOP+ 제공

> **핵심**: PlayerProfile은 **WSOP+**에서 제공
> GFX에 등장하는 모든 플레이어는 WSOP+에서도 정보 제공됨

**샘플 데이터 → Supabase → gfx_data 완전 매핑:**

| 데이터 소스 | 필드 | 샘플 값 | Supabase 컬럼 | gfx_data 키 | gfx_data 샘플 값 |
|:-----------:|------|---------|---------------|-------------|------------------|
| 🌐 WSOP+ | 플레이어명 | `Konstantin Voronin` | `wsop_players.name` | `name` | `"KONSTANTIN VORONIN"` ⬆️ |
| 🌐 WSOP+ | 국적 | `Russia` | `wsop_players.nationality` | `country` | `"Russia"` |
| 🌐 WSOP+ | 국가코드 | `RU` | `wsop_players.country_code` | `country_code` | `"RU"` |
| 🌐 WSOP+ | 프로필 이미지 | `voronin.jpg` | `wsop_players.profile_image` | `profile_image` | `"/images/voronin.jpg"` |
| 🌐 WSOP+ | 성취 | `WSOP Winner` | `wsop_players.achievement` | `achievement` | `"WSOP BRACELET WINNER"` |
| 🌐 WSOP+ | 총 상금 | `2084179` | `wsop_players.total_earnings` | `prize_info` | `"$2,084,179"` |
| 🌐 WSOP+ | 브레이슬릿 | `1` | `wsop_players.bracelets` | `wsop_bracelets` | `1` |
| ✅ GFX | `EndStackAmt` | `1585000` | `gfx_hand_players.end_stack_amt` | `chips` | `1585000` (옵션) |

**완성된 gfx_data 예시:**
```json
{
  "name": "KONSTANTIN VORONIN",
  "country": "Russia",
  "country_code": "RU",
  "profile_image": "/images/players/voronin.jpg",
  "achievement": "WSOP BRACELET WINNER",
  "ranking_info": "3RD ON RUSSIA ALL TIME MONEY LIST",
  "prize_info": "$2,084,179",
  "wsop_bracelets": 1,
  "chips": 1585000
}
```

**✅ PlayerProfile은 WSOP+에서 모든 정보 제공** (GFX 칩 정보는 보조)

---

#### C.1.4 Elimination - WSOP+ 제공

> **핵심**: Elimination 정보도 **WSOP+**에서 제공
> GFX에 겹치는 정보가 있지만, 모든 GFX 등록 플레이어는 WSOP+에서도 제공됨

**샘플 데이터 → Supabase → gfx_data 완전 매핑:**

| 데이터 소스 | 필드 | 샘플 값 | Supabase 컬럼 | gfx_data 키 | gfx_data 샘플 값 |
|:-----------:|------|---------|---------------|-------------|------------------|
| 🌐 WSOP+ | 플레이어명 | `Oliver Weis` | `wsop_players.name` | `player_name` | `"OLIVER WEIS"` ⬆️ |
| 🌐 WSOP+ | 국적 | `Germany` | `wsop_players.nationality` | `country` | `"Germany"` |
| 🌐 WSOP+ | 국가코드 | `DE` | `wsop_players.country_code` | `country_code` | `"DE"` |
| 🌐 WSOP+ | 순위 | `52` | `wsop_eliminations.placement` | `placement` | `"52ND"` 🔄서수 변환 |
| 🌐 WSOP+ | 상금 | `17500` | `wsop_events.payout_structure[52]` | `prize` | `17500` |
| ✅ GFX | `HoleCards` | `["Kd Kh"]` | `gfx_hand_players.hole_cards` | `hand_description` | `"KK vs JJ - River J"` 🔄분석 |
| ✅ GFX | `IsWinner=true` | `Spataru` | `gfx_hand_players` | `eliminator` | `"SPATARU"` 🔄분석 |

**완성된 gfx_data 예시:**
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

**✅ Elimination은 WSOP+에서 제공** (핸드 분석만 GFX 활용)

---

#### C.1.5 VPIP Stats - GFX 전용

> **핵심**: VPIP Stats는 **GFX에 등장하는 플레이어만** 정보 제공
> GFX JSON의 `VPIPPercent` 필드 직접 사용

**샘플 데이터 → Supabase → gfx_data 완전 매핑:**

| 데이터 소스 | 필드 | 샘플 값 | Supabase 컬럼 | gfx_data 키 | gfx_data 샘플 값 |
|:-----------:|------|---------|---------------|-------------|------------------|
| ✅ GFX | `Players[].LongName` | `Konstantin Voronin` | `gfx_hand_players.player_name` | `player_name` | `"KONSTANTIN VORONIN"` ⬆️ |
| 🌐 WSOP+ | 국적 | `Russia` | `wsop_players.nationality` | `country` | `"Russia"` |
| 🌐 WSOP+ | 국가코드 | `RU` | `wsop_players.country_code` | `country_code` | `"RU"` |
| ✅ GFX | `Players[].VPIPPercent` | `28.6` | `gfx_hand_players.vpip_percent` | `vpip_percent` | `28.6` |
| 🔄 계산 | - | 50 | COUNT(*) | `sample_hands` | `50` |

**완성된 gfx_data 예시:**
```json
{
  "player_name": "KONSTANTIN VORONIN",
  "country": "Russia",
  "country_code": "RU",
  "vpip_percent": 28.6,
  "sample_hands": 50
}
```

**✅ GFX 전용 데이터** (국가 정보만 WSOP+ 매핑)

---

#### C.1.6 ChipFlow - GFX 전용

> **핵심**: ChipFlow는 **GFX에서 직접 제공**
> 다중 핸드의 `EndStackAmt` 수집으로 칩 변동 추적

| 데이터 소스 | 필드 | 샘플 값 | Supabase 컬럼 | gfx_data 키 | gfx_data 샘플 값 |
|:-----------:|------|---------|---------------|-------------|------------------|
| ✅ GFX | `Players[].LongName` | `Konstantin Voronin` | `gfx_hand_players.player_name` | `player_name` | `"KONSTANTIN VORONIN"` ⬆️ |
| 🌐 WSOP+ | 국적 | `Russia` | `wsop_players.nationality` | `country` | `"Russia"` |
| 🌐 WSOP+ | 국가코드 | `RU` | `wsop_players.country_code` | `country_code` | `"RU"` |
| ✅ GFX | `EndStackAmt` (다중 핸드) | `[1625K, 1585K...]` | `gfx_hand_players.end_stack_amt` | `chip_history` | `[1625000, 1585000...]` |
| 🔄 계산 | - | 20 | COUNT(*) | `period` | `"LAST 20 HANDS"` |
| ✅ GFX | 마지막 핸드 | `1800000` | `gfx_hand_players.end_stack_amt` | `current_chips` | `1800000` |

**완성된 gfx_data 예시:**
```json
{
  "player_name": "KONSTANTIN VORONIN",
  "country": "Russia",
  "country_code": "RU",
  "chip_history": [1625000, 1585000, 1700000, 1650000, 1800000],
  "period": "LAST 20 HANDS",
  "current_chips": 1800000
}
```

**✅ ChipFlow는 GFX에서 직접 제공** (국가 정보만 WSOP+ 매핑)

---

### C.2 GFX 템플릿별 데이터 소스 요약 (수정됨)

| 템플릿 | GFX JSON ✅ | WSOP+ 🌐 | 계산 🔄 | 수동 📝 |
|--------|------------|----------|---------|---------|
| **MiniChipTable** | LongName⬆️, 칩, is_winner, 블라인드 | - | - | position |
| **Leaderboard** | LongName⬆️, 칩 (→rank 계산) | **국가, 국가코드** | rank (칩순), BB, avg_stack | title |
| **PlayerProfile** | (칩 옵션) | **전체** (이름, 국가, 이미지, 성취, 브레이슬릿) | - | - |
| **Elimination** | hole_cards, is_winner | **전체** (이름, 국가, 순위, 상금) | 핸드 분석 | - |
| **VPIP Stats** | LongName⬆️, **vpip_percent** | **국가, 국가코드** | sample_hands | - |
| **ChipFlow** | LongName⬆️, **chip_history** (다중 핸드) | **국가, 국가코드** | period | - |

> **📁 table_no**: 파일 경로 `gfx_json_data/table-{테이블명}/...`에서 추출
> **⬆️ player name**: `LongName` 필드를 **대문자**로 변환
> **🌐 국가 정보**: 모든 템플릿에서 **WSOP+** 플레이어-국가 매핑 테이블 사용
> **🌐 프로필 이미지**: **WSOP+**에서 제공

---

### C.3 변환 규칙 요약

| 변환 유형 | 입력 | 출력 | 예시 |
|----------|------|------|------|
| **이름 (LongName)** | `Konstantin Voronin` | `KONSTANTIN VORONIN` | `LongName.upper()` |
| **table_no 추출** | `gfx_json_data/table-GG/1019/...` | `"GG"` | 경로 파싱 |
| **Leaderboard rank** | 칩 리스트 | `1, 2, 3...` | `ORDER BY chips DESC` |
| **칩 포맷** | `1585000` | `1.6M` 또는 `1585000` | 템플릿에 따라 |
| **블라인드 포맷** | `{sb:20000, bb:40000, ante:40000}` | `"20K/40K - 40K (BB)"` | 결합 + 약어 |
| **순위 서수화** | `52` | `"52ND"` | ST/ND/RD/TH 규칙 |
| **홀카드 파싱** | `["Kd Kh"]` | `["Kd", "Kh"]` | 공백 분리 |
| **핸드 이름** | `["Kd", "Kh"]` | `"KK"` | 카드 분석 |
| **BB 계산** | `chips=1585000, bb=40000` | `40` | `chips // bb` |

---

### C.4 Session/Hand/Player/Event Level 상세 매핑

#### C.4.1 Session Level

| # | GFX JSON 필드 | 샘플 값 | Supabase 컬럼 | Cuesheet 활용 |
|:-:|---------------|---------|---------------|---------------|
| 1 | `ID` | `638964779563363778` | `gfx_sessions.session_id` | broadcast_sessions 연결 |
| 2 | `CreatedDateTimeUTC` | `2025-05-29T02:49:16Z` | `gfx_sessions.session_created_at` | 방송 날짜 |
| 3 | `Type` | `FEATURE_TABLE` | `gfx_sessions.table_type` | 테이블 구분 |
| 4 | `EventTitle` | `` (빈값) | `gfx_sessions.event_title` | ⚠️ WSOP+ 필요 |
| 5 | `Hands.length` | `51` | `gfx_sessions.hand_count` | 세션 통계 |

#### C.4.2 Hand Level

| # | GFX JSON 필드 | 샘플 값 | Supabase 컬럼 | Cuesheet 활용 |
|:-:|---------------|---------|---------------|---------------|
| 1 | `HandNum` | `1` | `gfx_hands.hand_num` | `cue_items.hand_number` |
| 2 | `Duration` | `PT58.49S` | `gfx_hands.duration_seconds` | 핸드 길이 |
| 3 | `FlopDrawBlinds.*` | `{sb:20K,bb:40K}` | `gfx_hands.blinds` | `gfx_data.blinds` 포맷팅 |
| 4 | `Events[-1].Pot` | `880000` | `gfx_hands.pot_size` | 팟 표시 |
| 5 | `RecordingOffsetStart` | `PT17.48S` | `gfx_hands.recording_offset_seconds` | AEP 타임코드 |

#### C.4.3 Player Level

| # | GFX JSON 필드 | 샘플 값 | Supabase 컬럼 | Cuesheet 활용 (gfx_data) |
|:-:|---------------|---------|---------------|--------------------------|
| 1 | `PlayerNum` | `1` | `seat_num` | `players[].seat` |
| 2 | `Name` | `Voronin` | `player_name` | `players[].name` (대문자) |
| 3 | `LongName` | `Konstantin Voronin` | `gfx_players.long_name` | PlayerProfile `name` |
| 4 | `EndStackAmt` | `1585000` | `end_stack_amt` | `players[].chips` |
| 5 | `IsWinner` | `true` | `is_winner` | `players[].is_winner` |
| 6 | `VPIPPercent` | `28.6` | `vpip_percent` | `vpip_percent` |
| 7 | `HoleCards` | `["9d 3c"]` | `hole_cards` | 홀카드/핸드 분석 |

#### C.4.4 Event Level

| # | GFX JSON 필드 | 샘플 값 | Supabase 컬럼 | Cuesheet 활용 |
|:-:|---------------|---------|---------------|---------------|
| 1 | `EventType` | `ALL IN` | `event_type` | `ALL_IN` (변환) |
| 2 | `PlayerNum` | `5` | `player_num` | 액션 플레이어 |
| 3 | `BetAmt` | `1555000` | `bet_amt` | 베팅 금액 |
| 4 | `Pot` | `3500000` | `pot` | 팟 크기 |
| 5 | `BoardCards` | `As Ks 2h` | `board_cards` | 보드 표시 |

---

### C.5 실제 핸드 → gfx_data 완전 변환 예시

```
┌─────────────────────────────────────────────────────────────────────────────┐
│          Hand #1 → MiniChipTable gfx_data 완전 변환 흐름                      │
└─────────────────────────────────────────────────────────────────────────────┘

[1. GFX JSON 원본]
{
  "HandNum": 1,
  "FlopDrawBlinds": {"SmallBlindAmt": 20000, "BigBlindAmt": 40000, "AnteType": "BB_ANTE_BB1ST"},
  "Players": [
    {"PlayerNum": 1, "Name": "Voronin", "EndStackAmt": 1585000, "IsWinner": false},
    {"PlayerNum": 2, "Name": "Tosoc", "EndStackAmt": 2080000, "IsWinner": false},
    ...
    {"PlayerNum": 9, "Name": "Leng", "EndStackAmt": 2950000, "IsWinner": true}
  ]
}

        ↓ [gfx_normalizer.py 변환]

[2. Supabase 저장]
gfx_hands: {hand_num: 1, blinds: {small_blind: 20000, big_blind: 40000, ante_type: "BB_ANTE_BB1ST"}}
gfx_hand_players: [
  {seat_num: 1, player_name: "Voronin", end_stack_amt: 1585000, is_winner: false},
  {seat_num: 2, player_name: "Tosoc", end_stack_amt: 2080000, is_winner: false},
  ...
  {seat_num: 9, player_name: "Leng", end_stack_amt: 2950000, is_winner: true}
]

        ↓ [GfxToCuesheetTransformer 변환]

[3. cue_items.gfx_data (최종)]
{
  "position": "LEFT",                          ← 수동 설정
  "table_no": 101,                             ← 수동 또는 session에서
  "blinds": "20K/40K - 40K (BB)",              ← format_blinds() 변환
  "players": [
    {"name": "VORONIN", "chips": 1585000, "is_winner": false},   ← .upper()
    {"name": "TOSOC", "chips": 2080000, "is_winner": false},
    {"name": "GEILICH", "chips": 3735000, "is_winner": false},
    {"name": "MA", "chips": 2530000, "is_winner": false},
    {"name": "ASTEDT", "chips": 1555000, "is_winner": false},
    {"name": "FOXEN", "chips": 5940000, "is_winner": false},
    {"name": "ALDEMIR", "chips": 3580000, "is_winner": false},
    {"name": "GAGLIANO", "chips": 1195000, "is_winner": false},
    {"name": "LENG", "chips": 2950000, "is_winner": true}        ← 승자 표시
  ]
}
```

---

## Appendix D: GFX JSON 미제공 데이터 (WSOP+ 제공)

> **목적**: GFX JSON에서 확보할 수 없어 **WSOP+**에서 제공받아야 하는 데이터 목록

### D.1 플레이어 정보 (WSOP+ 통합 제공)

| # | 필요 데이터 | Supabase 테이블 | 소스 | 비고 |
|:-:|-------------|-----------------|------|------|
| 1 | **국가 코드** | `wsop_players.country_code` | 🌐 **WSOP+** | ISO 2자리 (RU, US, KR) |
| 2 | **국가명** | `wsop_players.nationality` | 🌐 **WSOP+** | "Russia", "USA" |
| 3 | **프로필 이미지** | `wsop_players.profile_image` | 🌐 **WSOP+** | 이미지 경로 제공 |
| 4 | **성취/수상** | `wsop_players.achievement` | 🌐 **WSOP+** | 브레이슬릿, 우승 기록 |
| 5 | **WSOP 브레이슬릿 수** | `wsop_players.bracelets` | 🌐 **WSOP+** | 공식 기록 |
| 6 | **총 상금** | `wsop_players.total_earnings` | 🌐 **WSOP+** | 공식 기록 |
| 7 | **표시 이름** | `wsop_players.display_name` | 🌐 **WSOP+** | 정확한 스펠링 |

> **🌐 WSOP+ 통합 제공**: 국가 정보, 프로필 이미지, 성취 기록 모두 WSOP+에서 제공
> GFX에 등록된 모든 플레이어는 WSOP+에서도 정보 제공됨

### D.2 토너먼트/이벤트 정보

| # | 필요 데이터 | Supabase 테이블 | 소스 | 비고 |
|:-:|-------------|-----------------|------|------|
| 1 | **이벤트 제목** | `wsop_events.name` | WSOP+ | GFX `EventTitle` 비어있음 |
| 2 | **이벤트 번호** | `wsop_events.event_number` | WSOP+ | "Event #43" |
| 3 | **바이인 금액** | `wsop_events.buy_in` | WSOP+ | $10,000 등 |
| 4 | **총 참가자 수** | `wsop_events.total_entries` | WSOP+ | 엔트리 수 |
| 5 | **남은 참가자 수** | `wsop_events.players_remaining` | WSOP+ | 실시간 업데이트 |
| 6 | **평균 스택** | `wsop_chip_counts.avg_stack` | WSOP+ | 계산된 값 |
| 7 | **상금 테이블** | `wsop_events.payout_structure` | WSOP+ | GFX Payouts 비어있음 |

### D.3 상금/순위 정보

| # | 필요 데이터 | Supabase 테이블 | 소스 | 비고 |
|:-:|-------------|-----------------|------|------|
| 1 | **탈락 상금** | `wsop_events.payout_structure[rank]` | WSOP+ | $XX,XXX 형식 |
| 2 | **공식 순위** | `wsop_chip_counts.rank` | WSOP+ | 리더보드 순위 |
| 3 | **테이블별 순위** | 계산 필요 | GFX + WSOP+ | 칩 기준 정렬 |

### D.4 방송 제작 정보

| # | 필요 데이터 | Supabase 테이블 | 소스 | 비고 |
|:-:|-------------|-----------------|------|------|
| 1 | **방송 세션 코드** | `broadcast_sessions.session_code` | Cuesheet | "WSOP-2024-ME-D3" |
| 2 | **해설자 정보** | `broadcast_sessions.commentators` | Cuesheet | 해설진 이름 |
| 3 | **방송 언어** | `broadcast_sessions.language` | Cuesheet | EN, KO 등 |
| 4 | **스폰서 정보** | `cue_items.sponsor_data` | Cuesheet | 스폰서 로고/텍스트 |

### D.5 데이터 소스별 정리 (수정됨)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          데이터 소스 맵 (수정됨)                               │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────────┐
    │                        GFX JSON 제공 데이터 ✅                         │
    ├──────────────────────────────────────────────────────────────────────┤
    │ • 플레이어 이름 (LongName → 대문자 변환)                                │
    │ • 시트 번호 (PlayerNum: 1-10)                                         │
    │ • 칩 스택 (StartStackAmt, EndStackAmt)                                │
    │ • 홀카드 (HoleCards: ["9d 3c"])                                       │
    │ • 통계 (VPIPPercent, PFRPercent, AggressionPercent)                  │
    │ • 핸드 이벤트 (FOLD, CALL, RAISE, ALL IN)                             │
    │ • 보드 카드 (BoardCards)                                              │
    │ • 팟 크기 (Pot)                                                       │
    │ • 블라인드 구조 (FlopDrawBlinds)                                      │
    │ • 타임스탬프 (StartDateTimeUTC, RecordingOffsetStart)                 │
    │ • table_no (📁 파일 경로에서 추출: table-GG → "GG")                    │
    └──────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
    ┌──────────────────────────────────────────────────────────────────────┐
    │                    🌐 WSOP+ 통합 제공 데이터                            │
    ├──────────────────────────────────────────────────────────────────────┤
    │ • 플레이어 국가 (nationality, country_code)                           │
    │ • 프로필 이미지 (profile_image)                                       │
    │ • 성취 기록 (achievement, bracelets, total_earnings)                 │
    │ • PlayerProfile 전체 정보                                             │
    │ • Elimination 전체 정보 (순위, 상금)                                   │
    │ • 이벤트 정보 (제목, 바이인, 참가자 수)                                 │
    │ • 공식 상금 테이블 (Payout Structure)                                  │
    │                                                                      │
    │ ※ GFX에 등록된 모든 플레이어는 WSOP+에서도 정보 제공됨                   │
    └──────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
    ┌──────────────────────────────────────────────────────────────────────┐
    │                        Manual Override (선택) 📝                      │
    ├──────────────────────────────────────────────────────────────────────┤
    │ • 방송 세션 메타데이터 (해설자, 언어, 스폰서)                            │
    │ • 표시 이름 보정 (display_name: 스펠링/형식 보정) - 필요 시             │
    │ • 플레이어 별명 (nickname: "GTO Wizard") - 선택 사항                   │
    └──────────────────────────────────────────────────────────────────────┘
```

### D.6 Cuesheet GFX 요소별 데이터 소스 (수정됨)

| GFX 요소 | GFX JSON ✅ | WSOP+ 🌐 | 계산 🔄 | 비고 |
|----------|:----------:|:--------:|:------:|------|
| **MiniChipTable** | LongName⬆️, 칩, is_winner, 블라인드 | - | - | table_no=경로 추출 |
| **Leaderboard** | LongName⬆️, 칩 | **국가** | rank (칩순), BB | Feature Table 기준 |
| **Player Profile** | (칩 옵션) | **전체** | - | WSOP+ 단독 제공 |
| **Elimination** | hole_cards | **전체** | 핸드 분석 | WSOP+ 단독 제공 |
| **VPIP Stats** | LongName⬆️, **vpip_percent** | **국가** | sample_hands | GFX 전용 데이터 |
| **Chip Flow** | LongName⬆️, **chip_history** | **국가** | period | GFX 전용 데이터 |
| **Event Info** | - | **전체** | - | WSOP+ 단독 제공 |
| **Prize Display** | - | **전체** | - | WSOP+ 단독 제공 |

**범례**: ✅ = 필수 소스 | ⚠️ = 보조/부분 소스 | ❌ = 해당 없음

---

## Appendix E: 검증 체크리스트

### E.1 GFX JSON → Supabase 검증

- [ ] `ID` → `session_id` BIGINT 변환 확인
- [ ] `Duration` ISO 8601 → 초 단위 파싱 정확성
- [ ] `HoleCards` 공백 분리 배열 변환
- [ ] `EventType` 공백 → 언더스코어 변환 ("ALL IN" → "ALL_IN")
- [ ] 칩 금액 BIGINT 범위 내 저장

### E.2 Supabase → Cuesheet 검증

- [ ] `unified_chip_data` 뷰 조회 가능
- [ ] FK 관계 정상 (orphan 레코드 없음)
- [ ] `gfx_data` JSONB 구조 올바름

### E.3 데이터 완전성 검증

- [ ] WSOP+ 이벤트 정보 연결 확인
- [ ] Manual Override 플레이어 국가 코드 입력 확인
- [ ] 프로필 이미지 파일 존재 확인

---

## Appendix F: Cuesheet gfx_data 변환 전략 (스크립트 명세)

> **목적**: GFX JSON / Supabase 데이터를 Cuesheet의 `cue_items.gfx_data` JSONB로 변환하는 구체적인 전략 및 스크립트 명세

### F.1 변환 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    GFX → Cuesheet 변환 파이프라인                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Data Sources      │     │   Transformer       │     │   Output            │
├─────────────────────┤     ├─────────────────────┤     ├─────────────────────┤
│ gfx_hands           │─┬──▶│                     │     │                     │
│ gfx_hand_players    │ │   │  GfxToCuesheet      │────▶│  cue_items.gfx_data │
│ gfx_events          │ │   │  Transformer        │     │  (JSONB)            │
├─────────────────────┤ │   │                     │     │                     │
│ wsop_chip_counts    │─┤   │  + Template Router  │     └─────────────────────┘
│ wsop_events         │ │   │  + Data Enricher    │
├─────────────────────┤ │   │  + Formatter        │
│ player_overrides    │─┤   │                     │
│ profile_images      │─┘   └─────────────────────┘
└─────────────────────┘
```

### F.2 GFX 템플릿별 변환 로직

#### F.2.1 MiniChipTable 변환

**입력 데이터**: `gfx_hand_players` (특정 hand_id)

**SQL 쿼리**:
```sql
SELECT
    hp.seat_num,
    hp.player_name AS name,
    hp.end_stack_amt AS chips,
    hp.is_winner,
    h.blinds
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
WHERE h.id = :hand_id
ORDER BY hp.seat_num;
```

**Python 변환 로직**:
```python
def build_mini_chip_table(hand_id: str, position: str) -> dict:
    """MiniChipTable gfx_data 생성"""
    players = db.execute(MINI_CHIP_QUERY, {"hand_id": hand_id}).fetchall()
    hand = db.execute("SELECT * FROM gfx_hands WHERE id = :id", {"id": hand_id}).fetchone()

    return {
        "position": position,  # "LEFT" or "RIGHT"
        "table_no": hand.table_number or 1,
        "players": [
            {
                "name": p.name.upper(),  # 이름 대문자 변환
                "chips": p.chips,
                "is_winner": p.is_winner or False
            }
            for p in players
        ],
        "blinds": format_blinds(hand.blinds)  # "20K/40K - 40K (BB)"
    }

def format_blinds(blinds_json: dict) -> str:
    """블라인드 포맷팅: {small_blind: 20000, big_blind: 40000, ante: 40000}
       → "20K/40K - 40K (BB)" """
    sb = format_chips(blinds_json.get("small_blind", 0))
    bb = format_chips(blinds_json.get("big_blind", 0))
    ante = format_chips(blinds_json.get("ante", 0))
    ante_type = blinds_json.get("ante_type", "BB_ANTE")

    if ante_type == "BB_ANTE_BB1ST":
        return f"{sb}/{bb} - {ante} (BB)"
    return f"{sb}/{bb}"

def format_chips(amount: int) -> str:
    """칩 금액 포맷팅: 1625000 → "1.6M", 40000 → "40K" """
    if amount >= 1_000_000:
        return f"{amount / 1_000_000:.1f}M".rstrip('0').rstrip('.')
    elif amount >= 1_000:
        return f"{amount // 1_000}K"
    return str(amount)
```

#### F.2.2 Leaderboard 변환

**입력 데이터**: `wsop_chip_counts` + `player_overrides`

**SQL 쿼리**:
```sql
SELECT
    wcc.chip_rank AS rank,
    COALESCE(po.display_name, wcc.player_name) AS name,
    COALESCE(po.country_code, wcc.country_code) AS country_code,
    po.nationality AS country,
    wcc.chip_count AS chips,
    wcc.bb_stack AS bb
FROM wsop_chip_counts wcc
LEFT JOIN player_overrides po ON wcc.player_name ILIKE po.original_name
WHERE wcc.event_id = :event_id
  AND wcc.snapshot_time = (
      SELECT MAX(snapshot_time) FROM wsop_chip_counts WHERE event_id = :event_id
  )
ORDER BY wcc.chip_rank
LIMIT :limit;
```

**Python 변환 로직**:
```python
def build_leaderboard(event_id: str, limit: int = 10, title: str = None) -> dict:
    """Leaderboard gfx_data 생성"""
    players = db.execute(LEADERBOARD_QUERY, {"event_id": event_id, "limit": limit}).fetchall()
    event = db.execute("SELECT * FROM wsop_events WHERE id = :id", {"id": event_id}).fetchone()

    total_chips = sum(p.chips for p in players)
    players_remaining = event.players_remaining or len(players)
    avg_stack = total_chips // players_remaining if players_remaining > 0 else 0

    return {
        "title": title or f"{event.name} - Chip Leaders",
        "players_remaining": players_remaining,
        "avg_stack": avg_stack,
        "players": [
            {
                "rank": p.rank,
                "name": p.name,
                "country": p.country or "Unknown",
                "country_code": p.country_code or "XX",
                "chips": p.chips,
                "bb": p.bb or calculate_bb(p.chips, event.current_big_blind)
            }
            for p in players
        ]
    }

def calculate_bb(chips: int, big_blind: int) -> int:
    """BB 스택 계산"""
    return chips // big_blind if big_blind > 0 else 0
```

#### F.2.3 PlayerProfile 변환

**입력 데이터**: `gfx_players` + `player_overrides` + `profile_images` + `wsop_players`

**SQL 쿼리**:
```sql
SELECT
    gp.name,
    gp.long_name,
    COALESCE(po.display_name, gp.long_name, gp.name) AS display_name,
    COALESCE(po.nationality, 'Unknown') AS country,
    COALESCE(po.country_code, 'XX') AS country_code,
    pi.file_path AS profile_image,
    po.bio AS achievement,
    wp.total_earnings AS prize_info,
    wp.bracelets AS wsop_bracelets
FROM gfx_players gp
LEFT JOIN player_overrides po ON gp.name ILIKE po.original_name
LEFT JOIN profile_images pi ON gp.id = pi.player_id
LEFT JOIN wsop_players wp ON gp.name ILIKE wp.name
WHERE gp.id = :player_id;
```

**Python 변환 로직**:
```python
def build_player_profile(player_id: str, include_chips: bool = False, hand_id: str = None) -> dict:
    """PlayerProfile gfx_data 생성"""
    player = db.execute(PLAYER_PROFILE_QUERY, {"player_id": player_id}).fetchone()

    result = {
        "name": player.display_name.upper(),
        "country": player.country,
        "country_code": player.country_code,
    }

    if player.profile_image:
        result["profile_image"] = player.profile_image

    if player.achievement:
        result["achievement"] = player.achievement.upper()

    if player.prize_info:
        result["prize_info"] = f"${player.prize_info:,}"

    if player.wsop_bracelets and player.wsop_bracelets > 0:
        result["wsop_bracelets"] = player.wsop_bracelets

    # 칩 정보 추가 (옵션)
    if include_chips and hand_id:
        hp = db.execute(
            "SELECT end_stack_amt FROM gfx_hand_players WHERE hand_id = :hid AND player_name ILIKE :name",
            {"hid": hand_id, "name": player.name}
        ).fetchone()
        if hp:
            result["chips"] = hp.end_stack_amt

    return result
```

#### F.2.4 Elimination 변환

**입력 데이터**: `gfx_hand_players` (elimination_rank IS NOT NULL) + `wsop_events.payout_structure`

**SQL 쿼리**:
```sql
SELECT
    hp.player_name,
    hp.elimination_rank,
    hp.hole_cards,
    po.nationality AS country,
    po.country_code,
    h.pot_size,
    -- 상대 플레이어 찾기 (all-in 상대)
    (SELECT player_name FROM gfx_hand_players
     WHERE hand_id = hp.hand_id AND is_winner = true LIMIT 1) AS eliminator
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
LEFT JOIN player_overrides po ON hp.player_name ILIKE po.original_name
WHERE hp.hand_id = :hand_id
  AND hp.elimination_rank IS NOT NULL;
```

**Python 변환 로직**:
```python
def build_elimination(hand_id: str, event_id: str) -> dict:
    """Elimination gfx_data 생성"""
    elim = db.execute(ELIMINATION_QUERY, {"hand_id": hand_id}).fetchone()

    # 상금 조회
    payout = get_payout_for_rank(event_id, elim.elimination_rank)

    # 핸드 설명 생성
    hand_desc = build_hand_description(hand_id, elim.player_name, elim.eliminator)

    return {
        "player_name": elim.player_name.upper(),
        "country": elim.country or "Unknown",
        "country_code": elim.country_code or "XX",
        "placement": format_placement(elim.elimination_rank),  # "42ND"
        "prize": payout,
        "hand_description": hand_desc,  # "KK vs JJ - River J"
        "eliminator": elim.eliminator.upper() if elim.eliminator else None
    }

def format_placement(rank: int) -> str:
    """순위 → 서수 변환: 1 → "1ST", 2 → "2ND", 42 → "42ND" """
    if rank % 10 == 1 and rank != 11:
        return f"{rank}ST"
    elif rank % 10 == 2 and rank != 12:
        return f"{rank}ND"
    elif rank % 10 == 3 and rank != 13:
        return f"{rank}RD"
    return f"{rank}TH"

def build_hand_description(hand_id: str, loser: str, winner: str) -> str:
    """핸드 설명 생성: "KK vs JJ - River J" """
    loser_cards = get_hole_cards(hand_id, loser)  # ["Kd", "Kh"]
    winner_cards = get_hole_cards(hand_id, winner)  # ["Jd", "Jh"]
    board = get_board_cards(hand_id)  # ["As", "Ks", "2h", "5c", "Jc"]

    loser_hand = cards_to_hand_name(loser_cards)  # "KK"
    winner_hand = cards_to_hand_name(winner_cards)  # "JJ"

    # 리버에서 결정된 경우
    if len(board) == 5:
        river_card = board[4]
        return f"{loser_hand} vs {winner_hand} - River {river_card[0]}"

    return f"{loser_hand} vs {winner_hand}"
```

#### F.2.5 VPIP Stats 변환

**입력 데이터**: `gfx_hand_players`

**SQL 쿼리**:
```sql
SELECT
    hp.player_name,
    hp.vpip_percent,
    po.nationality AS country,
    po.country_code,
    COUNT(*) OVER (PARTITION BY hp.player_name) AS sample_hands
FROM gfx_hand_players hp
LEFT JOIN player_overrides po ON hp.player_name ILIKE po.original_name
WHERE hp.session_id = :session_id
  AND hp.player_name = :player_name
ORDER BY hp.hand_num DESC
LIMIT 1;
```

**Python 변환 로직**:
```python
def build_vpip_stats(session_id: str, player_name: str) -> dict:
    """VPIP Stats gfx_data 생성"""
    stats = db.execute(VPIP_QUERY, {
        "session_id": session_id,
        "player_name": player_name
    }).fetchone()

    return {
        "player_name": stats.player_name.upper(),
        "country": stats.country or "Unknown",
        "country_code": stats.country_code or "XX",
        "vpip_percent": round(stats.vpip_percent, 1),
        "sample_hands": stats.sample_hands
    }
```

#### F.2.6 ChipFlow 변환

**입력 데이터**: `gfx_hand_players` (다중 핸드)

**SQL 쿼리**:
```sql
SELECT
    hp.hand_num,
    hp.end_stack_amt AS chips
FROM gfx_hand_players hp
WHERE hp.session_id = :session_id
  AND hp.player_name ILIKE :player_name
ORDER BY hp.hand_num DESC
LIMIT :limit;
```

**Python 변환 로직**:
```python
def build_chip_flow(session_id: str, player_name: str, limit: int = 20) -> dict:
    """ChipFlow gfx_data 생성"""
    history = db.execute(CHIP_FLOW_QUERY, {
        "session_id": session_id,
        "player_name": player_name,
        "limit": limit
    }).fetchall()

    # 시간순 정렬 (역순으로 조회했으므로)
    history = list(reversed(history))
    chip_values = [h.chips for h in history]

    player = get_player_override(player_name)

    return {
        "player_name": player_name.upper(),
        "country": player.country or "Unknown",
        "country_code": player.country_code or "XX",
        "chip_history": chip_values,
        "period": f"LAST {len(chip_values)} HANDS",
        "current_chips": chip_values[-1] if chip_values else 0
    }
```

### F.3 템플릿 라우터

**템플릿 코드 → 변환 함수 매핑**:

```python
TEMPLATE_HANDLERS = {
    # MiniChipTable
    "mini_chip_left": lambda ctx: build_mini_chip_table(ctx["hand_id"], "LEFT"),
    "mini_chip_right": lambda ctx: build_mini_chip_table(ctx["hand_id"], "RIGHT"),

    # Leaderboard
    "leaderboard": lambda ctx: build_leaderboard(ctx["event_id"], ctx.get("limit", 10)),
    "leaderboard_full": lambda ctx: build_leaderboard(ctx["event_id"], limit=50),

    # Player Profile
    "player_profile": lambda ctx: build_player_profile(ctx["player_id"]),
    "player_profile_chips": lambda ctx: build_player_profile(
        ctx["player_id"], include_chips=True, hand_id=ctx.get("hand_id")
    ),

    # Elimination
    "eliminated": lambda ctx: build_elimination(ctx["hand_id"], ctx["event_id"]),
    "elimination_risk": lambda ctx: build_elimination_risk(ctx["player_id"], ctx["event_id"]),

    # Stats
    "vpip": lambda ctx: build_vpip_stats(ctx["session_id"], ctx["player_name"]),
    "chip_flow": lambda ctx: build_chip_flow(ctx["session_id"], ctx["player_name"]),
    "chip_comparison": lambda ctx: build_chip_comparison(ctx["player1_id"], ctx["player2_id"]),

    # Feature Table
    "feature_table_chip": lambda ctx: build_feature_table_chip(ctx["hand_id"]),

    # Payouts
    "mini_payouts": lambda ctx: build_mini_payouts(ctx["event_id"], ctx.get("position", "LEFT")),
}

def transform_to_gfx_data(template_code: str, context: dict) -> dict:
    """템플릿 코드에 따라 적절한 gfx_data 생성"""
    handler = TEMPLATE_HANDLERS.get(template_code)
    if not handler:
        raise ValueError(f"Unknown template code: {template_code}")
    return handler(context)
```

### F.4 cue_items INSERT 전체 흐름

```python
def create_cue_item(
    sheet_id: str,
    template_code: str,
    hand_number: int = None,
    context: dict = None
) -> str:
    """큐 아이템 생성 (gfx_data 자동 변환)"""

    # 1. 템플릿 조회
    template = db.execute(
        "SELECT id FROM cue_templates WHERE template_code = :code",
        {"code": template_code}
    ).fetchone()

    # 2. gfx_data 변환
    gfx_data = transform_to_gfx_data(template_code, context or {})

    # 3. cue_item INSERT
    result = db.execute("""
        INSERT INTO cue_items (
            sheet_id, template_id, hand_number, gfx_data, status
        ) VALUES (
            :sheet_id, :template_id, :hand_number, :gfx_data, 'ready'
        )
        RETURNING id
    """, {
        "sheet_id": sheet_id,
        "template_id": template.id if template else None,
        "hand_number": hand_number,
        "gfx_data": json.dumps(gfx_data)
    })

    return result.fetchone().id
```

### F.5 실제 사용 예시

```python
# 예시 1: MiniChipTable 생성
cue_item_id = create_cue_item(
    sheet_id="abc-123",
    template_code="mini_chip_left",
    hand_number=42,
    context={"hand_id": "hand-uuid-here"}
)

# 예시 2: Leaderboard 생성
cue_item_id = create_cue_item(
    sheet_id="abc-123",
    template_code="leaderboard",
    context={"event_id": "event-uuid-here", "limit": 10}
)

# 예시 3: Elimination 생성
cue_item_id = create_cue_item(
    sheet_id="abc-123",
    template_code="eliminated",
    hand_number=156,
    context={
        "hand_id": "hand-uuid-here",
        "event_id": "event-uuid-here"
    }
)

# 예시 4: VPIP Stats 생성
cue_item_id = create_cue_item(
    sheet_id="abc-123",
    template_code="vpip",
    context={
        "session_id": "session-uuid-here",
        "player_name": "Bagirov"
    }
)
```

### F.6 데이터 변환 유틸리티 함수

```python
# ==================== 포맷팅 유틸리티 ====================

def format_chips(amount: int) -> str:
    """칩 금액 포맷팅: 1625000 → "1.6M" """
    if amount >= 1_000_000:
        val = amount / 1_000_000
        return f"{val:.1f}M".rstrip('0').rstrip('.')
    elif amount >= 1_000:
        return f"{amount // 1_000}K"
    return str(amount)

def format_placement(rank: int) -> str:
    """순위 서수화: 1 → "1ST" """
    if rank % 10 == 1 and rank != 11:
        return f"{rank}ST"
    elif rank % 10 == 2 and rank != 12:
        return f"{rank}ND"
    elif rank % 10 == 3 and rank != 13:
        return f"{rank}RD"
    return f"{rank}TH"

def format_blinds(blinds: dict) -> str:
    """블라인드 포맷팅"""
    sb = format_chips(blinds.get("small_blind", 0))
    bb = format_chips(blinds.get("big_blind", 0))
    ante = blinds.get("ante", 0)
    if ante:
        return f"{sb}/{bb} - {format_chips(ante)} (BB)"
    return f"{sb}/{bb}"

# ==================== 카드 유틸리티 ====================

def cards_to_hand_name(cards: list[str]) -> str:
    """홀카드 → 핸드 이름: ["Kd", "Kh"] → "KK" """
    if not cards or len(cards) < 2:
        return "??"
    ranks = [c[:-1] for c in cards]  # ["K", "K"]
    if ranks[0] == ranks[1]:
        return f"{ranks[0]}{ranks[0]}"  # Pair
    # 수트 같으면 suited
    suits = [c[-1] for c in cards]
    suffix = "s" if suits[0] == suits[1] else "o"
    return f"{ranks[0]}{ranks[1]}{suffix}"

def parse_hole_cards(raw: list[str]) -> list[str]:
    """GFX JSON 홀카드 파싱: ["9d 3c"] → ["9d", "3c"] """
    if not raw or not raw[0]:
        return []
    return raw[0].split()

# ==================== 조회 유틸리티 ====================

def get_player_override(player_name: str) -> Optional[dict]:
    """player_overrides 조회"""
    return db.execute(
        "SELECT * FROM player_overrides WHERE original_name ILIKE :name",
        {"name": player_name}
    ).fetchone()

def get_payout_for_rank(event_id: str, rank: int) -> int:
    """상금 조회"""
    event = db.execute(
        "SELECT payout_structure FROM wsop_events WHERE id = :id",
        {"id": event_id}
    ).fetchone()
    if event and event.payout_structure:
        return event.payout_structure.get(str(rank), 0)
    return 0
```

### F.7 변환 흐름 요약 다이어그램

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    템플릿별 데이터 변환 흐름                                   │
└─────────────────────────────────────────────────────────────────────────────┘

[MiniChipTable]
gfx_hand_players (seat_num, player_name, end_stack_amt, is_winner)
        │
        ▼
    build_mini_chip_table()
        │
        ▼
    { position, table_no, players[], blinds }

[Leaderboard]
wsop_chip_counts + player_overrides
        │
        ▼
    build_leaderboard()
        │
        ▼
    { title, players_remaining, avg_stack, players[] }

[PlayerProfile]
gfx_players + player_overrides + profile_images + wsop_players
        │
        ▼
    build_player_profile()
        │
        ▼
    { name, country, country_code, profile_image, achievement, ... }

[Elimination]
gfx_hand_players (elimination_rank) + wsop_events (payout)
        │
        ▼
    build_elimination()
        │
        ▼
    { player_name, placement, prize, hand_description, eliminator }

[VPIP]
gfx_hand_players (vpip_percent)
        │
        ▼
    build_vpip_stats()
        │
        ▼
    { player_name, country, vpip_percent, sample_hands }

[ChipFlow]
gfx_hand_players (다중 핸드)
        │
        ▼
    build_chip_flow()
        │
        ▼
    { player_name, chip_history[], period, current_chips }
```
