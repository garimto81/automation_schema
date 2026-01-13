# 05. Cuesheet Database Schema

방송 진행 큐시트 관리를 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 1.0.0
**Date**: 2026-01-13
**Project**: Automation DB Schema

---

## 1. 개요

### 1.1 목적

포커 방송의 진행 순서 및 GFX 출력을 관리하여:
- 방송 세션 및 큐시트 관리
- 개별 큐 아이템 (GFX 요소) 순서 제어
- 큐 템플릿으로 재사용 가능한 구성 저장
- GFX 트리거 및 렌더링 상태 추적
- 실시간 방송 진행 모니터링

### 1.2 큐시트 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Cuesheet Workflow                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   방송 세션    │────▶│   큐시트      │────▶│   큐 아이템    │
│   (Session)   │  1:N│   (Sheet)     │  1:N│   (Item)      │
└───────────────┘     └───────────────┘     └───────┬───────┘
                                                    │
                                                    │ trigger
                                                    ▼
                      ┌───────────────┐     ┌───────────────┐
                      │   큐 템플릿    │     │  GFX 트리거   │
                      │   (Template)  │────▶│   (Trigger)   │
                      └───────────────┘     └───────┬───────┘
                                                    │
                                                    │ render
                                                    ▼
                                            ┌───────────────┐
                                            │   AEP 렌더    │
                                            │   (Output)    │
                                            └───────────────┘
```

### 1.3 핵심 기능

| 기능 | 설명 |
|------|------|
| **세션 관리** | 방송 일정, 스태프, 상태 관리 |
| **큐시트 관리** | 방송 구간별 큐시트 구성 |
| **큐 아이템** | 개별 GFX 요소 순서/타이밍 제어 |
| **템플릿** | 재사용 가능한 큐 구성 저장 |
| **트리거 로그** | GFX 송출 이력 추적 |

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Cuesheet Database Schema                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│  broadcast_sessions  │
│  (방송 세션)          │
├──────────────────────┤
│ PK id: uuid          │
│ UK session_code: text│───┐
│    event_name: text  │   │
│    event_id: uuid    │   │  FK to wsop_events (optional)
│    broadcast_date    │   │
│    scheduled_start   │   │
│    scheduled_end     │   │
│    actual_start      │   │
│    actual_end        │   │
│    status: enum      │   │
│    director: text    │   │
│    technical_director│   │
│    commentators: jsonb│  │
│    settings: jsonb   │   │
│    notes: text       │   │
│    created_at        │   │
│    updated_at        │   │
└──────────┬───────────┘   │
           │               │
           │ 1:N           │
           ▼               │
┌──────────────────────┐   │
│     cue_sheets       │   │
│     (큐시트)         │   │
├──────────────────────┤   │
│ PK id: uuid          │   │
│ UK sheet_code: text  │   │
│ FK session_id: uuid  │◄──┘
│    sheet_name: text  │
│    sheet_type: enum  │
│    sheet_order: int  │
│    version: int      │
│    status: enum      │
│    total_items: int  │
│    completed_items   │
│    current_item_id   │───────────────────┐
│    notes: text       │                   │
│    created_by        │                   │
│    created_at        │                   │
│    updated_at        │                   │
└──────────┬───────────┘                   │
           │                               │
           │ 1:N                           │
           ▼                               │
┌──────────────────────┐                   │
│     cue_items        │◄──────────────────┘
│   (큐 아이템)        │
├──────────────────────┤
│ PK id: uuid          │
│ FK sheet_id: uuid    │
│ FK template_id: uuid │◄──────────────────┐
│    cue_number: text  │                   │
│    cue_type: enum    │                   │
│    title: text       │                   │
│    description: text │                   │
│    gfx_template_name │                   │
│    gfx_comp_name     │                   │
│    gfx_data: jsonb   │                   │
│    duration_seconds  │                   │
│    scheduled_time    │                   │
│    actual_time       │                   │
│    status: enum      │                   │
│    sort_order: int   │                   │
│    depends_on: uuid[]│                   │
│    notes: text       │                   │
│    created_at        │                   │
│    updated_at        │                   │
└──────────┬───────────┘                   │
           │                               │
           │ 1:N                           │
           ▼                               │
┌──────────────────────┐   ┌──────────────────────┐
│    gfx_triggers      │   │   cue_templates      │
│   (GFX 트리거 로그)   │   │   (큐 템플릿)        │
├──────────────────────┤   ├──────────────────────┤
│ PK id: uuid          │   │ PK id: uuid          │
│ FK cue_item_id: uuid │   │ UK template_code     │───┘
│ FK session_id: uuid  │   │    template_name     │
│    trigger_type: enum│   │    cue_type: enum    │
│    trigger_time: ts  │   │    gfx_template_name │
│    triggered_by: text│   │    gfx_comp_name     │
│    aep_comp_name     │   │    default_duration  │
│    gfx_data: jsonb   │   │    data_schema: jsonb│
│    render_status:enum│   │    sample_data: jsonb│
│    render_job_id     │   │    preview_image_url │
│    output_path: text │   │    category: text    │
│    output_format     │   │    tags: text[]      │
│    error_message     │   │    is_active: bool   │
│    duration_ms: int  │   │    usage_count: int  │
│    created_at        │   │    created_by        │
└──────────────────────┘   │    created_at        │
                           │    updated_at        │
                           └──────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `broadcast_sessions` 1:N `cue_sheets` | 세션당 여러 큐시트 |
| `cue_sheets` 1:N `cue_items` | 큐시트당 여러 아이템 |
| `cue_items` 1:N `gfx_triggers` | 아이템당 여러 트리거 |
| `cue_templates` 1:N `cue_items` | 템플릿 → 아이템 참조 |
| `cue_sheets.current_item_id` → `cue_items` | 현재 진행 중 아이템 |

---

## 3. Enum 타입 정의

```sql
-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 방송 세션 상태
CREATE TYPE cue_broadcast_status AS ENUM (
    'draft',            -- 초안
    'scheduled',        -- 예정됨
    'preparing',        -- 준비 중
    'standby',          -- 대기
    'live',             -- 생방송 중
    'break',            -- 휴식
    'completed',        -- 완료
    'cancelled',        -- 취소
    'postponed'         -- 연기
);

-- 큐시트 타입
CREATE TYPE cue_sheet_type AS ENUM (
    'pre_show',         -- 방송 전 (오프닝)
    'main_show',        -- 메인 방송
    'segment',          -- 세그먼트 (중간 구간)
    'break',            -- 휴식 시간
    'post_show',        -- 방송 후 (클로징)
    'highlight',        -- 하이라이트
    'emergency'         -- 긴급 (기술 문제 등)
);

-- 큐시트 상태
CREATE TYPE cue_sheet_status AS ENUM (
    'draft',            -- 초안
    'pending_review',   -- 검토 대기
    'approved',         -- 승인됨
    'ready',            -- 준비 완료
    'active',           -- 진행 중
    'paused',           -- 일시 정지
    'completed',        -- 완료
    'archived'          -- 아카이브
);

-- 큐 아이템 타입
CREATE TYPE cue_item_type AS ENUM (
    -- 칩/순위 관련
    'chip_count',           -- 칩 카운트
    'chip_comparison',      -- 칩 비교
    'leaderboard',          -- 순위표
    'chip_flow',            -- 칩 흐름

    -- 플레이어 관련
    'player_info',          -- 선수 정보
    'player_profile',       -- 선수 프로필
    'player_stats',         -- 선수 통계
    'heads_up',             -- 헤즈업 정보

    -- 이벤트 관련
    'event_info',           -- 이벤트 정보
    'event_schedule',       -- 이벤트 일정
    'payout',               -- 상금 구조
    'elimination',          -- 탈락 정보

    -- 핸드 관련
    'hand_replay',          -- 핸드 리플레이
    'hand_highlight',       -- 핸드 하이라이트

    -- 스태프
    'commentator',          -- 해설자
    'reporter',             -- 리포터
    'staff',                -- 스태프

    -- 전환/기타
    'transition',           -- 전환 화면
    'lower_third',          -- 하단 자막
    'fullscreen',           -- 전체 화면
    'bumper',               -- 범퍼 (짧은 전환)
    'sponsor',              -- 스폰서
    'custom'                -- 커스텀
);

-- 큐 아이템 상태
CREATE TYPE cue_item_status AS ENUM (
    'draft',            -- 초안
    'pending',          -- 대기
    'ready',            -- 준비됨
    'standby',          -- 송출 대기
    'on_air',           -- 송출 중
    'completed',        -- 완료
    'skipped',          -- 건너뜀
    'failed',           -- 실패
    'cancelled'         -- 취소
);

-- GFX 트리거 타입
CREATE TYPE cue_trigger_type AS ENUM (
    'manual',           -- 수동 트리거
    'scheduled',        -- 예약 트리거
    'auto',             -- 자동 트리거
    'api',              -- API 호출
    'hotkey',           -- 단축키
    'external'          -- 외부 시스템
);

-- 렌더 상태
CREATE TYPE cue_render_status AS ENUM (
    'pending',          -- 대기
    'queued',           -- 큐에 등록됨
    'rendering',        -- 렌더링 중
    'completed',        -- 완료
    'failed',           -- 실패
    'cancelled',        -- 취소
    'cached'            -- 캐시됨 (이전 렌더 사용)
);
```

---

## 4. 테이블 DDL

### 4.1 broadcast_sessions (방송 세션)

```sql
-- ============================================================================
-- broadcast_sessions: 방송 세션 정보
-- 하나의 방송 날짜/이벤트에 대한 전체 정보
-- ============================================================================

CREATE TABLE broadcast_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 세션 식별
    session_code TEXT NOT NULL UNIQUE,  -- 예: "WSOP-2024-ME-D1"

    -- 이벤트 연결 (선택적)
    event_id UUID,  -- wsop_events FK (다른 스키마)
    event_name TEXT NOT NULL,
    event_description TEXT,

    -- 방송 일정
    broadcast_date DATE NOT NULL,
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,

    -- 상태
    status cue_broadcast_status DEFAULT 'draft',
    current_sheet_id UUID,  -- 현재 진행 중인 큐시트

    -- 스태프 정보
    director TEXT,
    technical_director TEXT,
    producer TEXT,

    -- 해설자/리포터 (JSONB)
    commentators JSONB DEFAULT '[]'::JSONB,
    /*
    [
        {"name": "홍길동", "role": "main", "language": "ko"},
        {"name": "John Doe", "role": "color", "language": "en"}
    ]
    */

    reporters JSONB DEFAULT '[]'::JSONB,

    -- 방송 설정
    settings JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "default_gfx_duration": 10,
        "auto_advance": true,
        "language": "ko",
        "resolution": "1080p"
    }
    */

    -- 통계
    total_cue_items INTEGER DEFAULT 0,
    completed_cue_items INTEGER DEFAULT 0,
    total_duration_minutes INTEGER DEFAULT 0,

    -- 메타데이터
    notes TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 관리 정보
    created_by TEXT NOT NULL,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_broadcast_sessions_code ON broadcast_sessions(session_code);
CREATE INDEX idx_broadcast_sessions_date ON broadcast_sessions(broadcast_date DESC);
CREATE INDEX idx_broadcast_sessions_status ON broadcast_sessions(status);
CREATE INDEX idx_broadcast_sessions_event ON broadcast_sessions(event_id);
CREATE INDEX idx_broadcast_sessions_scheduled ON broadcast_sessions(scheduled_start DESC);
CREATE INDEX idx_broadcast_sessions_tags ON broadcast_sessions USING GIN (tags);
```

### 4.2 cue_sheets (큐시트)

```sql
-- ============================================================================
-- cue_sheets: 방송 큐시트
-- 방송 세션 내의 구간별 큐 목록
-- ============================================================================

CREATE TABLE cue_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 큐시트 식별
    sheet_code TEXT NOT NULL UNIQUE,  -- 예: "WSOP-2024-ME-D1-MAIN"

    -- 세션 참조
    session_id UUID NOT NULL REFERENCES broadcast_sessions(id) ON DELETE CASCADE,

    -- 기본 정보
    sheet_name TEXT NOT NULL,
    sheet_type cue_sheet_type NOT NULL DEFAULT 'main_show',
    sheet_order INTEGER NOT NULL DEFAULT 0,  -- 세션 내 순서

    -- 버전 관리
    version INTEGER DEFAULT 1,
    parent_version_id UUID REFERENCES cue_sheets(id),  -- 이전 버전

    -- 상태
    status cue_sheet_status DEFAULT 'draft',

    -- 진행 상황
    total_items INTEGER DEFAULT 0,
    completed_items INTEGER DEFAULT 0,
    current_item_id UUID,  -- 현재 진행 중인 아이템
    current_item_index INTEGER DEFAULT 0,

    -- 예상 시간
    estimated_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,

    -- 설정 (세션 설정 오버라이드)
    settings_override JSONB DEFAULT '{}'::JSONB,

    -- 메타데이터
    description TEXT,
    notes TEXT,

    -- 관리 정보
    created_by TEXT NOT NULL,
    last_modified_by TEXT,

    -- 타임스탬프
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_cue_sheets_session_order UNIQUE (session_id, sheet_order)
);

-- 인덱스
CREATE INDEX idx_cue_sheets_code ON cue_sheets(sheet_code);
CREATE INDEX idx_cue_sheets_session ON cue_sheets(session_id);
CREATE INDEX idx_cue_sheets_type ON cue_sheets(sheet_type);
CREATE INDEX idx_cue_sheets_status ON cue_sheets(status);
CREATE INDEX idx_cue_sheets_order ON cue_sheets(session_id, sheet_order);

-- FK 추가 (순환 참조 방지를 위해 별도 추가)
ALTER TABLE cue_sheets
    ADD CONSTRAINT fk_cue_sheets_current_item
    FOREIGN KEY (current_item_id)
    REFERENCES cue_items(id)
    ON DELETE SET NULL
    DEFERRABLE INITIALLY DEFERRED;
```

### 4.3 cue_items (큐 아이템)

```sql
-- ============================================================================
-- cue_items: 개별 큐 아이템
-- 하나의 GFX 요소에 대한 정보
-- ============================================================================

CREATE TABLE cue_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 큐시트 참조
    sheet_id UUID NOT NULL REFERENCES cue_sheets(id) ON DELETE CASCADE,

    -- 템플릿 참조 (선택적)
    template_id UUID REFERENCES cue_templates(id) ON DELETE SET NULL,

    -- 큐 식별
    cue_number TEXT NOT NULL,  -- 예: "Q01", "Q02-A"
    cue_type cue_item_type NOT NULL,

    -- 기본 정보
    title TEXT NOT NULL,
    description TEXT,
    notes TEXT,

    -- GFX 정보
    gfx_template_name TEXT,  -- AEP 템플릿명
    gfx_comp_name TEXT,      -- After Effects 컴포지션명

    -- GFX 데이터 (동적 바인딩)
    gfx_data JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "player_name": "홍길동",
        "chips": 1500000,
        "rank": 1,
        "country_code": "KR"
    }
    */

    -- 데이터 소스 (어디서 데이터를 가져올지)
    data_source JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "type": "wsop_event_players",
        "event_id": "uuid",
        "player_count": 10,
        "sort_by": "current_chips DESC"
    }
    */

    -- 타이밍
    duration_seconds INTEGER DEFAULT 10,
    scheduled_time TIMESTAMPTZ,  -- 예정 시간
    actual_time TIMESTAMPTZ,     -- 실제 송출 시간
    fade_in_ms INTEGER DEFAULT 500,
    fade_out_ms INTEGER DEFAULT 500,

    -- 순서
    sort_order INTEGER NOT NULL DEFAULT 0,

    -- 의존성 (다른 아이템 완료 후 실행)
    depends_on UUID[] DEFAULT ARRAY[]::UUID[],

    -- 상태
    status cue_item_status DEFAULT 'pending',
    skip_reason TEXT,  -- 건너뛴 경우 이유

    -- 렌더링 정보
    pre_render BOOLEAN DEFAULT FALSE,  -- 미리 렌더링 여부
    render_status cue_render_status DEFAULT 'pending',
    cached_output_path TEXT,

    -- 반복 설정
    repeat_count INTEGER DEFAULT 1,
    repeat_interval_seconds INTEGER DEFAULT 0,
    current_repeat INTEGER DEFAULT 0,

    -- 관리 정보
    created_by TEXT,
    last_triggered_by TEXT,

    -- 타임스탬프
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_cue_items_sheet_order UNIQUE (sheet_id, sort_order)
);

-- 인덱스
CREATE INDEX idx_cue_items_sheet ON cue_items(sheet_id);
CREATE INDEX idx_cue_items_type ON cue_items(cue_type);
CREATE INDEX idx_cue_items_status ON cue_items(status);
CREATE INDEX idx_cue_items_order ON cue_items(sheet_id, sort_order);
CREATE INDEX idx_cue_items_template ON cue_items(template_id);
CREATE INDEX idx_cue_items_scheduled ON cue_items(scheduled_time) WHERE scheduled_time IS NOT NULL;
CREATE INDEX idx_cue_items_gfx_data ON cue_items USING GIN (gfx_data);
```

### 4.4 cue_templates (큐 템플릿)

```sql
-- ============================================================================
-- cue_templates: 재사용 가능한 큐 템플릿
-- 자주 사용하는 큐 구성을 템플릿으로 저장
-- ============================================================================

CREATE TABLE cue_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 템플릿 식별
    template_code TEXT NOT NULL UNIQUE,  -- 예: "TPL-CHIP-COUNT-10"

    -- 기본 정보
    template_name TEXT NOT NULL,
    description TEXT,
    cue_type cue_item_type NOT NULL,

    -- GFX 정보
    gfx_template_name TEXT,
    gfx_comp_name TEXT,

    -- 기본 설정
    default_duration INTEGER DEFAULT 10,  -- 초
    default_fade_in_ms INTEGER DEFAULT 500,
    default_fade_out_ms INTEGER DEFAULT 500,

    -- 데이터 스키마 (필수 필드 정의)
    data_schema JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "required": ["player_name", "chips"],
        "optional": ["rank", "country_code"],
        "types": {
            "player_name": "string",
            "chips": "number",
            "rank": "number",
            "country_code": "string"
        }
    }
    */

    -- 샘플 데이터 (미리보기용)
    sample_data JSONB DEFAULT '{}'::JSONB,

    -- 미리보기 이미지
    preview_image_url TEXT,
    preview_video_url TEXT,

    -- 분류
    category TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 상태
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,

    -- 사용 통계
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,

    -- 관리 정보
    created_by TEXT NOT NULL,
    approved_by TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_cue_templates_code ON cue_templates(template_code);
CREATE INDEX idx_cue_templates_type ON cue_templates(cue_type);
CREATE INDEX idx_cue_templates_category ON cue_templates(category);
CREATE INDEX idx_cue_templates_active ON cue_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_cue_templates_featured ON cue_templates(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_cue_templates_tags ON cue_templates USING GIN (tags);
CREATE INDEX idx_cue_templates_usage ON cue_templates(usage_count DESC);
```

### 4.5 gfx_triggers (GFX 트리거 로그)

```sql
-- ============================================================================
-- gfx_triggers: GFX 송출 트리거 로그
-- 모든 GFX 송출 이력 기록
-- ============================================================================

CREATE TABLE gfx_triggers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조
    cue_item_id UUID REFERENCES cue_items(id) ON DELETE SET NULL,
    session_id UUID REFERENCES broadcast_sessions(id) ON DELETE SET NULL,
    sheet_id UUID REFERENCES cue_sheets(id) ON DELETE SET NULL,

    -- 트리거 정보
    trigger_type cue_trigger_type NOT NULL,
    trigger_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    triggered_by TEXT NOT NULL,

    -- GFX 정보
    cue_type cue_item_type,
    aep_comp_name TEXT,
    gfx_template_name TEXT,
    gfx_data JSONB,

    -- 렌더링 정보
    render_status cue_render_status DEFAULT 'pending',
    render_job_id UUID,  -- 렌더 큐 작업 ID
    render_started_at TIMESTAMPTZ,
    render_completed_at TIMESTAMPTZ,

    -- 출력 정보
    output_path TEXT,
    output_format TEXT,  -- mp4, mov, png 등
    output_resolution TEXT,  -- 1920x1080 등
    file_size_bytes BIGINT,

    -- 성능 메트릭
    duration_ms INTEGER,  -- 전체 처리 시간
    render_duration_ms INTEGER,
    queue_wait_ms INTEGER,

    -- 에러 정보
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,

    -- 메타데이터
    notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_gfx_triggers_cue_item ON gfx_triggers(cue_item_id);
CREATE INDEX idx_gfx_triggers_session ON gfx_triggers(session_id);
CREATE INDEX idx_gfx_triggers_sheet ON gfx_triggers(sheet_id);
CREATE INDEX idx_gfx_triggers_type ON gfx_triggers(trigger_type);
CREATE INDEX idx_gfx_triggers_time ON gfx_triggers(trigger_time DESC);
CREATE INDEX idx_gfx_triggers_status ON gfx_triggers(render_status);
CREATE INDEX idx_gfx_triggers_cue_type ON gfx_triggers(cue_type);
CREATE INDEX idx_gfx_triggers_triggered_by ON gfx_triggers(triggered_by);

-- 최근 트리거 빠른 조회용
CREATE INDEX idx_gfx_triggers_recent ON gfx_triggers(session_id, trigger_time DESC);
```

---

## 5. 뷰 정의

### 5.1 v_session_overview (세션 개요 뷰)

```sql
-- ============================================================================
-- v_session_overview: 방송 세션 개요 및 진행 상황
-- ============================================================================

CREATE OR REPLACE VIEW v_session_overview AS
SELECT
    bs.id,
    bs.session_code,
    bs.event_name,
    bs.broadcast_date,
    bs.scheduled_start,
    bs.actual_start,
    bs.status,
    bs.director,

    -- 큐시트 통계
    COUNT(cs.id) AS total_sheets,
    COUNT(CASE WHEN cs.status = 'completed' THEN 1 END) AS completed_sheets,
    COUNT(CASE WHEN cs.status = 'active' THEN 1 END) AS active_sheets,

    -- 큐 아이템 통계
    SUM(cs.total_items) AS total_items,
    SUM(cs.completed_items) AS completed_items,

    -- 진행률
    CASE
        WHEN SUM(cs.total_items) > 0
        THEN ROUND(SUM(cs.completed_items)::NUMERIC / SUM(cs.total_items) * 100, 1)
        ELSE 0
    END AS progress_percent,

    bs.updated_at

FROM broadcast_sessions bs
LEFT JOIN cue_sheets cs ON bs.id = cs.session_id
GROUP BY bs.id
ORDER BY bs.broadcast_date DESC, bs.scheduled_start DESC;
```

### 5.2 v_cue_sheet_items (큐시트 아이템 목록 뷰)

```sql
-- ============================================================================
-- v_cue_sheet_items: 큐시트별 아이템 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_cue_sheet_items AS
SELECT
    ci.id,
    ci.cue_number,
    ci.title,
    ci.cue_type,
    ci.status,
    ci.duration_seconds,
    ci.sort_order,
    ci.gfx_template_name,
    ci.scheduled_time,
    ci.actual_time,

    -- 큐시트 정보
    cs.id AS sheet_id,
    cs.sheet_code,
    cs.sheet_name,
    cs.sheet_type,

    -- 세션 정보
    bs.id AS session_id,
    bs.session_code,
    bs.event_name,

    -- 현재 진행 여부
    (cs.current_item_id = ci.id) AS is_current,

    -- 템플릿 정보
    ct.template_name,
    ct.preview_image_url,

    ci.updated_at

FROM cue_items ci
JOIN cue_sheets cs ON ci.sheet_id = cs.id
JOIN broadcast_sessions bs ON cs.session_id = bs.id
LEFT JOIN cue_templates ct ON ci.template_id = ct.id
ORDER BY cs.session_id, cs.sheet_order, ci.sort_order;
```

### 5.3 v_active_cues (현재 활성 큐 뷰)

```sql
-- ============================================================================
-- v_active_cues: 현재 진행 중인 세션의 활성 큐
-- ============================================================================

CREATE OR REPLACE VIEW v_active_cues AS
SELECT
    ci.id,
    ci.cue_number,
    ci.title,
    ci.cue_type,
    ci.status,
    ci.gfx_data,
    ci.duration_seconds,

    cs.sheet_name,
    bs.session_code,
    bs.event_name,

    -- 다음 큐 정보
    (
        SELECT ci2.title
        FROM cue_items ci2
        WHERE ci2.sheet_id = ci.sheet_id
          AND ci2.sort_order > ci.sort_order
        ORDER BY ci2.sort_order
        LIMIT 1
    ) AS next_cue_title

FROM cue_items ci
JOIN cue_sheets cs ON ci.sheet_id = cs.id
JOIN broadcast_sessions bs ON cs.session_id = bs.id
WHERE bs.status = 'live'
  AND cs.status = 'active'
  AND ci.status IN ('standby', 'on_air')
ORDER BY ci.sort_order;
```

### 5.4 v_trigger_history (트리거 이력 뷰)

```sql
-- ============================================================================
-- v_trigger_history: GFX 트리거 이력
-- ============================================================================

CREATE OR REPLACE VIEW v_trigger_history AS
SELECT
    gt.id,
    gt.trigger_type,
    gt.trigger_time,
    gt.triggered_by,
    gt.cue_type,
    gt.aep_comp_name,
    gt.render_status,
    gt.duration_ms,
    gt.error_message,

    ci.cue_number,
    ci.title AS cue_title,

    cs.sheet_name,
    bs.session_code,
    bs.event_name

FROM gfx_triggers gt
LEFT JOIN cue_items ci ON gt.cue_item_id = ci.id
LEFT JOIN cue_sheets cs ON gt.sheet_id = cs.id
LEFT JOIN broadcast_sessions bs ON gt.session_id = bs.id
ORDER BY gt.trigger_time DESC;
```

### 5.5 v_template_usage (템플릿 사용 현황 뷰)

```sql
-- ============================================================================
-- v_template_usage: 템플릿 사용 현황
-- ============================================================================

CREATE OR REPLACE VIEW v_template_usage AS
SELECT
    ct.id,
    ct.template_code,
    ct.template_name,
    ct.cue_type,
    ct.category,
    ct.is_active,
    ct.usage_count,
    ct.last_used_at,

    -- 최근 30일 사용 횟수
    (
        SELECT COUNT(*)
        FROM cue_items ci
        WHERE ci.template_id = ct.id
          AND ci.created_at > NOW() - INTERVAL '30 days'
    ) AS usage_last_30_days,

    -- 현재 사용 중인 아이템 수
    (
        SELECT COUNT(*)
        FROM cue_items ci
        JOIN cue_sheets cs ON ci.sheet_id = cs.id
        JOIN broadcast_sessions bs ON cs.session_id = bs.id
        WHERE ci.template_id = ct.id
          AND bs.status = 'live'
    ) AS active_usage_count

FROM cue_templates ct
WHERE ct.is_active = TRUE
ORDER BY ct.usage_count DESC;
```

---

## 6. 함수 및 트리거

### 6.1 updated_at 자동 갱신

```sql
-- ============================================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================================

CREATE OR REPLACE FUNCTION update_cue_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_broadcast_sessions_updated_at
    BEFORE UPDATE ON broadcast_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

CREATE TRIGGER update_cue_sheets_updated_at
    BEFORE UPDATE ON cue_sheets
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

CREATE TRIGGER update_cue_items_updated_at
    BEFORE UPDATE ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

CREATE TRIGGER update_cue_templates_updated_at
    BEFORE UPDATE ON cue_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();
```

### 6.2 큐시트 통계 자동 업데이트

```sql
-- ============================================================================
-- 함수: 큐시트 아이템 통계 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_cue_sheet_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 큐시트 통계 업데이트
    UPDATE cue_sheets
    SET
        total_items = (
            SELECT COUNT(*) FROM cue_items WHERE sheet_id = COALESCE(NEW.sheet_id, OLD.sheet_id)
        ),
        completed_items = (
            SELECT COUNT(*) FROM cue_items
            WHERE sheet_id = COALESCE(NEW.sheet_id, OLD.sheet_id)
              AND status = 'completed'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.sheet_id, OLD.sheet_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_sheet_stats_on_item_change
    AFTER INSERT OR UPDATE OR DELETE ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_sheet_stats();
```

### 6.3 세션 통계 자동 업데이트

```sql
-- ============================================================================
-- 함수: 세션 통계 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 세션 통계 업데이트
    UPDATE broadcast_sessions
    SET
        total_cue_items = (
            SELECT COALESCE(SUM(total_items), 0)
            FROM cue_sheets
            WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        ),
        completed_cue_items = (
            SELECT COALESCE(SUM(completed_items), 0)
            FROM cue_sheets
            WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.session_id, OLD.session_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_session_stats_on_sheet_change
    AFTER INSERT OR UPDATE OR DELETE ON cue_sheets
    FOR EACH ROW
    EXECUTE FUNCTION update_session_stats();
```

### 6.4 템플릿 사용 횟수 업데이트

```sql
-- ============================================================================
-- 함수: 템플릿 사용 횟수 증가
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_template_usage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.template_id IS NOT NULL THEN
        UPDATE cue_templates
        SET
            usage_count = usage_count + 1,
            last_used_at = NOW()
        WHERE id = NEW.template_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_template_usage_on_item
    AFTER INSERT ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION increment_template_usage();
```

### 6.5 큐 아이템 상태 전환

```sql
-- ============================================================================
-- 함수: 큐 아이템 상태 전환 및 로그 기록
-- ============================================================================

CREATE OR REPLACE FUNCTION transition_cue_item_status(
    p_item_id UUID,
    p_new_status cue_item_status,
    p_triggered_by TEXT DEFAULT 'system'
)
RETURNS VOID AS $$
DECLARE
    v_item RECORD;
BEGIN
    -- 아이템 조회
    SELECT * INTO v_item FROM cue_items WHERE id = p_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cue item not found: %', p_item_id;
    END IF;

    -- 상태 업데이트
    UPDATE cue_items
    SET
        status = p_new_status,
        actual_time = CASE WHEN p_new_status = 'on_air' THEN NOW() ELSE actual_time END,
        last_triggered_by = p_triggered_by,
        last_triggered_at = NOW()
    WHERE id = p_item_id;

    -- on_air 상태로 전환 시 트리거 로그 기록
    IF p_new_status = 'on_air' THEN
        INSERT INTO gfx_triggers (
            cue_item_id,
            session_id,
            sheet_id,
            trigger_type,
            triggered_by,
            cue_type,
            aep_comp_name,
            gfx_template_name,
            gfx_data
        )
        SELECT
            ci.id,
            cs.session_id,
            ci.sheet_id,
            'manual',
            p_triggered_by,
            ci.cue_type,
            ci.gfx_comp_name,
            ci.gfx_template_name,
            ci.gfx_data
        FROM cue_items ci
        JOIN cue_sheets cs ON ci.sheet_id = cs.id
        WHERE ci.id = p_item_id;

        -- 큐시트의 현재 아이템 업데이트
        UPDATE cue_sheets
        SET current_item_id = p_item_id
        WHERE id = v_item.sheet_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### 6.6 다음 큐 아이템 조회

```sql
-- ============================================================================
-- 함수: 다음 큐 아이템 조회
-- ============================================================================

CREATE OR REPLACE FUNCTION get_next_cue_item(p_sheet_id UUID)
RETURNS TABLE (
    id UUID,
    cue_number TEXT,
    title TEXT,
    cue_type cue_item_type,
    gfx_data JSONB,
    duration_seconds INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ci.id,
        ci.cue_number,
        ci.title,
        ci.cue_type,
        ci.gfx_data,
        ci.duration_seconds
    FROM cue_items ci
    JOIN cue_sheets cs ON ci.sheet_id = cs.id
    WHERE ci.sheet_id = p_sheet_id
      AND ci.status IN ('pending', 'ready', 'standby')
      AND ci.sort_order > COALESCE(
          (SELECT sort_order FROM cue_items WHERE id = cs.current_item_id),
          -1
      )
    ORDER BY ci.sort_order
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;
```

---

## 7. 인덱스 전략 및 쿼리 패턴

### 7.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 오늘 방송 세션 | `WHERE broadcast_date = CURRENT_DATE` | `idx_broadcast_sessions_date` |
| 진행 중 세션 | `WHERE status = 'live'` | `idx_broadcast_sessions_status` |
| 세션별 큐시트 | `WHERE session_id = ?` | `idx_cue_sheets_session` |
| 큐시트별 아이템 | `WHERE sheet_id = ? ORDER BY sort_order` | `idx_cue_items_order` |
| 대기 중 아이템 | `WHERE status = 'standby'` | `idx_cue_items_status` |
| 최근 트리거 | `WHERE trigger_time > ? ORDER BY trigger_time DESC` | `idx_gfx_triggers_time` |
| 템플릿 검색 | `WHERE category = ?` | `idx_cue_templates_category` |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- broadcast_sessions.id, cue_sheets.id, cue_items.id, etc.

-- Unique Constraints
-- broadcast_sessions.session_code
-- cue_sheets.sheet_code
-- cue_templates.template_code
-- (session_id, sheet_order), (sheet_id, sort_order)

-- B-tree Indexes (범위/정렬 쿼리)
-- broadcast_sessions: broadcast_date DESC, scheduled_start DESC
-- cue_sheets: session_id, sheet_order
-- cue_items: sheet_id, sort_order
-- gfx_triggers: trigger_time DESC

-- GIN Indexes (배열/JSONB 검색)
-- broadcast_sessions.tags
-- cue_templates.tags
-- cue_items.gfx_data

-- Partial Indexes (조건부 최적화)
-- cue_templates.is_active WHERE TRUE
-- cue_items.scheduled_time WHERE NOT NULL
```

---

## 8. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE broadcast_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_triggers ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- broadcast_sessions 정책
-- ============================================================================
CREATE POLICY "broadcast_sessions_select_authenticated"
    ON broadcast_sessions FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "broadcast_sessions_insert_service"
    ON broadcast_sessions FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "broadcast_sessions_update_service"
    ON broadcast_sessions FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- cue_sheets 정책
-- ============================================================================
CREATE POLICY "cue_sheets_select_authenticated"
    ON cue_sheets FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_sheets_all_service"
    ON cue_sheets FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- cue_items 정책
-- ============================================================================
CREATE POLICY "cue_items_select_authenticated"
    ON cue_items FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_items_all_service"
    ON cue_items FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- cue_templates 정책
-- ============================================================================
CREATE POLICY "cue_templates_select_authenticated"
    ON cue_templates FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_templates_all_service"
    ON cue_templates FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- gfx_triggers 정책
-- ============================================================================
CREATE POLICY "gfx_triggers_select_authenticated"
    ON gfx_triggers FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_triggers_insert_service"
    ON gfx_triggers FOR INSERT
    WITH CHECK (auth.role() = 'service_role');
```

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. broadcast_sessions 테이블 생성
3. cue_templates 테이블 생성
4. cue_sheets 테이블 생성 (current_item_id FK 제외)
5. cue_items 테이블 생성
6. cue_sheets에 current_item_id FK 추가 (ALTER TABLE)
7. gfx_triggers 테이블 생성
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
6. cue_sheets.current_item_id FK 삭제
7. 테이블 삭제 (역순)
8. ENUM 타입 삭제 (DROP TYPE)
```

---

## 10. 제약조건 요약

| 테이블 | 제약조건 | 설명 |
|--------|----------|------|
| `broadcast_sessions` | `session_code UNIQUE` | 세션 코드 중복 방지 |
| `cue_sheets` | `sheet_code UNIQUE` | 큐시트 코드 중복 방지 |
| `cue_sheets` | `(session_id, sheet_order) UNIQUE` | 세션 내 순서 중복 방지 |
| `cue_items` | `(sheet_id, sort_order) UNIQUE` | 큐시트 내 순서 중복 방지 |
| `cue_templates` | `template_code UNIQUE` | 템플릿 코드 중복 방지 |

---

## 11. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `src/services/broadcast_service.py` | 방송 세션 관리 | broadcast_sessions |
| `src/services/cuesheet_service.py` | 큐시트 CRUD | cue_sheets, cue_items |
| `src/services/template_service.py` | 템플릿 관리 | cue_templates |
| `src/services/trigger_service.py` | GFX 트리거 | gfx_triggers |
| `src/api/cuesheet_api.py` | REST API | 전체 |
| `src/websocket/live_cue_handler.py` | 실시간 업데이트 | cue_items, gfx_triggers |

---

## Appendix: 큐 아이템 GFX 데이터 예시

### 칩 카운트 (chip_count)

```json
{
  "players": [
    {
      "rank": 1,
      "name": "홍길동",
      "country_code": "KR",
      "chips": 1500000,
      "stack_bbs": 75
    },
    {
      "rank": 2,
      "name": "John Doe",
      "country_code": "US",
      "chips": 1200000,
      "stack_bbs": 60
    }
  ],
  "event_name": "WSOP Main Event",
  "players_remaining": 100,
  "avg_stack": 500000
}
```

### 선수 정보 (player_info)

```json
{
  "name": "홍길동",
  "name_display": "Gil-Dong Hong",
  "country_code": "KR",
  "country_name": "South Korea",
  "profile_image": "/images/players/hong.jpg",
  "chips": 1500000,
  "rank": 1,
  "wsop_bracelets": 2,
  "notable_wins": ["2023 WSOP Asia Main Event"]
}
```

### 탈락 정보 (elimination)

```json
{
  "eliminated_player": {
    "name": "Jane Doe",
    "country_code": "UK",
    "chips_at_elimination": 0,
    "final_rank": 50
  },
  "eliminator": {
    "name": "홍길동",
    "country_code": "KR"
  },
  "prize_won": 25000,
  "elimination_hand": "AA vs KK"
}
```
