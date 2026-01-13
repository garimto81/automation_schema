# 03. WSOP+ Database Schema

WSOP+ 플랫폼 데이터 저장을 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 1.0.0
**Date**: 2026-01-13
**Project**: Automation DB Schema

---

## 1. 개요

### 1.1 목적

WSOP+ 플랫폼에서 내보낸 JSON/CSV 파일을 정규화된 관계형 데이터베이스에 저장하여:
- 토너먼트/이벤트 정보 관리
- 플레이어 프로필 및 통계 저장
- 실시간 칩 카운트 히스토리 추적
- 순위표 스냅샷 관리
- 임포트 로그 및 오류 추적

### 1.2 데이터 소스

| 소스 타입 | 설명 |
|-----------|------|
| JSON 파일 | WSOP+ 플랫폼에서 내보낸 이벤트/플레이어 데이터 |
| CSV 파일 | 칩 카운트, 순위표 등 대량 데이터 |
| (향후) API | WSOP+ 실시간 API 연동 |

### 1.3 데이터 구조 요약

```
WSOP+ Data
├── Events (토너먼트)
│   ├── Event Info (이벤트 기본 정보)
│   ├── Payouts (상금 구조)
│   └── Schedule (일정)
│
├── Players (플레이어)
│   ├── Profile (프로필)
│   ├── Statistics (통계)
│   └── Bracelets (팔찌)
│
├── Event Players (이벤트별 참가자)
│   ├── Registration (등록 정보)
│   ├── Current Status (현재 상태)
│   └── Elimination (탈락 정보)
│
├── Chip Counts (칩 카운트)
│   └── History (히스토리)
│
└── Standings (순위표)
    └── Snapshots (스냅샷)
```

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           WSOP+ Database Schema                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐       ┌──────────────────────┐
│   wsop_events        │       │   wsop_players       │
│   (토너먼트/이벤트)   │       │   (플레이어 마스터)   │
├──────────────────────┤       ├──────────────────────┤
│ PK id: uuid          │       │ PK id: uuid          │
│ UK event_id: text    │───┐   │ UK wsop_player_id    │───┐
│    event_name: text  │   │   │    name: text        │   │
│    event_type: enum  │   │   │    country_code      │   │
│    start_date: date  │   │   │    country_name      │   │
│    end_date: date    │   │   │    profile_image_url │   │
│    buy_in: int       │   │   │    wsop_bracelets    │   │
│    total_entries     │   │   │    lifetime_earnings │   │
│    prize_pool: bigint│   │   │    created_at        │   │
│    payouts: jsonb    │   │   │    updated_at        │   │
│    status: enum      │   │   └──────────┬───────────┘   │
│    venue: text       │   │              │               │
│    created_at        │   │              │               │
│    updated_at        │   │              │               │
└──────────┬───────────┘   │              │               │
           │               │              │               │
           │ 1:N           │              │               │
           ▼               │              │               │
┌──────────────────────┐   │   ┌──────────────────────┐   │
│  wsop_event_players  │◄──┘   │   wsop_chip_counts   │   │
│  (이벤트별 참가자)    │       │   (칩 카운트 히스토리)│   │
├──────────────────────┤       ├──────────────────────┤   │
│ PK id: uuid          │       │ PK id: uuid          │   │
│ FK event_id: uuid    │       │ FK event_id: uuid    │◄──┤
│ FK player_id: uuid   │◄──────│ FK player_id: uuid   │◄──┘
│    seat_num: int     │       │    table_num: int    │
│    table_num: int    │       │    seat_num: int     │
│    starting_chips    │       │    chip_count: bigint│
│    current_chips     │       │    rank: int         │
│    rank: int         │       │    recorded_at: ts   │
│    status: enum      │       │    source: enum      │
│    eliminated_at     │       │    created_at        │
│    prize_won: bigint │       └──────────────────────┘
│    created_at        │
│    updated_at        │       ┌──────────────────────┐
└──────────────────────┘       │   wsop_standings     │
                               │   (순위표 스냅샷)     │
┌──────────────────────┐       ├──────────────────────┤
│   wsop_import_logs   │       │ PK id: uuid          │
│   (임포트 로그)       │       │ FK event_id: uuid    │◄──┐
├──────────────────────┤       │    snapshot_at: ts   │   │
│ PK id: uuid          │       │    standings: jsonb  │   │
│    file_name: text   │       │    players_remaining │   │
│    file_path: text   │       │    avg_stack: bigint │   │
│    file_hash: text   │       │    median_stack      │   │
│    file_type: enum   │       │    created_at        │   │
│    record_count: int │       └──────────────────────┘   │
│    status: enum      │                                  │
│    error_message     │──────────────────────────────────┘
│    processed_at      │
│    created_at        │
└──────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `wsop_events` 1:N `wsop_event_players` | 이벤트당 여러 참가자 |
| `wsop_players` 1:N `wsop_event_players` | 플레이어당 여러 이벤트 참가 |
| `wsop_events` 1:N `wsop_chip_counts` | 이벤트당 여러 칩 카운트 기록 |
| `wsop_players` 1:N `wsop_chip_counts` | 플레이어당 여러 칩 카운트 기록 |
| `wsop_events` 1:N `wsop_standings` | 이벤트당 여러 순위표 스냅샷 |

---

## 3. Enum 타입 정의

```sql
-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 이벤트 타입 (토너먼트 종류)
CREATE TYPE wsop_event_type AS ENUM (
    'MAIN_EVENT',       -- 메인 이벤트
    'BRACELET_EVENT',   -- 브레이슬릿 이벤트
    'SIDE_EVENT',       -- 사이드 이벤트
    'SATELLITE',        -- 새틀라이트
    'DEEPSTACK',        -- 딥스택
    'MYSTERY_BOUNTY',   -- 미스터리 바운티
    'HIGH_ROLLER',      -- 하이 롤러
    'SENIOR',           -- 시니어
    'LADIES',           -- 레이디스
    'OTHER'             -- 기타
);

-- 이벤트 상태
CREATE TYPE wsop_event_status AS ENUM (
    'upcoming',         -- 예정됨
    'registration',     -- 등록 중
    'running',          -- 진행 중
    'day_break',        -- 데이 브레이크
    'final_table',      -- 파이널 테이블
    'heads_up',         -- 헤즈업
    'completed',        -- 완료
    'cancelled'         -- 취소
);

-- 플레이어 상태 (이벤트 내)
CREATE TYPE wsop_player_status AS ENUM (
    'registered',       -- 등록됨
    'active',           -- 활성 (플레이 중)
    'eliminated',       -- 탈락
    'winner'            -- 우승자
);

-- 임포트 파일 타입
CREATE TYPE wsop_import_type AS ENUM (
    'json',             -- JSON 파일
    'csv',              -- CSV 파일
    'api'               -- API 응답
);

-- 임포트 상태
CREATE TYPE wsop_import_status AS ENUM (
    'pending',          -- 처리 대기
    'processing',       -- 처리 중
    'completed',        -- 완료
    'failed',           -- 실패
    'partial'           -- 부분 완료
);

-- 칩 카운트 소스
CREATE TYPE wsop_chip_source AS ENUM (
    'import',           -- JSON/CSV 임포트
    'manual',           -- 수동 입력
    'realtime',         -- 실시간 업데이트
    'snapshot'          -- 스냅샷
);
```

---

## 4. 테이블 DDL

### 4.1 wsop_players (플레이어 마스터)

```sql
-- ============================================================================
-- wsop_players: WSOP+ 플레이어 마스터 테이블
-- WSOP+ 플랫폼의 플레이어 프로필 정보 저장
-- ============================================================================

CREATE TABLE wsop_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- WSOP+ 플레이어 식별자
    wsop_player_id TEXT NOT NULL UNIQUE,

    -- 기본 정보
    name TEXT NOT NULL,
    name_normalized TEXT,  -- 검색용 정규화된 이름 (소문자, 특수문자 제거)
    nickname TEXT,

    -- 국적
    country_code VARCHAR(10),  -- ISO 국가 코드 (US, KR 등)
    country_name VARCHAR(100),
    city TEXT,

    -- 프로필 이미지
    profile_image_url TEXT,

    -- WSOP 통계
    wsop_bracelets INTEGER DEFAULT 0,
    wsop_rings INTEGER DEFAULT 0,
    wsop_cashes INTEGER DEFAULT 0,
    lifetime_earnings BIGINT DEFAULT 0,  -- cents 단위 저장

    -- 추가 정보 (JSONB로 유연하게)
    additional_info JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "birth_date": "1990-01-15",
        "twitter_handle": "@player",
        "instagram_handle": "@player",
        "hendon_mob_id": "12345"
    }
    */

    -- 데이터 출처
    source_file TEXT,
    source_import_id UUID,

    -- 타임스탬프
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_wsop_players_wsop_id ON wsop_players(wsop_player_id);
CREATE INDEX idx_wsop_players_name ON wsop_players(name);
CREATE INDEX idx_wsop_players_name_normalized ON wsop_players(name_normalized);
CREATE INDEX idx_wsop_players_country ON wsop_players(country_code);
CREATE INDEX idx_wsop_players_bracelets ON wsop_players(wsop_bracelets DESC);
CREATE INDEX idx_wsop_players_earnings ON wsop_players(lifetime_earnings DESC);
```

### 4.2 wsop_events (토너먼트/이벤트)

```sql
-- ============================================================================
-- wsop_events: WSOP+ 토너먼트/이벤트 정보
-- 이벤트 메타데이터 및 상금 구조 저장
-- ============================================================================

CREATE TABLE wsop_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- WSOP+ 이벤트 식별자
    event_id TEXT NOT NULL UNIQUE,

    -- 기본 정보
    event_name TEXT NOT NULL,
    event_number INTEGER,  -- 이벤트 번호 (예: Event #1)
    event_type wsop_event_type NOT NULL DEFAULT 'OTHER',

    -- 일정
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME,
    timezone TEXT DEFAULT 'UTC',

    -- 바이인 정보
    buy_in BIGINT NOT NULL,  -- cents 단위
    rake BIGINT DEFAULT 0,   -- 레이크 (cents)
    fee BIGINT DEFAULT 0,    -- 수수료 (cents)

    -- 참가자 정보
    total_entries INTEGER DEFAULT 0,
    unique_entries INTEGER DEFAULT 0,
    reentries_count INTEGER DEFAULT 0,
    starting_chips BIGINT,

    -- 블라인드 구조
    blind_structure JSONB DEFAULT '[]'::JSONB,
    /*
    [
        {"level": 1, "sb": 100, "bb": 200, "ante": 0, "duration": 60},
        {"level": 2, "sb": 150, "bb": 300, "ante": 0, "duration": 60}
    ]
    */

    -- 상금 정보
    prize_pool BIGINT DEFAULT 0,  -- cents 단위
    guaranteed_pool BIGINT,
    payouts JSONB DEFAULT '[]'::JSONB,
    /*
    [
        {"place": 1, "amount": 10000000, "percentage": 20.0},
        {"place": 2, "amount": 5000000, "percentage": 10.0}
    ]
    */

    -- 장소
    venue TEXT,
    table_count INTEGER,

    -- 상태
    status wsop_event_status DEFAULT 'upcoming',

    -- 추가 정보
    description TEXT,
    notes TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 데이터 출처
    source_file TEXT,
    source_import_id UUID,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_wsop_events_event_id ON wsop_events(event_id);
CREATE INDEX idx_wsop_events_type ON wsop_events(event_type);
CREATE INDEX idx_wsop_events_status ON wsop_events(status);
CREATE INDEX idx_wsop_events_start_date ON wsop_events(start_date DESC);
CREATE INDEX idx_wsop_events_prize_pool ON wsop_events(prize_pool DESC);
CREATE INDEX idx_wsop_events_buy_in ON wsop_events(buy_in);
CREATE INDEX idx_wsop_events_tags ON wsop_events USING GIN (tags);
```

### 4.3 wsop_event_players (이벤트별 참가자)

```sql
-- ============================================================================
-- wsop_event_players: 이벤트별 참가자 정보
-- 플레이어의 이벤트 참가 상태, 결과 저장
-- ============================================================================

CREATE TABLE wsop_event_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조
    event_id UUID NOT NULL REFERENCES wsop_events(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES wsop_players(id) ON DELETE CASCADE,

    -- 좌석 정보
    table_num INTEGER,
    seat_num INTEGER CHECK (seat_num BETWEEN 1 AND 10),

    -- 칩 정보
    starting_chips BIGINT,
    current_chips BIGINT DEFAULT 0,
    peak_chips BIGINT DEFAULT 0,

    -- 순위
    rank INTEGER,
    rank_at_end_of_day INTEGER,

    -- 상태
    status wsop_player_status DEFAULT 'registered',

    -- 탈락 정보
    eliminated_at TIMESTAMPTZ,
    eliminated_by_player_id UUID REFERENCES wsop_players(id),
    elimination_hand TEXT,  -- 탈락 핸드 설명

    -- 상금
    prize_won BIGINT DEFAULT 0,  -- cents 단위
    bounties_collected INTEGER DEFAULT 0,
    bounties_collected_amount BIGINT DEFAULT 0,

    -- 추가 정보
    notes TEXT,

    -- 데이터 출처
    source_file TEXT,
    source_import_id UUID,

    -- 타임스탬프
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_wsop_event_player UNIQUE (event_id, player_id)
);

-- 인덱스
CREATE INDEX idx_wsop_event_players_event ON wsop_event_players(event_id);
CREATE INDEX idx_wsop_event_players_player ON wsop_event_players(player_id);
CREATE INDEX idx_wsop_event_players_status ON wsop_event_players(status);
CREATE INDEX idx_wsop_event_players_rank ON wsop_event_players(rank) WHERE rank IS NOT NULL;
CREATE INDEX idx_wsop_event_players_chips ON wsop_event_players(current_chips DESC);
CREATE INDEX idx_wsop_event_players_prize ON wsop_event_players(prize_won DESC) WHERE prize_won > 0;
CREATE INDEX idx_wsop_event_players_table_seat ON wsop_event_players(table_num, seat_num)
    WHERE table_num IS NOT NULL;
```

### 4.4 wsop_chip_counts (칩 카운트 히스토리)

```sql
-- ============================================================================
-- wsop_chip_counts: 플레이어 칩 카운트 히스토리
-- 시간별 칩 카운트 변화 추적
-- ============================================================================

CREATE TABLE wsop_chip_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조
    event_id UUID NOT NULL REFERENCES wsop_events(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES wsop_players(id) ON DELETE CASCADE,

    -- 좌석 정보 (기록 시점)
    table_num INTEGER,
    seat_num INTEGER,

    -- 칩 정보
    chip_count BIGINT NOT NULL,
    chip_change BIGINT DEFAULT 0,  -- 이전 대비 변화량
    rank INTEGER,

    -- BB 기준 스택
    big_blind_at_time BIGINT,
    stack_in_bbs NUMERIC(10,2),

    -- 기록 시점
    recorded_at TIMESTAMPTZ NOT NULL,
    day_number INTEGER DEFAULT 1,  -- 몇 번째 데이
    level_number INTEGER,  -- 블라인드 레벨

    -- 소스
    source wsop_chip_source DEFAULT 'import',

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_wsop_chip_counts_event ON wsop_chip_counts(event_id);
CREATE INDEX idx_wsop_chip_counts_player ON wsop_chip_counts(player_id);
CREATE INDEX idx_wsop_chip_counts_recorded ON wsop_chip_counts(recorded_at DESC);
CREATE INDEX idx_wsop_chip_counts_event_player ON wsop_chip_counts(event_id, player_id, recorded_at DESC);
CREATE INDEX idx_wsop_chip_counts_rank ON wsop_chip_counts(rank) WHERE rank IS NOT NULL;
CREATE INDEX idx_wsop_chip_counts_day ON wsop_chip_counts(event_id, day_number);

-- 파티셔닝 고려 (대용량 데이터 시)
-- PARTITION BY RANGE (recorded_at);
```

### 4.5 wsop_standings (순위표 스냅샷)

```sql
-- ============================================================================
-- wsop_standings: 순위표 스냅샷
-- 특정 시점의 전체 순위표를 JSONB로 저장
-- ============================================================================

CREATE TABLE wsop_standings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조
    event_id UUID NOT NULL REFERENCES wsop_events(id) ON DELETE CASCADE,

    -- 스냅샷 시점
    snapshot_at TIMESTAMPTZ NOT NULL,
    day_number INTEGER DEFAULT 1,
    level_number INTEGER,

    -- 통계
    players_remaining INTEGER NOT NULL,
    players_eliminated INTEGER DEFAULT 0,
    avg_stack BIGINT,
    median_stack BIGINT,
    total_chips BIGINT,

    -- 순위표 데이터 (JSONB)
    standings JSONB NOT NULL,
    /*
    [
        {
            "rank": 1,
            "player_id": "uuid",
            "player_name": "John Doe",
            "country_code": "US",
            "chip_count": 1500000,
            "stack_in_bbs": 75.0,
            "table_num": 5,
            "seat_num": 3
        },
        ...
    ]
    */

    -- 리더 정보 (빠른 조회용)
    chip_leader_player_id UUID REFERENCES wsop_players(id),
    chip_leader_name TEXT,
    chip_leader_count BIGINT,

    -- 소스
    source wsop_chip_source DEFAULT 'import',
    source_file TEXT,
    source_import_id UUID,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 유니크 제약 (이벤트당 동일 시점 하나의 스냅샷)
    CONSTRAINT uq_wsop_standings_snapshot UNIQUE (event_id, snapshot_at)
);

-- 인덱스
CREATE INDEX idx_wsop_standings_event ON wsop_standings(event_id);
CREATE INDEX idx_wsop_standings_snapshot ON wsop_standings(snapshot_at DESC);
CREATE INDEX idx_wsop_standings_event_day ON wsop_standings(event_id, day_number);
CREATE INDEX idx_wsop_standings_remaining ON wsop_standings(players_remaining);

-- JSONB 검색용 GIN 인덱스
CREATE INDEX idx_wsop_standings_data ON wsop_standings USING GIN (standings);
```

### 4.6 wsop_import_logs (임포트 로그)

```sql
-- ============================================================================
-- wsop_import_logs: 파일 임포트 로그
-- JSON/CSV 파일 처리 이력 추적
-- ============================================================================

CREATE TABLE wsop_import_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 파일 정보
    file_name TEXT NOT NULL,
    file_path TEXT,
    file_hash TEXT NOT NULL,  -- SHA256 (중복 방지)
    file_size_bytes BIGINT,
    file_type wsop_import_type NOT NULL,

    -- 처리 대상
    target_table TEXT,  -- 'events', 'players', 'chip_counts', 'standings'
    event_id UUID REFERENCES wsop_events(id),

    -- 처리 결과
    record_count INTEGER DEFAULT 0,
    records_created INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_skipped INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,

    -- 상태
    status wsop_import_status DEFAULT 'pending',
    error_message TEXT,
    error_details JSONB,

    -- 처리 시간
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    processing_duration_ms INTEGER,

    -- 메타데이터
    imported_by TEXT,
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_wsop_import_logs_hash ON wsop_import_logs(file_hash);
CREATE INDEX idx_wsop_import_logs_status ON wsop_import_logs(status);
CREATE INDEX idx_wsop_import_logs_created ON wsop_import_logs(created_at DESC);
CREATE INDEX idx_wsop_import_logs_target ON wsop_import_logs(target_table);
CREATE INDEX idx_wsop_import_logs_event ON wsop_import_logs(event_id);
```

---

## 5. 뷰 정의

### 5.1 v_event_summary (이벤트 요약 뷰)

```sql
-- ============================================================================
-- v_event_summary: 이벤트 요약 통계
-- ============================================================================

CREATE OR REPLACE VIEW v_event_summary AS
SELECT
    e.id,
    e.event_id,
    e.event_name,
    e.event_number,
    e.event_type,
    e.start_date,
    e.buy_in,
    e.prize_pool,
    e.total_entries,
    e.status,

    -- 참가자 통계
    COUNT(ep.id) AS registered_players,
    COUNT(CASE WHEN ep.status = 'active' THEN 1 END) AS active_players,
    COUNT(CASE WHEN ep.status = 'eliminated' THEN 1 END) AS eliminated_players,

    -- 칩 리더
    (
        SELECT ep2.player_id
        FROM wsop_event_players ep2
        WHERE ep2.event_id = e.id AND ep2.status = 'active'
        ORDER BY ep2.current_chips DESC
        LIMIT 1
    ) AS chip_leader_id,

    -- 평균 스택
    AVG(ep.current_chips) FILTER (WHERE ep.status = 'active') AS avg_stack,

    e.updated_at

FROM wsop_events e
LEFT JOIN wsop_event_players ep ON e.id = ep.event_id
GROUP BY e.id
ORDER BY e.start_date DESC;
```

### 5.2 v_player_stats (플레이어 통계 뷰)

```sql
-- ============================================================================
-- v_player_stats: 플레이어 종합 통계
-- ============================================================================

CREATE OR REPLACE VIEW v_player_stats AS
SELECT
    p.id,
    p.wsop_player_id,
    p.name,
    p.country_code,
    p.country_name,
    p.wsop_bracelets,
    p.lifetime_earnings,

    -- 이벤트 통계
    COUNT(DISTINCT ep.event_id) AS events_played,
    COUNT(CASE WHEN ep.status = 'winner' THEN 1 END) AS wins,
    COUNT(CASE WHEN ep.prize_won > 0 THEN 1 END) AS cashes,

    -- 상금 통계
    SUM(ep.prize_won) AS total_prize_won,
    AVG(ep.rank) FILTER (WHERE ep.rank IS NOT NULL) AS avg_finish,

    -- 최근 활동
    MAX(ep.created_at) AS last_event_date,

    p.updated_at

FROM wsop_players p
LEFT JOIN wsop_event_players ep ON p.id = ep.player_id
GROUP BY p.id
ORDER BY p.lifetime_earnings DESC;
```

### 5.3 v_chip_count_latest (최신 칩 카운트 뷰)

```sql
-- ============================================================================
-- v_chip_count_latest: 각 이벤트/플레이어별 최신 칩 카운트
-- ============================================================================

CREATE OR REPLACE VIEW v_chip_count_latest AS
SELECT DISTINCT ON (cc.event_id, cc.player_id)
    cc.id,
    cc.event_id,
    cc.player_id,
    p.name AS player_name,
    p.country_code,
    cc.table_num,
    cc.seat_num,
    cc.chip_count,
    cc.rank,
    cc.stack_in_bbs,
    cc.recorded_at,
    cc.day_number
FROM wsop_chip_counts cc
JOIN wsop_players p ON cc.player_id = p.id
ORDER BY cc.event_id, cc.player_id, cc.recorded_at DESC;
```

### 5.4 v_leaderboard (리더보드 뷰)

```sql
-- ============================================================================
-- v_leaderboard: 이벤트별 실시간 리더보드
-- ============================================================================

CREATE OR REPLACE VIEW v_leaderboard AS
SELECT
    ep.event_id,
    e.event_name,
    ep.player_id,
    p.name AS player_name,
    p.country_code,
    p.profile_image_url,
    ep.current_chips,
    ep.rank,
    ep.table_num,
    ep.seat_num,
    ep.status,

    -- 칩 변화 (최근 기록 대비)
    ep.current_chips - COALESCE(
        (SELECT chip_count FROM wsop_chip_counts
         WHERE event_id = ep.event_id AND player_id = ep.player_id
         ORDER BY recorded_at DESC
         OFFSET 1 LIMIT 1),
        ep.starting_chips
    ) AS chip_change,

    ep.updated_at

FROM wsop_event_players ep
JOIN wsop_events e ON ep.event_id = e.id
JOIN wsop_players p ON ep.player_id = p.id
WHERE ep.status IN ('active', 'winner')
ORDER BY ep.current_chips DESC;
```

---

## 6. 함수 및 트리거

### 6.1 updated_at 자동 갱신

```sql
-- ============================================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================================

CREATE OR REPLACE FUNCTION update_wsop_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_wsop_players_updated_at
    BEFORE UPDATE ON wsop_players
    FOR EACH ROW
    EXECUTE FUNCTION update_wsop_updated_at_column();

CREATE TRIGGER update_wsop_events_updated_at
    BEFORE UPDATE ON wsop_events
    FOR EACH ROW
    EXECUTE FUNCTION update_wsop_updated_at_column();

CREATE TRIGGER update_wsop_event_players_updated_at
    BEFORE UPDATE ON wsop_event_players
    FOR EACH ROW
    EXECUTE FUNCTION update_wsop_updated_at_column();
```

### 6.2 플레이어 이름 정규화

```sql
-- ============================================================================
-- 함수: 플레이어 이름 정규화 (검색용)
-- ============================================================================

CREATE OR REPLACE FUNCTION normalize_player_name(p_name TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(
        REGEXP_REPLACE(
            TRIM(p_name),
            '[^a-zA-Z0-9가-힣\s]',
            '',
            'g'
        )
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 플레이어 삽입/수정 시 자동 정규화
CREATE OR REPLACE FUNCTION set_normalized_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.name_normalized = normalize_player_name(NEW.name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER normalize_wsop_player_name
    BEFORE INSERT OR UPDATE ON wsop_players
    FOR EACH ROW
    EXECUTE FUNCTION set_normalized_name();
```

### 6.3 이벤트 통계 업데이트

```sql
-- ============================================================================
-- 함수: 이벤트 참가자 통계 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_event_player_stats(p_event_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_entries INTEGER;
    v_avg_stack BIGINT;
BEGIN
    -- 총 참가자 수
    SELECT COUNT(*)
    INTO v_total_entries
    FROM wsop_event_players
    WHERE event_id = p_event_id;

    -- 평균 스택 (활성 플레이어 기준)
    SELECT AVG(current_chips)::BIGINT
    INTO v_avg_stack
    FROM wsop_event_players
    WHERE event_id = p_event_id AND status = 'active';

    -- 이벤트 업데이트
    UPDATE wsop_events
    SET
        total_entries = v_total_entries,
        updated_at = NOW()
    WHERE id = p_event_id;
END;
$$ LANGUAGE plpgsql;
```

### 6.4 순위 자동 계산

```sql
-- ============================================================================
-- 함수: 이벤트 내 플레이어 순위 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_event_rankings(p_event_id UUID)
RETURNS VOID AS $$
BEGIN
    -- 활성 플레이어 순위 업데이트
    UPDATE wsop_event_players ep
    SET rank = ranking.new_rank
    FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (ORDER BY current_chips DESC) AS new_rank
        FROM wsop_event_players
        WHERE event_id = p_event_id AND status = 'active'
    ) ranking
    WHERE ep.id = ranking.id AND ep.event_id = p_event_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 7. 인덱스 전략 및 쿼리 패턴

### 7.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 이벤트 목록 조회 | `ORDER BY start_date DESC` | `idx_wsop_events_start_date` |
| 이벤트별 참가자 | `WHERE event_id = ?` | `idx_wsop_event_players_event` |
| 플레이어 검색 | `WHERE name_normalized LIKE ?` | `idx_wsop_players_name_normalized` |
| 칩 리더 조회 | `WHERE status = 'active' ORDER BY current_chips DESC` | `idx_wsop_event_players_chips` |
| 칩 히스토리 | `WHERE event_id = ? AND player_id = ?` | `idx_wsop_chip_counts_event_player` |
| 순위표 스냅샷 | `WHERE event_id = ? ORDER BY snapshot_at DESC` | `idx_wsop_standings_event` |
| 파일 중복 체크 | `WHERE file_hash = ?` | `idx_wsop_import_logs_hash` |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- wsop_players.id, wsop_events.id, wsop_event_players.id, etc.

-- Unique Constraints
-- wsop_players.wsop_player_id
-- wsop_events.event_id
-- (event_id, player_id), (event_id, snapshot_at)

-- B-tree Indexes (범위/정렬 쿼리)
-- wsop_events: start_date DESC, prize_pool DESC
-- wsop_event_players: current_chips DESC
-- wsop_chip_counts: recorded_at DESC

-- GIN Indexes (배열/JSONB 검색)
-- wsop_events.tags
-- wsop_standings.standings

-- Partial Indexes (조건부 최적화)
-- wsop_event_players.rank WHERE rank IS NOT NULL
-- wsop_event_players.prize_won WHERE prize_won > 0
```

---

## 8. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE wsop_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_event_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_chip_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_standings ENABLE ROW LEVEL SECURITY;
ALTER TABLE wsop_import_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- wsop_players 정책
-- ============================================================================
CREATE POLICY "wsop_players_select_authenticated"
    ON wsop_players FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "wsop_players_insert_service"
    ON wsop_players FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "wsop_players_update_service"
    ON wsop_players FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- wsop_events 정책
-- ============================================================================
CREATE POLICY "wsop_events_select_authenticated"
    ON wsop_events FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "wsop_events_insert_service"
    ON wsop_events FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "wsop_events_update_service"
    ON wsop_events FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- wsop_event_players 정책
-- ============================================================================
CREATE POLICY "wsop_event_players_select_authenticated"
    ON wsop_event_players FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "wsop_event_players_insert_service"
    ON wsop_event_players FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "wsop_event_players_update_service"
    ON wsop_event_players FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- wsop_chip_counts 정책
-- ============================================================================
CREATE POLICY "wsop_chip_counts_select_authenticated"
    ON wsop_chip_counts FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "wsop_chip_counts_insert_service"
    ON wsop_chip_counts FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- wsop_standings 정책
-- ============================================================================
CREATE POLICY "wsop_standings_select_authenticated"
    ON wsop_standings FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "wsop_standings_insert_service"
    ON wsop_standings FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- wsop_import_logs 정책
-- ============================================================================
CREATE POLICY "wsop_import_logs_select_authenticated"
    ON wsop_import_logs FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "wsop_import_logs_all_service"
    ON wsop_import_logs FOR ALL
    USING (auth.role() = 'service_role');
```

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. wsop_players 테이블 생성
3. wsop_events 테이블 생성
4. wsop_event_players 테이블 생성
5. wsop_chip_counts 테이블 생성
6. wsop_standings 테이블 생성
7. wsop_import_logs 테이블 생성
8. 뷰 생성 (CREATE VIEW)
9. 함수 생성 (CREATE FUNCTION)
10. 트리거 생성 (CREATE TRIGGER)
11. 인덱스 생성 (CREATE INDEX)
12. RLS 정책 적용 (ALTER TABLE, CREATE POLICY)
```

### Rollback 순서 (역순)

```
1. RLS 정책 삭제 (DROP POLICY)
2. 인덱스 삭제 (DROP INDEX)
3. 트리거 삭제 (DROP TRIGGER)
4. 함수 삭제 (DROP FUNCTION)
5. 뷰 삭제 (DROP VIEW)
6. 테이블 삭제 (역순: wsop_import_logs → wsop_standings → ...)
7. ENUM 타입 삭제 (DROP TYPE)
```

---

## 10. 제약조건 요약

| 테이블 | 제약조건 | 설명 |
|--------|----------|------|
| `wsop_players` | `wsop_player_id UNIQUE` | WSOP+ ID 중복 방지 |
| `wsop_events` | `event_id UNIQUE` | 이벤트 ID 중복 방지 |
| `wsop_event_players` | `(event_id, player_id) UNIQUE` | 이벤트당 플레이어 중복 방지 |
| `wsop_event_players` | `seat_num BETWEEN 1 AND 10` | 유효 시트 번호 |
| `wsop_standings` | `(event_id, snapshot_at) UNIQUE` | 스냅샷 시점 중복 방지 |

---

## 11. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `src/importers/wsop_json_importer.py` | JSON 파일 임포트 | 모든 테이블 |
| `src/importers/wsop_csv_importer.py` | CSV 파일 임포트 | chip_counts, standings |
| `src/models/wsop_event.py` | 도메인 모델 | wsop_events |
| `src/models/wsop_player.py` | 도메인 모델 | wsop_players |
| `src/services/chip_count_service.py` | 칩 카운트 서비스 | chip_counts |

---

## Appendix: 상금 금액 단위

모든 금액 필드는 **cents (센트) 단위**로 저장:

| 표시 금액 | 저장 값 |
|-----------|---------|
| $1.00 | 100 |
| $100.00 | 10000 |
| $1,000,000.00 | 100000000 |

이유:
- 부동소수점 오차 방지
- 정수 연산으로 정확한 계산
- BIGINT로 최대 $92,233,720,368,547,758.07 까지 저장 가능
