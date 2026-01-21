# json 스키마 샘플 데이터 사용 가이드

## 개요

json 스키마에 Texas Hold'em 포커 핸드 샘플 데이터를 삽입합니다.
트리거가 자동으로 public 스키마에 동기화합니다.

## 데이터 구조

### 세션
- **Session ID**: 638962967524560999
- **Event**: WSOP Super Circuit Cyprus - Main Event Day 2
- **Hands**: 3개 (A급, B급, C급)

### 핸드 시나리오

| Hand | Grade | 시나리오 | Pot Size | Players | Showdown |
|:----:|:-----:|---------|:--------:|:-------:|:--------:|
| 1 | A | Full House vs Flush | 128K | 8 | ✓ |
| 2 | B | Preflop All-in (AA vs KK) | 224K | 6 | ✓ |
| 3 | C | River Fold | 18K | 7 | ✗ |

#### Hand 1 (A급): Full House vs Flush
- **Winner**: Ipekoglu (AdAc) - Full House, Aces full of Sevens
- **Loser**: Khordbin (KhQh) - Flush, Ace high
- **Board**: Ah As Kh 7d 7s
- **Action**: Preflop raise → Flop bet → Turn bet → River all-in call
- **Duration**: 245초 (4분 5초)

#### Hand 2 (B급): AA vs KK All-in
- **Winner**: Ipekoglu (AhAd) - Pair of Aces
- **Loser**: Cucchiara (KcKd) - Pair of Kings
- **Board**: 2h 9c Qd 5s 8h
- **Action**: Preflop 3-bet → 4-bet → All-in call
- **Duration**: 185초 (3분 5초)

#### Hand 3 (C급): River Fold
- **Winner**: Ipekoglu (카드 미공개)
- **Loser**: Khordbin (카드 미공개)
- **Board**: 3c 7d Jh 9s (Turn까지만)
- **Action**: Preflop limp → Flop check → Turn bet → River fold
- **Duration**: 95초 (1분 35초)

## 삽입되는 데이터

| 테이블 | 레코드 수 | 설명 |
|--------|:--------:|------|
| `json.gfx_sessions` | 1 | 세션 메타데이터 |
| `json.hands` | 3 | 핸드 정보 (A/B/C급) |
| `json.hand_players` | 21 | 핸드별 플레이어 (8+6+7명) |
| `json.hand_actions` | 53 | 액션/이벤트 |
| `json.hand_cards` | 22 | 홀카드 + 커뮤니티 카드 |
| `json.hand_results` | 4 | 쇼다운 결과 (Hand 1-2만) |

## 사용 방법

### 1. 샘플 데이터 삽입

```bash
# Supabase CLI 사용
supabase db reset  # 기존 데이터 초기화 (선택)
psql $SUPABASE_DB_URL -f supabase/sample_data_json_schema.sql
```

### 2. 데이터 검증

```bash
# 검증 쿼리 실행
psql $SUPABASE_DB_URL -f supabase/verify_sample_data_json.sql
```

### 3. 예상 출력

```
===== 데이터 무결성 검증 =====
check_name              | result
------------------------+---------
hand_count_match        | ✓ PASS
pot_size_match_hand1    | ✓ PASS
winner_amount_match_hand1 | ✓ PASS
card_count_hand1        | ✓ PASS
sync_trigger_sessions   | ✓ PASS (트리거 동작)
sync_trigger_hands      | ✓ PASS (3개 핸드 동기화)
```

## 트리거 동기화 확인

샘플 데이터 삽입 후 자동으로 실행되는 트리거:

| json 스키마 | 트리거 함수 | public 스키마 |
|------------|------------|--------------|
| `json.gfx_sessions` | `sync_json_gfx_sessions_to_public()` | `public.gfx_sessions` |
| `json.hands` | `sync_json_hands_to_public()` | `public.gfx_hands` |
| `json.hand_players` | `sync_json_hand_players_to_public()` | `public.gfx_hand_players` |
| `json.hand_actions` | `sync_json_hand_actions_to_public()` | `public.gfx_events` |
| `json.hand_cards` | `sync_json_hand_cards_to_public()` | `public.gfx_hand_cards` |
| `json.hand_results` | `sync_json_hand_results_to_public()` | `public.gfx_hand_results` |

## 쿼리 예시

### json 스키마 조회

```sql
-- 세션 정보
SELECT * FROM json.gfx_sessions WHERE id = 638962967524560999;

-- A급 핸드 조회
SELECT * FROM json.hands WHERE session_id = 638962967524560999 AND grade = 'A';

-- Hand 1 쇼다운 플레이어
SELECT
    seat_number,
    player_name,
    hole_cards,
    is_winner,
    won_amount
FROM json.hand_players
WHERE session_id = 638962967524560999
  AND hand_number = 1
  AND has_shown_cards = TRUE
ORDER BY seat_number;
```

### public 스키마 조회 (트리거 동기화 확인)

```sql
-- 세션 확인
SELECT session_id, file_name, hand_count, sync_status
FROM public.gfx_sessions
WHERE session_id = 638962967524560999;

-- 핸드 등급별 통계
SELECT
    grade,
    COUNT(*) as hand_count,
    AVG(pot_size) as avg_pot,
    AVG(duration_seconds) as avg_duration
FROM public.gfx_hands
WHERE session_id = 638962967524560999
GROUP BY grade
ORDER BY grade;

-- 카드 타입별 통계
SELECT
    h.hand_num,
    c.card_type,
    COUNT(*) as card_count
FROM public.gfx_hands h
JOIN public.gfx_hand_cards c ON h.id = c.hand_id
WHERE h.session_id = 638962967524560999
GROUP BY h.hand_num, c.card_type
ORDER BY h.hand_num, c.card_type;
```

## 데이터 초기화

```sql
-- json 스키마 샘플 데이터 삭제
DELETE FROM json.hand_results WHERE session_id = 638962967524560999;
DELETE FROM json.hand_cards WHERE session_id = 638962967524560999;
DELETE FROM json.hand_actions WHERE session_id = 638962967524560999;
DELETE FROM json.hand_players WHERE session_id = 638962967524560999;
DELETE FROM json.hands WHERE session_id = 638962967524560999;
DELETE FROM json.gfx_sessions WHERE id = 638962967524560999;

-- public 스키마는 CASCADE로 자동 삭제됨
```

## 트러블슈팅

### 트리거가 동작하지 않는 경우

```sql
-- 트리거 상태 확인
SELECT
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'json'
  AND event_object_table IN ('gfx_sessions', 'hands', 'hand_players', 'hand_actions', 'hand_cards', 'hand_results');

-- 트리거 수동 활성화
SELECT enable_json_sync_triggers();
```

### FK 제약 위반 (hand_id 누락)

json 스키마에서 public 스키마로 동기화 시 FK 관계가 생성됩니다.
만약 public.gfx_hands에 데이터가 없으면 hand_players, events 등이 실패합니다.

**해결책**: 데이터 삽입 순서 준수
1. gfx_sessions
2. hands
3. hand_players, hand_actions, hand_cards, hand_results (병렬 가능)

## 참고 문서

- **스키마 정의**: `docs/02-GFX-JSON-DB.md`
- **트리거 마이그레이션**: `supabase/migrations/20260120000000_json_public_sync_triggers.sql`
- **public 스키마 확장**: `supabase/migrations/20260119000000_json_public_schema_integration.sql`
