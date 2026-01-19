# GFX JSON 필드 2계층 매핑 전략

**Version**: 2.0.0
**Last Updated**: 2026-01-19
**Status**: Active
**Project**: Automation DB Schema Optimization

---

## 1. 개요

### 1.1 핵심 원칙

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    2계층 매핑 전략 (Two-Layer Mapping)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Layer 1: DB 저장 (Storage Layer)                                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                                           │
│  ✅ 모든 JSON 필드 저장 (53개 전체)                                          │
│  ✅ 원본 데이터 보존                                                         │
│  ✅ 추후 분석/확장 가능                                                      │
│                                                                             │
│  Layer 2: AEP 매핑 (Rendering Layer)                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                                          │
│  ⚡ 실제 사용 필드만 매핑 (32개)                                              │
│  ⚡ 26개 컴포지션에 필요한 값만 쿼리                                         │
│  ⚡ 성능 최적화 (불필요 컬럼 제외)                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 전략 요약

| 계층 | 목적 | 필드 수 | 원칙 |
|------|------|---------|------|
| **Layer 1: DB 저장** | 원본 보존, 추후 확장 | **53개** (전체) | 모든 필드 저장 |
| **Layer 2: AEP 매핑** | 렌더링 성능 | **32개** (선별) | 사용 필드만 쿼리 |

---

## 2. 분석 결과 (28개 파일 기준)

### 2.1 데이터 규모

| 항목 | 수량 |
|------|------|
| 분석 파일 | 28개 |
| 총 핸드 | 1,559개 |
| 총 플레이어 레코드 | 11,961개 |
| 총 이벤트 | 20,020개 |
| 총 필드 | 53개 |

### 2.2 필드 분류 결과

| 분류 | 개수 | DB 저장 | AEP 매핑 | 비고 |
|------|------|---------|----------|------|
| **ACTIVE** | 32 | ✅ | ✅ | 실제 사용 중 |
| **RESERVED** | 6 | ✅ | ❌ | 고정값이나 향후 변경 가능 |
| **ARCHIVED** | 15 | ✅ | ❌ | 현재 미사용 (0/null/고정) |
| **합계** | **53** | **53** | **32** | - |

---

## 3. 필드별 상세 분류

### 3.1 Root Level (6개)

| 필드 | 값 특성 | DB 저장 | AEP 매핑 | 분류 | 비고 |
|------|---------|---------|----------|------|------|
| **ID** | 고유 (28개) | ✅ | ✅ | ACTIVE | 세션 PK |
| **CreatedDateTimeUTC** | 고유 (28개) | ✅ | ✅ | ACTIVE | 세션 생성 시각 |
| **SoftwareVersion** | "PokerGFX 3.2" | ✅ | ❌ | RESERVED | 버전 변경 시 필요 |
| **Type** | 2종류 | ✅ | ✅ | ACTIVE | FEATURE/FINAL_TABLE |
| **EventTitle** | 100% 빈 문자열 | ✅ | ❌ | ARCHIVED | 미사용 |
| **Payouts** | 100% [0,0,...] | ✅ | ❌ | ARCHIVED | WSOP+에서 관리 |

### 3.2 Hands Level (12개)

| 필드 | 값 특성 | DB 저장 | AEP 매핑 | 분류 | 비고 |
|------|---------|---------|----------|------|------|
| **HandNum** | 1-173 | ✅ | ✅ | ACTIVE | 핸드 번호 |
| **AnteAmt** | 0-600,000 | ✅ | ✅ | ACTIVE | 앤티 금액 |
| **BetStructure** | "NOLIMIT" | ✅ | ❌ | RESERVED | 다른 구조 가능성 |
| **BombPotAmt** | 100% 0 | ✅ | ❌ | ARCHIVED | 캐시게임용 |
| **Description** | 100% null | ✅ | ❌ | ARCHIVED | 미사용 |
| **Duration** | 다양 (PT형식) | ✅ | ✅ | ACTIVE | 핸드 시간 |
| **GameClass** | "FLOP" | ✅ | ❌ | RESERVED | 다른 게임 가능성 |
| **GameVariant** | "HOLDEM" | ✅ | ❌ | RESERVED | 다른 변형 가능성 |
| **NumBoards** | 100% 1 | ✅ | ❌ | ARCHIVED | Run It Twice 없음 |
| **RunItNumTimes** | 100% 1 | ✅ | ❌ | ARCHIVED | 토너먼트 미사용 |
| **StartDateTimeUTC** | 고유 | ✅ | ✅ | ACTIVE | 핸드 시작 시각 |
| **RecordingOffsetStart** | 고유 | ✅ | ✅ | ACTIVE | 영상 타임코드 |

### 3.3 FlopDrawBlinds (9개)

| 필드 | 값 특성 | DB 저장 | AEP 매핑 | 분류 | 비고 |
|------|---------|---------|----------|------|------|
| **AnteType** | "BB_ANTE_BB1ST" | ✅ | ❌ | RESERVED | 다른 앤티 방식 가능 |
| **BigBlindAmt** | 200-600,000 | ✅ | ✅ | ACTIVE | BB 금액 (핵심) |
| **BigBlindPlayerNum** | 2-9 | ✅ | ✅ | ACTIVE | BB 위치 |
| **BlindLevel** | 100% 0 | ✅ | ❌ | ARCHIVED | 레벨 번호 미사용 |
| **ButtonPlayerNum** | 1-10 | ✅ | ✅ | ACTIVE | 버튼 위치 |
| **SmallBlindAmt** | 80-300,000 | ✅ | ✅ | ACTIVE | SB 금액 |
| **SmallBlindPlayerNum** | 1-9 | ✅ | ✅ | ACTIVE | SB 위치 |
| **ThirdBlindAmt** | 100% 0 | ✅ | ❌ | ARCHIVED | 3블 미사용 |
| **ThirdBlindPlayerNum** | 100% 0 | ✅ | ❌ | ARCHIVED | 3블 미사용 |

### 3.4 StudLimits (4개) - 전체 ARCHIVED

| 필드 | 값 특성 | DB 저장 | AEP 매핑 | 분류 | 비고 |
|------|---------|---------|----------|------|------|
| **BringInAmt** | 100% 0 | ✅ | ❌ | ARCHIVED | 스터드 미사용 |
| **BringInPlayerNum** | 100% 1 | ✅ | ❌ | ARCHIVED | 스터드 미사용 |
| **HighLimitAmt** | 100% 0 | ✅ | ❌ | ARCHIVED | 스터드 미사용 |
| **LowLimitAmt** | 100% 0 | ✅ | ❌ | ARCHIVED | 스터드 미사용 |

### 3.5 Players Level (14개)

| 필드 | 값 특성 | DB 저장 | AEP 매핑 | 분류 | 비고 |
|------|---------|---------|----------|------|------|
| **PlayerNum** | 1-10 | ✅ | ✅ | ACTIVE | 좌석 번호 |
| **Name** | 다양 | ✅ | ✅ | ACTIVE | 표시 이름 (핵심) |
| **LongName** | 1.5% null | ✅ | ✅ | ACTIVE | 전체 이름 |
| **StartStackAmt** | 0-455M | ✅ | ✅ | ACTIVE | 시작 칩 |
| **EndStackAmt** | 0-455M | ✅ | ✅ | ACTIVE | 종료 칩 (핵심) |
| **CumulativeWinningsAmt** | -22M~65M | ✅ | ✅ | ACTIVE | 누적 수익 |
| **HoleCards** | 다양 | ✅ | ✅ | ACTIVE | 핸드 카드 |
| **SittingOut** | true/false | ✅ | ✅ | ACTIVE | 참가 상태 |
| **EliminationRank** | -1~9 | ✅ | ✅ | ACTIVE | 탈락 순위 |
| **BlindBetStraddleAmt** | 100% 0 | ✅ | ❌ | ARCHIVED | 스트래들 미사용 |
| **VPIPPercent** | 0-100 | ✅ | ✅ | ACTIVE | VPIP 통계 |
| **PreFlopRaisePercent** | 0-100 | ✅ | ✅ | ACTIVE | PFR 통계 |
| **AggressionFrequencyPercent** | 0-83 | ✅ | ✅ | ACTIVE | AF 통계 |
| **WentToShowDownPercent** | 0-600 | ✅ | ✅ | ACTIVE | WTSD 통계 |

### 3.6 Events Level (8개)

| 필드 | 값 특성 | DB 저장 | AEP 매핑 | 분류 | 비고 |
|------|---------|---------|----------|------|------|
| **EventType** | 6종류 | ✅ | ✅ | ACTIVE | 액션 유형 |
| **PlayerNum** | 0-9 | ✅ | ✅ | ACTIVE | 액션 주체 |
| **BetAmt** | 0-55M | ✅ | ✅ | ACTIVE | 베팅 금액 |
| **Pot** | 0-44M | ✅ | ✅ | ACTIVE | 팟 크기 |
| **BoardNum** | 0-1 | ✅ | ✅ | ACTIVE | 보드 번호 |
| **BoardCards** | 80.4% null | ✅ | ✅ | ACTIVE | 보드 카드 |
| **NumCardsDrawn** | 100% 0 | ✅ | ❌ | ARCHIVED | 드로우 미사용 |
| **DateTimeUTC** | 100% null | ✅ | ❌ | ARCHIVED | 미사용 |

---

## 4. 2계층 아키텍처 상세

### 4.1 Layer 1: DB 저장 스키마

```sql
-- 모든 필드 저장 (원본 보존)
CREATE TABLE gfx_sessions (
    id BIGINT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL,
    software_version VARCHAR(50),        -- RESERVED
    type VARCHAR(20) NOT NULL,
    event_title VARCHAR(255),            -- ARCHIVED (null 허용)
    payouts INTEGER[],                   -- ARCHIVED (null 허용)
    raw_json JSONB                       -- 원본 백업 (선택)
);

CREATE TABLE gfx_hands (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES gfx_sessions(id),
    hand_num INTEGER NOT NULL,
    ante_amt BIGINT DEFAULT 0,
    bet_structure VARCHAR(20),           -- RESERVED
    bomb_pot_amt BIGINT DEFAULT 0,       -- ARCHIVED
    description TEXT,                    -- ARCHIVED
    duration INTERVAL,
    game_class VARCHAR(20),              -- RESERVED
    game_variant VARCHAR(20),            -- RESERVED
    num_boards SMALLINT DEFAULT 1,       -- ARCHIVED
    run_it_num_times SMALLINT DEFAULT 1, -- ARCHIVED
    started_at TIMESTAMPTZ,
    recording_offset INTERVAL,
    blinds JSONB NOT NULL,               -- 전체 blinds 구조 저장
    stud_limits JSONB                    -- 전체 stud 구조 저장 (ARCHIVED)
);

CREATE TABLE gfx_hand_players (
    id BIGSERIAL PRIMARY KEY,
    hand_id BIGINT REFERENCES gfx_hands(id),
    seat_num SMALLINT NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_full_name VARCHAR(200),
    start_stack_amt BIGINT NOT NULL,
    end_stack_amt BIGINT NOT NULL,
    cumulative_winnings BIGINT DEFAULT 0,
    hole_cards VARCHAR(20),
    sitting_out BOOLEAN DEFAULT FALSE,
    elimination_rank SMALLINT,
    blind_bet_straddle_amt BIGINT DEFAULT 0,  -- ARCHIVED
    vpip_percent DECIMAL(5,2),
    pfr_percent DECIMAL(5,2),
    af_percent DECIMAL(5,2),
    wtsd_percent DECIMAL(5,2)
);

CREATE TABLE gfx_events (
    id BIGSERIAL PRIMARY KEY,
    hand_id BIGINT REFERENCES gfx_hands(id),
    event_order SMALLINT NOT NULL,
    event_type VARCHAR(20) NOT NULL,
    seat_num SMALLINT,
    bet_amt BIGINT DEFAULT 0,
    pot_amt BIGINT DEFAULT 0,
    board_num SMALLINT DEFAULT 0,
    board_card VARCHAR(5),
    num_cards_drawn SMALLINT DEFAULT 0,  -- ARCHIVED
    event_time TIMESTAMPTZ               -- ARCHIVED (null)
);
```

### 4.2 Layer 2: AEP 매핑 뷰

```sql
-- 칩 디스플레이용 뷰 (ACTIVE 필드만)
CREATE VIEW v_aep_chip_display AS
SELECT
    hp.id,
    hp.hand_id,
    hp.seat_num,
    UPPER(hp.player_name) AS display_name,
    hp.end_stack_amt,
    h.blinds->>'big_blind_amt' AS bb_amt,
    hp.sitting_out,
    hp.elimination_rank
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
WHERE hp.sitting_out = FALSE;

-- 플레이어 통계용 뷰 (ACTIVE 필드만)
CREATE VIEW v_aep_player_stats AS
SELECT
    hp.id,
    hp.hand_id,
    hp.seat_num,
    hp.player_name,
    hp.vpip_percent,
    hp.pfr_percent,
    hp.af_percent,
    hp.wtsd_percent
FROM gfx_hand_players hp
WHERE hp.sitting_out = FALSE;

-- 핸드 정보용 뷰 (ACTIVE 필드만)
CREATE VIEW v_aep_hand_info AS
SELECT
    h.id,
    h.session_id,
    h.hand_num,
    h.ante_amt,
    h.duration,
    h.started_at,
    h.recording_offset,
    (h.blinds->>'big_blind_amt')::BIGINT AS bb_amt,
    (h.blinds->>'small_blind_amt')::BIGINT AS sb_amt,
    (h.blinds->>'button_player_num')::SMALLINT AS btn_seat
FROM gfx_hands h;

-- 이벤트용 뷰 (ACTIVE 필드만)
CREATE VIEW v_aep_events AS
SELECT
    e.id,
    e.hand_id,
    e.event_order,
    e.event_type,
    e.seat_num,
    e.bet_amt,
    e.pot_amt,
    e.board_num,
    e.board_card
FROM gfx_events e;
```

---

## 5. AEP 컴포지션별 사용 필드

### 5.1 chip_display 카테고리 (6개)

| 컴포지션 | 사용 필드 | 테이블/뷰 |
|----------|----------|-----------|
| _MAIN Mini Chip Count | name, end_stack_amt, bb_amt, seat_num | v_aep_chip_display |
| _SUB_Mini Chip Count | name, end_stack_amt, bb_amt, seat_num | v_aep_chip_display |
| Chips In Play x3 | bb_amt, sb_amt, SUM(end_stack_amt) | v_aep_hand_info, v_aep_chip_display |
| Chips In Play x4 | bb_amt, sb_amt, SUM(end_stack_amt) | v_aep_hand_info, v_aep_chip_display |
| Chip Comparison | name, end_stack_amt | v_aep_chip_display |
| Chip Flow | end_stack_amt (히스토리) | gfx_hand_players |

### 5.2 player_info 카테고리 (4개)

| 컴포지션 | 사용 필드 | 테이블/뷰 |
|----------|----------|-----------|
| NAME | player_name, end_stack_amt, bb_amt | v_aep_chip_display |
| NAME 1줄 | player_name | v_aep_chip_display |
| NAME 2줄 | player_name, end_stack_amt, bb_amt | v_aep_chip_display |
| NAME 3줄+ | player_name, end_stack_amt, vpip_percent | v_aep_chip_display, v_aep_player_stats |

### 5.3 elimination 카테고리 (2개)

| 컴포지션 | 사용 필드 | 테이블/뷰 |
|----------|----------|-----------|
| Elimination | player_name, elimination_rank | gfx_hand_players |
| At Risk of Elimination | player_name, end_stack_amt | v_aep_chip_display |

---

## 6. 필드 활성화 로드맵

### 6.1 현재 ARCHIVED → 향후 ACTIVE 가능성

| 필드 | 현재 상태 | 활성화 조건 | 우선순위 |
|------|----------|------------|---------|
| **EventTitle** | 100% null | PokerGFX 업데이트 | LOW |
| **Payouts** | 100% [0,...] | GFX 자체 payouts 지원 | LOW |
| **BombPotAmt** | 100% 0 | 캐시게임 방송 시작 | MEDIUM |
| **BlindLevel** | 100% 0 | 레벨 표시 필요 시 | MEDIUM |
| **NumCardsDrawn** | 100% 0 | 드로우 게임 방송 | LOW |
| **DateTimeUTC (Events)** | 100% null | 이벤트 타임스탬프 필요 | LOW |

### 6.2 RESERVED → 조건부 ACTIVE

| 필드 | 현재 값 | 변경 시나리오 |
|------|---------|--------------|
| **SoftwareVersion** | "PokerGFX 3.2" | 버전 업그레이드 감지 |
| **BetStructure** | "NOLIMIT" | PLO, Limit 방송 |
| **GameClass** | "FLOP" | 스터드, 드로우 방송 |
| **GameVariant** | "HOLDEM" | Omaha, Stud 방송 |
| **AnteType** | "BB_ANTE_BB1ST" | 앤티 방식 변경 |

---

## 7. 구현 권장사항

### 7.1 DB 저장 (Layer 1)

```python
# gfx_json_parser.py
def save_to_db(json_data):
    """모든 필드 저장 - 분류와 무관"""
    session = GfxSession(
        id=json_data['ID'],
        created_at=json_data['CreatedDateTimeUTC'],
        software_version=json_data['SoftwareVersion'],  # RESERVED
        type=json_data['Type'],
        event_title=json_data.get('EventTitle'),        # ARCHIVED (nullable)
        payouts=json_data.get('Payouts'),               # ARCHIVED (nullable)
    )
    # ... 모든 필드 저장
```

### 7.2 AEP 매핑 (Layer 2)

```python
# aep_mapper.py
def get_chip_display_data(session_id, hand_num):
    """ACTIVE 필드만 쿼리 - 성능 최적화"""
    return db.execute("""
        SELECT display_name, end_stack_amt, bb_amt
        FROM v_aep_chip_display
        WHERE hand_id = (
            SELECT id FROM gfx_hands
            WHERE session_id = :sid AND hand_num = :hnum
        )
        ORDER BY end_stack_amt DESC
        LIMIT 9
    """, {'sid': session_id, 'hnum': hand_num})
```

### 7.3 필드 분류 메타데이터

```sql
-- 필드 분류 테이블 (관리용)
CREATE TABLE gfx_field_classifications (
    id SERIAL PRIMARY KEY,
    level VARCHAR(20) NOT NULL,         -- root, hands, players, events
    field_name VARCHAR(100) NOT NULL,
    classification VARCHAR(20) NOT NULL, -- ACTIVE, RESERVED, ARCHIVED
    aep_mapped BOOLEAN DEFAULT FALSE,
    notes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(level, field_name)
);

-- 초기 데이터
INSERT INTO gfx_field_classifications (level, field_name, classification, aep_mapped, notes) VALUES
('root', 'ID', 'ACTIVE', TRUE, '세션 PK'),
('root', 'CreatedDateTimeUTC', 'ACTIVE', TRUE, '세션 생성 시각'),
('root', 'SoftwareVersion', 'RESERVED', FALSE, '버전 변경 시 필요'),
('root', 'Type', 'ACTIVE', TRUE, 'FEATURE/FINAL_TABLE'),
('root', 'EventTitle', 'ARCHIVED', FALSE, '100% 빈 문자열'),
('root', 'Payouts', 'ARCHIVED', FALSE, 'WSOP+에서 관리');
-- ... 53개 전체
```

---

## 8. 요약

### 8.1 핵심 포인트

| 원칙 | 설명 |
|------|------|
| **DB: 모든 필드 저장** | 53개 필드 전체 저장 (원본 보존) |
| **AEP: 사용 필드만 쿼리** | 32개 ACTIVE 필드만 매핑 |
| **확장성 확보** | RESERVED/ARCHIVED 필드 언제든 활성화 가능 |
| **성능 최적화** | AEP 뷰에서 필요 컬럼만 SELECT |

### 8.2 필드 분류 요약

```
┌─────────────────────────────────────────────────────────────┐
│  총 53개 필드                                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ███████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│  |      ACTIVE (32)      | RESERVED (6) | ARCHIVED (15)   | │
│  |      DB ✅ AEP ✅      | DB ✅ AEP ❌ | DB ✅ AEP ❌    | │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. 관련 문서

| 문서 | 위치 | 관계 |
|------|------|------|
| GFX JSON 종합 분석 | `docs/GFX_JSON_COMPREHENSIVE_ANALYSIS.md` | 원본 데이터 분석 |
| GFX JSON DB 스키마 | `docs/02-GFX-JSON-DB.md` | Layer 1 스키마 |
| GFX-AEP 매핑 명세 | `docs/08-GFX-AEP-Mapping.md` | Layer 2 매핑 로직 |
| 마이그레이션 파일 | `supabase/migrations/` | SSOT |

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 2.0.0 | 2026-01-19 | 2계층 매핑 전략으로 전환 (모든 필드 저장 + 사용 필드만 매핑) |
| 1.0.0 | 2026-01-19 | 초기 작성: 필드 제거 중심 전략 (폐기) |
