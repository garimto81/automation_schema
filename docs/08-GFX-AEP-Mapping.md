# 08. GFX JSON DB ↔ AEP 렌더링 필드 매핑

GFX JSON DB 데이터와 After Effects 컴포지션 필드 간의 바인딩 규칙 정의

**Version**: 1.0.0
**Date**: 2026-01-14
**Project**: Feature Table Automation (FT-0001)

---

## 1. 개요

### 1.1 목적

GFX JSON DB에 저장된 포커 게임 데이터를 After Effects 컴포지션의 텍스트/이미지 레이어에 동적으로 바인딩하여 방송 그래픽을 자동 생성합니다.

### 1.2 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Data Flow Architecture                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   SOURCE DATA   │     │  ORCHESTRATION  │     │   AEP RENDER    │
│                 │     │                 │     │                 │
│ ┌─────────────┐ │     │ ┌─────────────┐ │     │ ┌─────────────┐ │
│ │ gfx_hands   │─┼────▶│ │ job_queue   │─┼────▶│ │ aerender    │ │
│ │ gfx_players │ │     │ │             │ │     │ │             │ │
│ └─────────────┘ │     │ └─────────────┘ │     │ └─────────────┘ │
│                 │     │       │         │     │       │         │
│ ┌─────────────┐ │     │       ▼         │     │       ▼         │
│ │ wsop_       │ │     │ ┌─────────────┐ │     │ ┌─────────────┐ │
│ │ standings   │─┼────▶│ │render_queue │─┼────▶│ │ Output      │ │
│ │ chip_counts │ │     │ │ (gfx_data)  │ │     │ │ .mp4/.mov   │ │
│ └─────────────┘ │     │ └─────────────┘ │     │ └─────────────┘ │
│                 │     │                 │     │                 │
│ ┌─────────────┐ │     │                 │     │                 │
│ │ manual_     │ │     │                 │     │                 │
│ │ players     │─┼────▶│                 │     │                 │
│ └─────────────┘ │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 1.3 연관 문서

| 문서 | 설명 |
|------|------|
| `02-GFX-JSON-DB.md` | GFX JSON 데이터베이스 스키마 |
| `03-WSOP+-DB.md` | WSOP+ 데이터베이스 스키마 |
| `04-Manual-DB.md` | 수동 플레이어 관리 스키마 |
| `06-AEP-Analysis-DB.md` | AEP 컴포지션 분석 스키마 |
| `07-Supabase-Orchestration.md` | 오케스트레이션 레이어 |

---

## 2. 컴포지션별 필드 매핑

### 2.1 Chip Display 컴포지션 (16개)

**대상 컴포지션**: `_MAIN Mini Chip Count`, `_SUB_Mini Chip Count`, `Chip Flow`, `Chip Comparison` 등

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|--------|---------------|---------|---------------|
| `name 1~16` | 16 | `gfx_hand_players` | `player_name` | **정렬**: `end_stack_amt DESC`. slot 1 = 칩 리더. `sitting_out = TRUE` 제외 |
| `chips 1~16` | 16 | `gfx_hand_players` | `end_stack_amt` | **정렬**: 동일. **변환**: `format_chips()` (1500000 → "1,500,000") |
| `rank 1~16` | 16 | (계산) | - | **계산**: `ROW_NUMBER() OVER (ORDER BY end_stack_amt DESC)`. rank = slot_index |
| `bbs 1~16` | 16 | (계산) | - | **계산**: `end_stack_amt / big_blind_amt`. **변환**: `format_bbs()` (소수점 1자리) |
| `country_flag 1~16` | 16 | `unified_players` | `country_code` | **우선순위**: Manual > WSOP+ > GFX. **fallback**: 'XX' (Unknown). **변환**: ISO → Flag 경로 |

#### 데이터 추출 쿼리

```sql
SELECT
    ROW_NUMBER() OVER (ORDER BY hp.end_stack_amt DESC) AS rank,
    hp.player_name AS name,
    format_chips(hp.end_stack_amt) AS chips,
    format_bbs(hp.end_stack_amt, (h.blinds->>'big_blind_amt')::BIGINT) AS bbs,
    COALESCE(up.country_code, 'XX') AS country_code,
    get_flag_path(COALESCE(up.country_code, 'XX')) AS flag_path
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
LEFT JOIN unified_players up ON hp.player_name = up.name
WHERE hp.sitting_out = FALSE
  AND h.session_id = :session_id
  AND h.hand_num = :hand_num
ORDER BY hp.end_stack_amt DESC
LIMIT 16;
```

---

### 2.2 Leaderboard 컴포지션 (3개)

**대상 컴포지션**: `Feature Table Leaderboard MAIN`, `Feature Table Leaderboard SUB`

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|--------|---------------|---------|---------------|
| `name 1~30` | 30 | `wsop_standings` | `standings->>'player_name'` | **정렬**: JSONB `rank` 필드 오름차순. slot 1 = 전체 1위. **추출**: JSONB 배열 순회 |
| `chips 1~30` | 30 | `wsop_standings` | `standings->>'chip_count'` | **정렬**: 동일. **변환**: `format_chips()` (1500000 → "1,500,000") |
| `rank 1~30` | 30 | `wsop_standings` | `standings->>'rank'` | **추출**: JSONB `rank` 필드 직접 사용 (WSOP+ API 제공 순위) |
| `bbs 1~30` | 30 | `wsop_standings` | `standings->>'stack_in_bbs'` | **추출**: JSONB 필드. **변환**: `format_bbs()` (소수점 1자리) |
| `country_flag 1~30` | 30 | `wsop_standings` | `standings->>'country_code'` | **추출**: JSONB 필드. **fallback**: 'XX'. **변환**: ISO → Flag 경로 |

#### 데이터 추출 쿼리

```sql
SELECT
    (player->>'rank')::INTEGER AS rank,
    player->>'player_name' AS name,
    format_chips((player->>'chip_count')::BIGINT) AS chips,
    format_bbs(
        (player->>'chip_count')::BIGINT,
        (SELECT (blind_structure->0->>'bb')::BIGINT FROM wsop_events WHERE id = s.event_id)
    ) AS bbs,
    COALESCE(player->>'country_code', 'XX') AS country_code,
    get_flag_path(COALESCE(player->>'country_code', 'XX')) AS flag_path
FROM wsop_standings s
CROSS JOIN LATERAL jsonb_array_elements(s.standings) AS player
WHERE s.event_id = :event_id
  AND s.id = (
      SELECT id FROM wsop_standings
      WHERE event_id = :event_id
      ORDER BY snapshot_at DESC
      LIMIT 1
  )
ORDER BY (player->>'rank')::INTEGER
LIMIT 30;
```

---

### 2.3 Payout 컴포지션 (3개)

**대상 컴포지션**: `Payouts`, `Payouts detail`

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|--------|---------------|---------|---------------|
| `rank 1~24` | 24 | `wsop_events` | `payouts[n].place` | **정렬**: `place` 오름차순. slot 1 = 1등 상금. **추출**: JSONB 배열 순회 |
| `prize 1~24` | 24 | `wsop_events` | `payouts[n].amount` | **정렬**: 동일. **변환**: `format_currency()` (cents → "$1,000,000") |
| `percentage 1~24` | 24 | `wsop_events` | `payouts[n].percentage` | **정렬**: 동일. **변환**: `|| '%'` 접미사 추가 |

#### 데이터 추출 쿼리

```sql
SELECT
    (payout->>'place')::INTEGER AS rank,
    format_currency((payout->>'amount')::BIGINT) AS prize,
    (payout->>'percentage')::NUMERIC || '%' AS percentage
FROM wsop_events e
CROSS JOIN LATERAL jsonb_array_elements(e.payouts) AS payout
WHERE e.id = :event_id
ORDER BY (payout->>'place')::INTEGER
LIMIT 24;
```

---

### 2.4 Player Info 컴포지션 (6개)

**대상 컴포지션**: `NAME`, `NAME-DETAIL`, `Player Profile`

#### 필드 매핑 테이블

| AEP Field Key | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|---------------|---------|---------------|
| `name` | `unified_players` | `display_name` | **우선순위**: Manual > WSOP+ > GFX. **조회**: `player_name` ILIKE 매칭 |
| `name_korean` | `manual_players` | `name_korean` | **소스**: Manual DB 전용. **fallback**: 빈 문자열 |
| `country` | `unified_players` | `country_name` | **조회**: unified_players 통합 뷰. 국가명 (영문) |
| `country_flag` | `unified_players` | `country_code` | **변환**: ISO → Flag 경로. **fallback**: 'XX' (Unknown) |
| `bracelets` | `wsop_players` | `wsop_bracelets` | **조회**: LEFT JOIN wsop_players. **fallback**: 0 |
| `earnings` | `wsop_players` | `lifetime_earnings` | **변환**: `format_currency()` (cents → "$1,000,000"). **fallback**: "$0" |
| `bio` | `manual_players` | `bio` | **소스**: Manual DB 전용. **fallback**: 빈 문자열 |

#### 데이터 추출 쿼리

```sql
SELECT
    up.display_name AS name,
    mp.name_korean,
    up.country_name AS country,
    up.country_code,
    get_flag_path(up.country_code) AS flag_path,
    COALESCE(wp.wsop_bracelets, 0) AS bracelets,
    COALESCE(format_currency(wp.lifetime_earnings), '$0') AS earnings,
    mp.bio
FROM unified_players up
LEFT JOIN manual_players mp ON up.manual_player_id = mp.id
LEFT JOIN wsop_players wp ON up.wsop_player_id = wp.id
WHERE up.name ILIKE :player_name
   OR mp.name_korean ILIKE :player_name
LIMIT 1;
```

---

### 2.5 Elimination 컴포지션 (2개)

**대상 컴포지션**: `Elimination`, `Elimination_detail`

#### 필드 매핑 테이블

| AEP Field Key | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|---------------|---------|---------------|
| `name` | `gfx_hand_players` | `player_name` | **조건**: `elimination_rank > 0`. 탈락한 플레이어 이름 |
| `rank` | `gfx_hand_players` | `elimination_rank` | **조건**: `elimination_rank > 0`. 최종 순위 (탈락 순서 역순) |
| `prize` | `wsop_events` | `payouts[rank].amount` | **조회**: elimination_rank와 payouts.place 매칭. **변환**: `format_currency()`. **fallback**: "$0" |
| `country_flag` | `unified_players` | `country_code` | **우선순위**: Manual > WSOP+ > GFX. **fallback**: 'XX'. **변환**: ISO → Flag 경로 |
| `eliminated_by` | `wsop_event_players` | `eliminated_by_player_id` | **조회**: FK → unified_players.name 조인. 탈락시킨 플레이어 이름 |

#### 데이터 추출 쿼리

```sql
SELECT
    hp.player_name AS name,
    hp.elimination_rank AS rank,
    COALESCE(
        (SELECT format_currency((payout->>'amount')::BIGINT)
         FROM wsop_events e
         CROSS JOIN LATERAL jsonb_array_elements(e.payouts) AS payout
         WHERE e.id = :event_id
           AND (payout->>'place')::INTEGER = hp.elimination_rank
         LIMIT 1),
        '$0'
    ) AS prize,
    COALESCE(up.country_code, 'XX') AS country_code,
    get_flag_path(COALESCE(up.country_code, 'XX')) AS flag_path
FROM gfx_hand_players hp
LEFT JOIN unified_players up ON hp.player_name = up.name
WHERE hp.hand_id = :hand_id
  AND hp.elimination_rank > 0
ORDER BY hp.elimination_rank
LIMIT 1;
```

---

### 2.6 Event Info 컴포지션 (5개)

**대상 컴포지션**: `Event info`, `Event info detail`

#### 필드 매핑 테이블

| AEP Field Key | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|---------------|---------|---------------|
| `event_name` | `wsop_events` | `event_name` | **조회**: event_id로 조회. 이벤트 전체 이름 |
| `event_number` | `wsop_events` | `event_number` | **변환**: `'Event #' \|\| event_number` 접두사 추가 |
| `buy_in` | `wsop_events` | `buy_in` | **변환**: `format_currency()` (cents → "$10,000") |
| `entries` | `wsop_events` | `total_entries` | **변환**: `format_number()` (1000 → "1,000") |
| `prize_pool` | `wsop_events` | `prize_pool` | **변환**: `format_currency()` (cents → "$10,000,000") |
| `players_remaining` | `wsop_standings` | `players_remaining` | **조회**: 최신 snapshot. 현재 남은 플레이어 수 |
| `blind_level` | `wsop_events` | `blind_structure` | **계산**: 현재 레벨 추출. **변환**: `format_blinds()` ("10K/20K (20K ante)") |

---

### 2.7 Schedule 컴포지션 (1개)

**대상 컴포지션**: `Broadcast Schedule`

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 | 매핑 로직 상세 |
|---------------|--------|---------|---------------|
| `date 1~20` | 20 | `broadcast_sessions.broadcast_date` | **정렬**: `broadcast_date ASC`. slot 1 = 가장 빠른 날짜. **변환**: `format_date()` ("Jan 14") |
| `time 1~6` | 6 | `broadcast_sessions.scheduled_start` | **정렬**: `scheduled_start ASC`. slot 1 = 가장 이른 시간. **변환**: `format_time()` ("05:30 PM") |
| `event_name 1~6` | 6 | `broadcast_sessions.event_name` | **정렬**: 동일. 해당 시간대의 이벤트 이름 |

---

## 3. 국기 이미지 매핑

### 3.1 매핑 규칙

```
country_code (ISO 3166-1 alpha-2) → aep_media_sources.file_path
```

### 3.2 매핑 함수

```sql
-- ============================================================================
-- 함수: ISO 국가 코드 → AEP Flag 이미지 경로
-- ============================================================================

CREATE OR REPLACE FUNCTION get_flag_path(p_country_code VARCHAR(10))
RETURNS TEXT AS $$
DECLARE
    v_path TEXT;
BEGIN
    SELECT file_path INTO v_path
    FROM aep_media_sources
    WHERE country_code = UPPER(p_country_code)
      AND category = 'Flag'
    LIMIT 1;

    -- 기본값: Unknown 국기
    RETURN COALESCE(v_path, 'Flag/Unknown.png');
END;
$$ LANGUAGE plpgsql STABLE;
```

### 3.3 주요 국기 매핑 (270개 중 일부)

| country_code | country_name | AEP 파일 경로 |
|--------------|--------------|---------------|
| KR | Korea | Flag/Korea.png |
| US | United States | Flag/United States.png |
| CA | Canada | Flag/Canada.png |
| GB | United Kingdom | Flag/United Kingdom.png |
| DE | Germany | Flag/Germany.png |
| FR | France | Flag/France.png |
| JP | Japan | Flag/Japan.png |
| CN | China | Flag/China.png |
| AU | Australia | Flag/Australia.png |
| BR | Brazil | Flag/Brazil.png |
| MX | Mexico | Flag/Mexico.png |
| ES | Spain | Flag/Spain.png |
| IT | Italy | Flag/Italy.png |
| NL | Netherlands | Flag/Netherlands.png |
| SE | Sweden | Flag/Sweden.png |
| NO | Norway | Flag/Norway.png |
| FI | Finland | Flag/Finland.png |
| DK | Denmark | Flag/Denmark.png |
| XX | Unknown | Flag/Unknown.png |

---

## 4. 데이터 변환 함수

### 4.1 숫자 포맷팅 (칩 스택)

```sql
-- ============================================================================
-- 함수: 칩 스택 포맷팅
-- 입력: 1500000 → 출력: "1,500,000"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_chips(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '0';
    END IF;
    RETURN TO_CHAR(amount, 'FM999,999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 4.2 통화 포맷팅 (상금)

```sql
-- ============================================================================
-- 함수: 통화 포맷팅 (cents → dollars)
-- 입력: 100000000 (cents) → 출력: "$1,000,000"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_currency(amount_cents BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount_cents IS NULL OR amount_cents = 0 THEN
        RETURN '$0';
    END IF;
    RETURN '$' || TO_CHAR(amount_cents / 100, 'FM999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 4.3 BB 스택 계산

```sql
-- ============================================================================
-- 함수: BB 스택 계산
-- 입력: chips=1500000, bb=20000 → 출력: "75.0"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_bbs(chips BIGINT, big_blind BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF chips IS NULL OR big_blind IS NULL OR big_blind = 0 THEN
        RETURN '0';
    END IF;
    RETURN TO_CHAR(chips::NUMERIC / big_blind, 'FM999,999.9');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 4.4 날짜 포맷팅

```sql
-- ============================================================================
-- 함수: 날짜 포맷팅
-- 입력: 2026-01-14 → 출력: "Jan 14"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_date(d DATE)
RETURNS TEXT AS $$
BEGIN
    IF d IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(d, 'Mon DD');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 4.5 시간 포맷팅

```sql
-- ============================================================================
-- 함수: 시간 포맷팅
-- 입력: 17:30:00 → 출력: "05:30 PM"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_time(t TIME)
RETURNS TEXT AS $$
BEGIN
    IF t IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(t, 'HH:MI AM');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 4.6 블라인드 레벨 포맷팅

```sql
-- ============================================================================
-- 함수: 블라인드 레벨 포맷팅
-- 입력: sb=10000, bb=20000, ante=20000 → 출력: "10K/20K (20K ante)"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_blinds(sb BIGINT, bb BIGINT, ante BIGINT DEFAULT 0)
RETURNS TEXT AS $$
DECLARE
    v_result TEXT;
BEGIN
    v_result := format_chips_short(sb) || '/' || format_chips_short(bb);
    IF ante > 0 THEN
        v_result := v_result || ' (' || format_chips_short(ante) || ' ante)';
    END IF;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 보조 함수: 짧은 칩 포맷 (K/M)
CREATE OR REPLACE FUNCTION format_chips_short(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount >= 1000000 THEN
        RETURN TO_CHAR(amount / 1000000.0, 'FM999.9') || 'M';
    ELSIF amount >= 1000 THEN
        RETURN TO_CHAR(amount / 1000.0, 'FM999.9') || 'K';
    ELSE
        RETURN amount::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## 5. 렌더 큐 데이터 구조

### 5.1 render_queue.gfx_data JSONB 스키마

```json
{
  "$schema": "render_gfx_data_v1",
  "comp_name": "_MAIN Mini Chip Count",
  "render_type": "chip_count",
  "slots": [
    {
      "slot_index": 1,
      "fields": {
        "name": "Phil Ivey",
        "chips": "1,500,000",
        "rank": "1",
        "bbs": "75.0",
        "country_code": "US",
        "flag_path": "Flag/United States.png"
      }
    },
    {
      "slot_index": 2,
      "fields": {
        "name": "Daniel Negreanu",
        "chips": "1,200,000",
        "rank": "2",
        "bbs": "60.0",
        "country_code": "CA",
        "flag_path": "Flag/Canada.png"
      }
    }
  ],
  "metadata": {
    "event_id": "uuid",
    "event_name": "WSOP Main Event",
    "session_id": 123456789,
    "hand_num": 42,
    "blind_level": "10K/20K",
    "players_remaining": 50,
    "timestamp": "2026-01-14T10:30:00Z"
  }
}
```

### 5.2 렌더 타입별 스키마

| render_type | slots 구조 | 필수 metadata |
|-------------|-----------|---------------|
| `chip_count` | name, chips, rank, bbs, flag | session_id, hand_num, blind_level |
| `leaderboard` | name, chips, rank, bbs, flag | event_id, players_remaining |
| `payout` | rank, prize, percentage | event_id |
| `player_info` | name, country, bracelets, earnings | player_id |
| `elimination` | name, rank, prize, flag | hand_id, elimination_rank |
| `event_info` | event_name, buy_in, entries, prize_pool | event_id |

---

## 6. 예제 쿼리

### 6.1 Chip Count 렌더 데이터 생성

```sql
-- ============================================================================
-- Chip Count 렌더링용 데이터 추출
-- ============================================================================

WITH chip_data AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY hp.end_stack_amt DESC) AS slot_index,
        hp.player_name,
        hp.end_stack_amt,
        (h.blinds->>'big_blind_amt')::BIGINT AS big_blind,
        COALESCE(up.country_code, 'XX') AS country_code
    FROM gfx_hand_players hp
    JOIN gfx_hands h ON hp.hand_id = h.id
    LEFT JOIN unified_players up ON LOWER(hp.player_name) = LOWER(up.name)
    WHERE h.session_id = :session_id
      AND h.hand_num = :hand_num
      AND hp.sitting_out = FALSE
    ORDER BY hp.end_stack_amt DESC
    LIMIT 16
)
SELECT jsonb_build_object(
    'comp_name', '_MAIN Mini Chip Count',
    'render_type', 'chip_count',
    'slots', jsonb_agg(
        jsonb_build_object(
            'slot_index', slot_index,
            'fields', jsonb_build_object(
                'name', player_name,
                'chips', format_chips(end_stack_amt),
                'rank', slot_index::TEXT,
                'bbs', format_bbs(end_stack_amt, big_blind),
                'country_code', country_code,
                'flag_path', get_flag_path(country_code)
            )
        )
    ),
    'metadata', jsonb_build_object(
        'session_id', :session_id,
        'hand_num', :hand_num,
        'timestamp', NOW()
    )
) AS gfx_data
FROM chip_data;
```

### 6.2 Leaderboard 렌더 데이터 생성

```sql
-- ============================================================================
-- Leaderboard 렌더링용 데이터 추출
-- ============================================================================

WITH standings_data AS (
    SELECT
        (player->>'rank')::INTEGER AS slot_index,
        player->>'player_name' AS player_name,
        (player->>'chip_count')::BIGINT AS chip_count,
        (player->>'stack_in_bbs')::NUMERIC AS stack_in_bbs,
        COALESCE(player->>'country_code', 'XX') AS country_code
    FROM wsop_standings s
    CROSS JOIN LATERAL jsonb_array_elements(s.standings) AS player
    WHERE s.event_id = :event_id
      AND s.snapshot_at = (
          SELECT MAX(snapshot_at) FROM wsop_standings WHERE event_id = :event_id
      )
    ORDER BY (player->>'rank')::INTEGER
    LIMIT 30
)
SELECT jsonb_build_object(
    'comp_name', 'Feature Table Leaderboard MAIN',
    'render_type', 'leaderboard',
    'slots', jsonb_agg(
        jsonb_build_object(
            'slot_index', slot_index,
            'fields', jsonb_build_object(
                'name', player_name,
                'chips', format_chips(chip_count),
                'rank', slot_index::TEXT,
                'bbs', TO_CHAR(stack_in_bbs, 'FM999.9'),
                'country_code', country_code,
                'flag_path', get_flag_path(country_code)
            )
        )
    ),
    'metadata', jsonb_build_object(
        'event_id', :event_id,
        'timestamp', NOW()
    )
) AS gfx_data
FROM standings_data;
```

### 6.3 렌더 큐에 작업 추가

```sql
-- ============================================================================
-- 렌더 큐에 Chip Count 작업 추가
-- ============================================================================

INSERT INTO render_queue (
    render_type,
    aep_project,
    aep_comp_name,
    gfx_data,
    data_hash,
    output_format,
    output_resolution,
    priority,
    status
)
SELECT
    'chip_count',
    'CyprusDesign.aep',
    '_MAIN Mini Chip Count',
    gfx_data,
    md5(gfx_data::TEXT),
    'mp4',
    '1920x1080',
    100,
    'pending'
FROM (
    -- 위의 Chip Count 쿼리 실행
    SELECT ... AS gfx_data
) data
WHERE NOT EXISTS (
    -- 캐시 히트 체크
    SELECT 1 FROM render_queue
    WHERE data_hash = md5(data.gfx_data::TEXT)
      AND status = 'completed'
);
```

---

## 7. 슬롯 인덱스 규칙

### 7.1 AEP 레이어 네이밍 패턴

```
{field_key} {slot_index}

예시:
- "Name 1", "Name 2", ... "Name 30"
- "Chips 1", "Chips 2", ... "Chips 19"
- "Rank 1", "Rank 2", ... "Rank 25"
```

### 7.2 슬롯 인덱스 매핑

| 데이터 순서 | AEP 슬롯 | 설명 |
|------------|---------|------|
| 1st (chips 최다) | slot 1 | 1위 |
| 2nd | slot 2 | 2위 |
| 3rd | slot 3 | 3위 |
| ... | ... | ... |
| 30th | slot 30 | 30위 |

### 7.3 빈 슬롯 처리

```json
{
  "slot_index": 17,
  "fields": {
    "name": "",
    "chips": "",
    "rank": "",
    "bbs": "",
    "flag_path": ""
  }
}
```

### 7.4 슬롯 할당 규칙

각 컴포지션별 슬롯 할당 규칙 정의:

#### Chip Display (name 1~16)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | `end_stack_amt DESC` (칩 스택 내림차순) |
| **slot 1** | 가장 많은 칩 보유자 (칩 리더) |
| **slot 16** | 16번째로 많은 칩 보유자 |
| **제외 조건** | `sitting_out = TRUE` |
| **최대 슬롯** | 16 |

#### Leaderboard (name 1~30)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | WSOP+ API `rank` 필드 오름차순 |
| **slot 1** | 전체 1위 |
| **slot 30** | 전체 30위 |
| **데이터 소스** | `wsop_standings.standings` JSONB |
| **최대 슬롯** | 30 |

#### Payout (rank 1~24)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | `place ASC` (순위 오름차순) |
| **slot 1** | 1등 상금 |
| **slot 24** | 24등 상금 |
| **데이터 소스** | `wsop_events.payouts[]` JSONB |
| **최대 슬롯** | 24 |

#### Schedule (date 1~20, time 1~6)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | `broadcast_date ASC`, `scheduled_start ASC` |
| **slot 1** | 가장 빠른 날짜/시간 |
| **데이터 소스** | `broadcast_sessions` |
| **최대 슬롯** | date: 20, time: 6 |

---

## 8. 마이그레이션

### 8.1 함수 추가 마이그레이션

```sql
-- Migration: 08_gfx_aep_mapping_functions

-- 1. format_chips
CREATE OR REPLACE FUNCTION format_chips(amount BIGINT) ...;

-- 2. format_currency
CREATE OR REPLACE FUNCTION format_currency(amount_cents BIGINT) ...;

-- 3. format_bbs
CREATE OR REPLACE FUNCTION format_bbs(chips BIGINT, big_blind BIGINT) ...;

-- 4. format_date
CREATE OR REPLACE FUNCTION format_date(d DATE) ...;

-- 5. format_time
CREATE OR REPLACE FUNCTION format_time(t TIME) ...;

-- 6. format_blinds
CREATE OR REPLACE FUNCTION format_blinds(sb BIGINT, bb BIGINT, ante BIGINT) ...;

-- 7. format_chips_short
CREATE OR REPLACE FUNCTION format_chips_short(amount BIGINT) ...;

-- 8. get_flag_path
CREATE OR REPLACE FUNCTION get_flag_path(p_country_code VARCHAR(10)) ...;
```

---

## 9. 검증 체크리스트

### 9.1 데이터 무결성

- [ ] 모든 플레이어에 country_code 존재 확인
- [ ] 모든 country_code가 Flag 이미지와 매핑됨
- [ ] chips 값이 양수인지 확인
- [ ] rank 값이 연속적인지 확인

### 9.2 렌더 결과

- [ ] 모든 슬롯에 데이터 바인딩됨
- [ ] 국기 이미지 로드 성공
- [ ] 숫자 포맷 정확성 (콤마, 달러 기호)
- [ ] 출력 해상도 일치 (1920x1080)

---

## Appendix: 컴포지션-필드 키 매핑 전체 목록

| 컴포지션 | 카테고리 | 필드 키 | 슬롯 수 |
|----------|----------|---------|--------|
| _MAIN Mini Chip Count | chip_display | name, chips, rank, bbs, flag | 16 |
| _SUB_Mini Chip Count | chip_display | name, chips, rank, bbs, flag | 8 |
| Feature Table Leaderboard MAIN | leaderboard | name, chips, rank, bbs, flag | 30 |
| Feature Table Leaderboard SUB | leaderboard | name, chips, rank, bbs, flag | 30 |
| Payouts | payout | rank, prize, percentage | 24 |
| NAME | player_info | name, country, bracelets, earnings | 1 |
| Elimination | elimination | name, rank, prize, flag | 1 |
| Event info | event_info | event_name, buy_in, entries, prize_pool | 1 |
| Broadcast Schedule | schedule | date, time, event_name | 20 |
