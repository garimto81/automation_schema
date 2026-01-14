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

### 2.1 Chip Display 컴포지션 (9개 슬롯)

**대상 컴포지션**: `_MAIN Mini Chip Count`, `_SUB_Mini Chip Count`

> **Note**: 실제 AEP 분석 결과 슬롯 수는 **9개**입니다. (full_analysis.json 기준)

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|--------|---------------|---------|---------------|
| `name 1~9` | 9 | `gfx_hand_players` | `player_name` | **정렬**: `end_stack_amt DESC`. slot 1 = 칩 리더. `sitting_out = TRUE` 제외. **Case-Insensitive**: `name`, `Name` 모두 매칭 |
| `chip 1~9` | 9 | `gfx_hand_players` | `end_stack_amt` | **정렬**: 동일. **변환**: `format_chips()` (1500000 → "1,500,000"). **Case-Insensitive**: `chip`, `Chip` 모두 매칭 |
| `rank 1~9` | 9 | (계산) | - | **계산**: `ROW_NUMBER() OVER (ORDER BY end_stack_amt DESC)`. rank = slot_index |
| `bbs 1~9` | 9 | (계산) | - | **계산**: `end_stack_amt / big_blind_amt`. **변환**: `format_bbs()` (소수점 1자리) |
| `country_flag 1~9` | 9 | `manual_players` | `country_code` | **⚠️ GFX JSON에 없음** → Manual DB 전용. **fallback**: 'XX' (Unknown). **변환**: ISO → Flag 경로 |

#### 특수 필드

| AEP Layer Name | 용도 | 매핑 로직 |
|----------------|------|-----------|
| `AVERAGE STACK : ...` | 평균 스택 표시 | `AVG(end_stack_amt)` 계산 후 포맷팅 |

#### 데이터 추출 쿼리

```sql
SELECT
    ROW_NUMBER() OVER (ORDER BY hp.end_stack_amt DESC) AS rank,
    hp.player_name AS name,
    format_chips(hp.end_stack_amt) AS chips,
    format_bbs(hp.end_stack_amt, (h.blinds->>'big_blind_amt')::BIGINT) AS bbs,
    -- country_code는 GFX JSON에 없음 → Manual DB에서 조회
    COALESCE(mp.country_code, 'XX') AS country_code,
    get_flag_path(COALESCE(mp.country_code, 'XX')) AS flag_path
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
LEFT JOIN manual_players mp ON LOWER(hp.player_name) = LOWER(mp.name)
WHERE hp.sitting_out = FALSE
  AND h.session_id = :session_id
  AND h.hand_num = :hand_num
ORDER BY hp.end_stack_amt DESC
LIMIT 9;
```

---

### 2.2 Leaderboard 컴포지션 (9개 슬롯)

**대상 컴포지션**: `_Feature Table Leaderboard` (메인), `Feature Table Leaderboard MAIN`, `Feature Table Leaderboard SUB` (소스 컴프)

> **Note**: AEP 분석 결과 실제 슬롯 수는 **9개**입니다. (full_analysis.json 기준)

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|--------|---------------|---------|---------------|
| `Name 1~9` | 9 | `wsop_standings` | `standings->>'player_name'` | **정렬**: JSONB `rank` 필드 오름차순. slot 1 = 전체 1위. **Case-Insensitive** |
| `Chips 1~9` | 9 | `wsop_standings` | `standings->>'chip_count'` | **정렬**: 동일. **변환**: `format_chips()` (1500000 → "1,500,000"). **Case-Insensitive** |
| `Date 1~9` | 9 | (계산) | - | **⚠️ 순위 번호 표시용** (1, 2, 3...). 날짜 아님. `ROW_NUMBER()` 사용 |
| `Flag 1~9` | 8 | `manual_players` | `country_code` | **⚠️ Flag 3 누락** (1,2,4,5,6,7,8,9만 존재). **fallback**: 'XX'. **Case-Insensitive** |

> **⚠️ BBs 슬롯 없음**: `bbs` 레이어는 헤더 텍스트만 존재하고 데이터 슬롯 (`BBs 1~9`)은 없습니다. BB 값은 Chips 레이어에 포함하거나 별도 처리 필요.

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
    -- country_code는 GFX JSON에 없음 → Manual DB에서 조회
    COALESCE(mp.country_code, 'XX') AS country_code,
    get_flag_path(COALESCE(mp.country_code, 'XX')) AS flag_path
FROM wsop_standings s
CROSS JOIN LATERAL jsonb_array_elements(s.standings) AS player
LEFT JOIN manual_players mp ON LOWER(player->>'player_name') = LOWER(mp.name)
WHERE s.event_id = :event_id
  AND s.id = (
      SELECT id FROM wsop_standings
      WHERE event_id = :event_id
      ORDER BY snapshot_at DESC
      LIMIT 1
  )
ORDER BY (player->>'rank')::INTEGER
LIMIT 9;
```

---

### 2.3 Payout 컴포지션 (9~12개 슬롯)

**대상 컴포지션**: `_Mini Payout`

> **Note**: 실제 AEP 분석 결과 슬롯 수는 **9개** (일부 컴포지션 12개). (full_analysis.json 기준)

#### 필드 매핑 테이블

| AEP Field Key | 슬롯 수 | DB 소스 테이블 | DB 컬럼 | 매핑 로직 상세 |
|---------------|--------|---------------|---------|---------------|
| `Rank 1~9` | 9 | `wsop_events` | `payouts[n].place` | **정렬**: `place` 오름차순. slot 1 = 1등 상금. **Case-Insensitive** |
| `Name 1~9` | 9 | `wsop_standings` | `standings->>'player_name'` | 해당 순위 플레이어 이름. **Case-Insensitive** |
| `prize 1~9` | 9 | `wsop_events` | `payouts[n].amount` | **정렬**: 동일. **변환**: `format_currency()`. **Case-Insensitive** |

#### 특수 필드

| AEP Layer Name | 용도 | 매핑 로직 |
|----------------|------|-----------|
| `Total Prize $...` | 총 상금 표시 | `wsop_events.prize_pool` 포맷팅 |

#### 데이터 추출 쿼리

```sql
SELECT
    (payout->>'place')::INTEGER AS rank,
    format_currency((payout->>'amount')::BIGINT) AS prize
FROM wsop_events e
CROSS JOIN LATERAL jsonb_array_elements(e.payouts) AS payout
WHERE e.id = :event_id
ORDER BY (payout->>'place')::INTEGER
LIMIT 9;
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

### 2.5 Elimination 컴포지션 (고정 레이어)

**대상 컴포지션**: `Elimination`

> **⚠️ 구조 주의**: 슬롯 기반이 아닌 **고정 텍스트 레이어** 구조입니다.

#### 레이어 구조 (full_analysis.json 기준)

| AEP Layer (예시) | 레이어 타입 | 매핑 데이터 |
|------------------|------------|-------------|
| `Turkey.png` | AVLayer (Flag) | 국가 코드 → Flag 이미지 경로 |
| `Mehmet Dalkilic` | TextLayer | 플레이어 이름 (직접 텍스트 교체) |
| `ELIMINATED IN 10TH PLACE ($64,600)` | TextLayer | **복합 필드**: 순위 + 상금 결합 |

> **Note**: `rank`, `prize` 필드가 분리되지 않고 하나의 텍스트 레이어에 결합되어 있습니다.

#### 매핑 로직

| 데이터 | DB 소스 | 변환 로직 |
|--------|---------|-----------|
| 플레이어 이름 | `gfx_hand_players.player_name` | 직접 텍스트 교체 |
| 국기 | `manual_players.country_code` | ISO → Flag 이미지 경로 |
| 탈락 정보 | (계산) | `ELIMINATED IN {rank}TH PLACE (${prize})` 포맷 |

#### 데이터 추출 쿼리

```sql
SELECT
    hp.player_name AS name,
    hp.elimination_rank AS rank,
    format_currency((
        SELECT (payout->>'amount')::BIGINT
        FROM wsop_events e
        CROSS JOIN LATERAL jsonb_array_elements(e.payouts) AS payout
        WHERE e.id = :event_id
          AND (payout->>'place')::INTEGER = hp.elimination_rank
        LIMIT 1
    )) AS prize,
    -- 탈락 정보 텍스트 생성
    'ELIMINATED IN ' || hp.elimination_rank ||
        CASE
            WHEN hp.elimination_rank = 1 THEN 'ST'
            WHEN hp.elimination_rank = 2 THEN 'ND'
            WHEN hp.elimination_rank = 3 THEN 'RD'
            ELSE 'TH'
        END || ' PLACE (' || format_currency(...) || ')' AS elimination_text,
    get_flag_path(COALESCE(up.country_code, 'XX')) AS flag_path
FROM gfx_hand_players hp
LEFT JOIN unified_players up ON hp.player_name = up.name
WHERE hp.hand_id = :hand_id
  AND hp.elimination_rank > 0
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

> **Note**: 모든 필드 키는 **Case-Insensitive** 매핑됩니다.

#### Chip Display (name 1~9)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | `end_stack_amt DESC` (칩 스택 내림차순) |
| **slot 1** | 가장 많은 칩 보유자 (칩 리더) |
| **slot 9** | 9번째로 많은 칩 보유자 |
| **제외 조건** | `sitting_out = TRUE` |
| **최대 슬롯** | 9 |
| **필드 매칭** | `name`, `Name` 모두 매칭 (Case-Insensitive) |

#### Leaderboard (Name 1~9)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | WSOP+ API `rank` 필드 오름차순 |
| **slot 1** | 전체 1위 |
| **slot 9** | 전체 9위 |
| **데이터 소스** | `wsop_standings.standings` JSONB |
| **최대 슬롯** | 9 |
| **참고** | Date 필드 = 순위 번호, BBs 슬롯 없음 |

#### Payout (Rank 1~9)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | `place ASC` (순위 오름차순) |
| **slot 1** | 1등 상금 |
| **slot 9** | 9등 상금 |
| **데이터 소스** | `wsop_events.payouts[]` JSONB |
| **최대 슬롯** | 9 (일부 컴포지션 12) |

#### Schedule (date 1~20, time 1~6)

| 항목 | 값 |
|------|-----|
| **정렬 기준** | `broadcast_date ASC`, `scheduled_start ASC` |
| **slot 1** | 가장 빠른 날짜/시간 |
| **데이터 소스** | `broadcast_sessions` |
| **최대 슬롯** | date: 20, time: 6 |

---

## 7.5 레이어 이름 매칭 규칙

### 7.5.1 Case-Insensitive 매핑

AEP 템플릿의 레이어 이름은 대소문자가 일관되지 않으므로, 매핑 로직에서 **대소문자를 무시**하고 매칭합니다.

| 필드 패턴 | 매칭되는 레이어 예시 |
|-----------|---------------------|
| `name` | `name 1`, `Name 4`, `NAME 5` |
| `chip` | `Chip 1`, `chip 2`, `chips 3` |
| `rank` | `Rank 1`, `rank 2` |
| `flag` | `Flag 1`, `flag 2` |

### 7.5.2 매핑 함수 (PostgreSQL)

```sql
-- ============================================================================
-- 함수: 레이어 이름 패턴 매칭 (Case-Insensitive)
-- 입력: layer_name='Name 4', field_pattern='name' → 출력: TRUE
-- ============================================================================

CREATE OR REPLACE FUNCTION match_layer_pattern(
    layer_name TEXT,
    field_pattern TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    -- 대소문자 무시하고 "패턴 + 공백 + 숫자" 형태 매칭
    RETURN LOWER(layer_name) ~ ('^' || LOWER(field_pattern) || ' \d+$');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 7.5.3 Python 매핑 로직

```python
import re

def match_layer(layer_name: str, field_key: str) -> bool:
    """레이어 이름이 필드 키 패턴과 일치하는지 확인 (Case-Insensitive)"""
    pattern = rf'^{re.escape(field_key)}\s+\d+$'
    return bool(re.match(pattern, layer_name, re.IGNORECASE))

def extract_slot_index(layer_name: str, field_key: str) -> int | None:
    """레이어 이름에서 슬롯 인덱스 추출"""
    pattern = rf'^{re.escape(field_key)}\s+(\d+)$'
    match = re.match(pattern, layer_name, re.IGNORECASE)
    return int(match.group(1)) if match else None
```

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

> **Note**: 모든 필드 키는 **Case-Insensitive** 매핑됩니다. (`name` = `Name` = `NAME`)

| 컴포지션 | 카테고리 | 필드 키 | 슬롯 수 | 비고 |
|----------|----------|---------|--------|------|
| _MAIN Mini Chip Count | chip_display | name, chip | 9 | `AVERAGE STACK` 특수 필드 포함 |
| _SUB_Mini Chip Count | chip_display | name, chip | 9 | |
| _Feature Table Leaderboard | leaderboard | (메인 컴프) | - | MAIN/SUB 서브컴프 포함 |
| Feature Table Leaderboard MAIN | leaderboard | Name, Chips, Date, Flag | 9 | ⚠️ Date=순위번호, BBs 슬롯 없음 |
| Feature Table Leaderboard SUB | leaderboard | Name, Chips, Date, Flag | 9 | |
| _Mini Payout | payout | Rank, Name, prize | 9 | `Total Prize` 특수 필드 포함 |
| NAME | player_info | name, country, bracelets, earnings | 1 | |
| Elimination | elimination | (고정 레이어) | 1 | 복합 텍스트 레이어 구조 |
| Event info | event_info | event_name, buy_in, entries, prize_pool | 1 | |
| Broadcast Schedule | schedule | date, time, event_name | 20 | |
