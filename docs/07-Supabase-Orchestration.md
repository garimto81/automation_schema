# 07. Supabase Orchestration Schema

전체 시스템 통합 및 오케스트레이션을 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 2.0.0
**Date**: 2026-01-16

> ⚠️ **스키마 변경 안내 (2026-01-16)**
> - `unified_players` 뷰: `manual_players` 제거 → gfx/wsop만 UNION
> - `unified_chip_data` 뷰: `chip_snapshots` 제거 → wsop_chip_counts/gfx_hand_players만
> - `sync_status` 초기 데이터: chip_snapshots 제거
**Project**: Automation DB Schema

---

## 1. 개요

### 1.1 목적

모든 데이터 소스(GFX, WSOP+, Manual, Cuesheet)를 통합하여:
- 통합 플레이어 뷰 제공 (소스별 데이터 병합)
- 통합 이벤트 뷰 제공
- 작업 큐 및 렌더 큐 관리
- 동기화 상태 추적
- 시스템 설정 관리
- 실시간 알림 시스템

### 1.2 통합 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Supabase Orchestration Architecture                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA SOURCES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│   │  GFX JSON   │  │   WSOP+     │  │   Manual    │  │  Cuesheet   │      │
│   │   Schema    │  │   Schema    │  │   Schema    │  │   Schema    │      │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
│          │                │                │                │              │
└──────────┼────────────────┼────────────────┼────────────────┼──────────────┘
           │                │                │                │
           └────────────────┼────────────────┼────────────────┘
                            │                │
                            ▼                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ORCHESTRATION LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                        UNIFIED VIEWS                                 │  │
│   ├─────────────────────────────────────────────────────────────────────┤  │
│   │  unified_players  │  unified_events  │  unified_chip_data           │  │
│   │  (플레이어 통합)   │  (이벤트 통합)    │  (칩 데이터 통합)              │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ┌─────────────────────┐  ┌─────────────────────┐                         │
│   │     job_queue       │  │    render_queue     │                         │
│   │   (작업 큐)         │  │   (렌더 큐)         │                         │
│   └─────────────────────┘  └─────────────────────┘                         │
│                                                                             │
│   ┌─────────────────────┐  ┌─────────────────────┐  ┌───────────────────┐  │
│   │    sync_status      │  │   system_config     │  │   notifications   │  │
│   │   (동기화 상태)      │  │   (시스템 설정)      │  │   (알림)          │  │
│   └─────────────────────┘  └─────────────────────┘  └───────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              OUTPUT LAYER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│   ┌─────────────────────┐  ┌─────────────────────┐                         │
│   │    AEP Render       │  │    API Response     │                         │
│   │   (영상 출력)        │  │   (데이터 제공)      │                         │
│   └─────────────────────┘  └─────────────────────┘                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 핵심 기능

| 기능 | 설명 |
|------|------|
| **통합 뷰** | GFX, WSOP+, Manual 플레이어 데이터 병합 |
| **작업 큐** | 비동기 작업 (동기화, 임포트, 내보내기) 관리 |
| **렌더 큐** | AEP 렌더링 작업 관리 |
| **동기화 추적** | 각 소스별 동기화 상태 모니터링 |
| **설정 관리** | 시스템 전역 설정 저장 |
| **알림** | 실시간 알림 및 로그 |

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Supabase Orchestration Schema                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐       ┌──────────────────────┐
│     job_queue        │       │    render_queue      │
│   (작업 큐)          │       │   (렌더 큐)          │
├──────────────────────┤       ├──────────────────────┤
│ PK id: uuid          │       │ PK id: uuid          │
│    job_type: enum    │───┐   │ FK job_id: uuid      │◄──┐
│    job_name: text    │   │   │    render_type: enum │   │
│    priority: int     │   │   │    aep_project: text │   │
│    payload: jsonb    │   │   │    aep_comp_name     │   │
│    status: enum      │   │   │    gfx_data: jsonb   │   │
│    progress: int     │   │   │    output_format     │   │
│    result: jsonb     │   │   │    output_path       │   │
│    retry_count: int  │   │   │    output_resolution │   │
│    max_retries: int  │   │   │    status: enum      │   │
│    scheduled_at: ts  │   │   │    progress: int     │   │
│    started_at: ts    │   │   │    priority: int     │   │
│    completed_at: ts  │   │   │    started_at: ts    │   │
│    error_message     │   │   │    completed_at: ts  │   │
│    error_details     │   └──▶│    error_message     │   │
│    created_by        │       │    worker_id: text   │   │
│    created_at        │       │    created_at        │   │
└──────────────────────┘       └──────────────────────┘   │
                                                          │
┌──────────────────────┐       ┌──────────────────────┐   │
│    sync_status       │       │   sync_history       │   │
│   (동기화 상태)       │       │   (동기화 이력)       │   │
├──────────────────────┤       ├──────────────────────┤   │
│ PK id: uuid          │       │ PK id: uuid          │   │
│ UK source_entity     │───┐   │ FK sync_status_id    │◄──┤
│    source: enum      │   │   │    operation: enum   │   │
│    entity_type: text │   │   │    records_processed │   │
│    entity_id: uuid   │   │   │    records_created   │   │
│    last_synced_at: ts│   │   │    records_updated   │   │
│    sync_hash: text   │   │   │    records_failed    │   │
│    status: enum      │   │   │    duration_ms: int  │   │
│    last_error: text  │   │   │    error_count: int  │   │
│    retry_count: int  │   │   │    errors: jsonb     │   │
│    next_sync_at: ts  │   │   │    metadata: jsonb   │   │
│    metadata: jsonb   │   └──▶│    created_at: ts    │   │
│    created_at        │       └──────────────────────┘   │
│    updated_at        │                                  │
└──────────────────────┘                                  │
                                                          │
┌──────────────────────┐       ┌──────────────────────┐   │
│   system_config      │       │   notifications      │   │
│   (시스템 설정)       │       │   (알림)             │   │
├──────────────────────┤       ├──────────────────────┤   │
│ PK key: text         │       │ PK id: uuid          │   │
│    value: jsonb      │       │    type: enum        │   │
│    value_type: text  │       │    level: enum       │   │
│    category: text    │       │    title: text       │   │
│    description: text │       │    message: text     │   │
│    is_sensitive: bool│       │    data: jsonb       │   │
│    is_readonly: bool │       │    source: enum      │   │
│    validation: jsonb │       │    entity_type: text │   │
│    updated_by: text  │       │    entity_id: uuid   │   │
│    updated_at: ts    │       │ FK job_id: uuid      │───┘
│    created_at: ts    │       │    read: bool        │
└──────────────────────┘       │    read_at: ts       │
                               │    dismissed: bool   │
┌──────────────────────┐       │    created_at: ts    │
│   api_keys           │       └──────────────────────┘
│   (API 키)           │
├──────────────────────┤       ┌──────────────────────┐
│ PK id: uuid          │       │   activity_log       │
│ UK key_hash: text    │       │   (활동 로그)        │
│    name: text        │       ├──────────────────────┤
│    key_prefix: text  │       │ PK id: uuid          │
│    permissions: jsonb│       │    action: text      │
│    rate_limit: int   │       │    actor: text       │
│    expires_at: ts    │       │    actor_type: enum  │
│    last_used_at: ts  │       │    entity_type: text │
│    is_active: bool   │       │    entity_id: uuid   │
│    created_by: text  │       │    changes: jsonb    │
│    created_at: ts    │       │    metadata: jsonb   │
└──────────────────────┘       │    ip_address: inet  │
                               │    user_agent: text  │
                               │    created_at: ts    │
                               └──────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `job_queue` 1:N `render_queue` | 작업당 여러 렌더링 |
| `sync_status` 1:N `sync_history` | 동기화 상태당 여러 이력 |
| `job_queue` 1:N `notifications` | 작업 관련 알림 |

---

## 3. Enum 타입 정의

```sql
-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 데이터 소스
CREATE TYPE orch_data_source AS ENUM (
    'gfx',              -- GFX JSON
    'wsop',             -- WSOP+
    'manual',           -- Manual
    'cuesheet',         -- Cuesheet
    'external',         -- 외부 시스템
    'system'            -- 시스템 내부
);

-- 작업 타입
CREATE TYPE orch_job_type AS ENUM (
    -- 동기화
    'sync_gfx',             -- GFX JSON 동기화
    'sync_wsop',            -- WSOP+ 데이터 동기화
    'sync_manual',          -- Manual 데이터 동기화

    -- 임포트/익스포트
    'import_json',          -- JSON 임포트
    'import_csv',           -- CSV 임포트
    'export_data',          -- 데이터 내보내기

    -- 렌더링
    'render_gfx',           -- GFX 렌더링
    'render_batch',         -- 배치 렌더링

    -- 처리
    'process_hands',        -- 핸드 처리
    'grade_hands',          -- 핸드 등급 분류
    'match_players',        -- 플레이어 매칭

    -- 유지보수
    'cleanup',              -- 정리 작업
    'backup',               -- 백업
    'archive'               -- 아카이브
);

-- 작업 상태
CREATE TYPE orch_job_status AS ENUM (
    'pending',              -- 대기
    'queued',               -- 큐에 등록됨
    'running',              -- 실행 중
    'paused',               -- 일시 정지
    'completed',            -- 완료
    'failed',               -- 실패
    'cancelled',            -- 취소
    'timeout'               -- 시간 초과
);

-- 렌더 타입
CREATE TYPE orch_render_type AS ENUM (
    'chip_count',           -- 칩 카운트
    'leaderboard',          -- 순위표
    'player_info',          -- 선수 정보
    'hand_replay',          -- 핸드 리플레이
    'elimination',          -- 탈락
    'payout',               -- 상금
    'custom'                -- 커스텀
);

-- 렌더 상태
CREATE TYPE orch_render_status AS ENUM (
    'pending',              -- 대기
    'queued',               -- 큐에 등록됨
    'preparing',            -- 준비 중
    'rendering',            -- 렌더링 중
    'encoding',             -- 인코딩 중
    'uploading',            -- 업로드 중
    'completed',            -- 완료
    'failed',               -- 실패
    'cancelled'             -- 취소
);

-- 동기화 상태
CREATE TYPE orch_sync_status AS ENUM (
    'pending',              -- 대기
    'in_progress',          -- 진행 중
    'synced',               -- 동기화됨
    'outdated',             -- 오래됨
    'failed',               -- 실패
    'disabled'              -- 비활성화
);

-- 동기화 작업 타입
CREATE TYPE orch_sync_operation AS ENUM (
    'full_sync',            -- 전체 동기화
    'incremental',          -- 증분 동기화
    'manual',               -- 수동 동기화
    'scheduled',            -- 예약 동기화
    'webhook'               -- 웹훅 트리거
);

-- 알림 타입
CREATE TYPE orch_notification_type AS ENUM (
    'info',                 -- 정보
    'success',              -- 성공
    'warning',              -- 경고
    'error',                -- 에러
    'alert'                 -- 긴급
);

-- 알림 레벨
CREATE TYPE orch_notification_level AS ENUM (
    'low',                  -- 낮음
    'medium',               -- 중간
    'high',                 -- 높음
    'critical'              -- 긴급
);

-- 활동 주체 타입
CREATE TYPE orch_actor_type AS ENUM (
    'user',                 -- 사용자
    'service',              -- 서비스
    'system',               -- 시스템
    'api',                  -- API
    'scheduler'             -- 스케줄러
);
```

---

## 4. 테이블 DDL

### 4.1 job_queue (작업 큐)

```sql
-- ============================================================================
-- job_queue: 비동기 작업 큐
-- 동기화, 임포트, 내보내기 등 백그라운드 작업 관리
-- ============================================================================

CREATE TABLE job_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 작업 식별
    job_type orch_job_type NOT NULL,
    job_name TEXT NOT NULL,
    job_group TEXT,  -- 관련 작업 그룹화

    -- 우선순위 (낮을수록 높은 우선순위)
    priority INTEGER DEFAULT 100,

    -- 작업 데이터
    payload JSONB NOT NULL DEFAULT '{}'::JSONB,
    /*
    {
        "source_path": "/nas/gfx_json/",
        "target_event_id": "uuid",
        "options": {
            "overwrite": false,
            "validate": true
        }
    }
    */

    -- 상태
    status orch_job_status DEFAULT 'pending',
    progress INTEGER DEFAULT 0,  -- 0-100%
    progress_message TEXT,

    -- 결과
    result JSONB,
    /*
    {
        "records_processed": 100,
        "records_created": 50,
        "records_updated": 30,
        "records_failed": 20,
        "errors": [...]
    }
    */

    -- 재시도 설정
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,

    -- 스케줄링
    scheduled_at TIMESTAMPTZ,  -- 예약 실행 시간
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    timeout_seconds INTEGER DEFAULT 3600,  -- 1시간

    -- 에러 정보
    error_message TEXT,
    error_details JSONB,
    error_stack TEXT,

    -- 워커 정보
    worker_id TEXT,
    locked_at TIMESTAMPTZ,
    lock_expires_at TIMESTAMPTZ,

    -- 의존성
    depends_on UUID[] DEFAULT ARRAY[]::UUID[],
    parent_job_id UUID REFERENCES job_queue(id),

    -- 메타데이터
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 관리 정보
    created_by TEXT NOT NULL,
    cancelled_by TEXT,
    cancelled_at TIMESTAMPTZ,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_job_queue_type ON job_queue(job_type);
CREATE INDEX idx_job_queue_status ON job_queue(status);
CREATE INDEX idx_job_queue_priority ON job_queue(priority, created_at);
CREATE INDEX idx_job_queue_scheduled ON job_queue(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_job_queue_pending ON job_queue(priority, created_at)
    WHERE status = 'pending' AND (scheduled_at IS NULL OR scheduled_at <= NOW());
CREATE INDEX idx_job_queue_running ON job_queue(worker_id, started_at)
    WHERE status = 'running';
CREATE INDEX idx_job_queue_parent ON job_queue(parent_job_id);
CREATE INDEX idx_job_queue_tags ON job_queue USING GIN (tags);
CREATE INDEX idx_job_queue_created ON job_queue(created_at DESC);
```

### 4.2 render_queue (렌더 큐)

```sql
-- ============================================================================
-- render_queue: AEP 렌더링 작업 큐
-- After Effects 렌더링 작업 관리
-- ============================================================================

CREATE TABLE render_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 작업 참조
    job_id UUID REFERENCES job_queue(id) ON DELETE SET NULL,
    cue_item_id UUID,  -- cue_items FK (다른 스키마)

    -- 렌더 타입
    render_type orch_render_type NOT NULL,

    -- AEP 프로젝트 정보
    aep_project TEXT NOT NULL,  -- AEP 파일 경로
    aep_comp_name TEXT NOT NULL,  -- 컴포지션명

    -- GFX 데이터
    gfx_data JSONB NOT NULL,
    data_hash TEXT,  -- 동일 데이터 캐싱용

    -- 출력 설정
    output_format TEXT DEFAULT 'mp4',  -- mp4, mov, png
    output_path TEXT,
    output_resolution TEXT DEFAULT '1920x1080',
    output_frame_rate INTEGER DEFAULT 30,
    output_codec TEXT DEFAULT 'h264',
    output_quality TEXT DEFAULT 'high',

    -- 시간 범위
    start_frame INTEGER DEFAULT 0,
    end_frame INTEGER,
    duration_seconds NUMERIC(10,2),

    -- 상태
    status orch_render_status DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    current_frame INTEGER DEFAULT 0,
    total_frames INTEGER,

    -- 우선순위
    priority INTEGER DEFAULT 100,

    -- 타이밍
    queued_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    estimated_completion TIMESTAMPTZ,

    -- 결과
    output_file_size BIGINT,
    output_duration_seconds NUMERIC(10,2),
    render_duration_ms INTEGER,

    -- 에러 정보
    error_message TEXT,
    error_details JSONB,
    error_frame INTEGER,

    -- 워커 정보
    worker_id TEXT,
    worker_host TEXT,
    aerender_pid INTEGER,

    -- 캐싱
    cache_hit BOOLEAN DEFAULT FALSE,
    cached_output_path TEXT,

    -- 메타데이터
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_render_queue_job ON render_queue(job_id);
CREATE INDEX idx_render_queue_type ON render_queue(render_type);
CREATE INDEX idx_render_queue_status ON render_queue(status);
CREATE INDEX idx_render_queue_priority ON render_queue(priority, queued_at);
CREATE INDEX idx_render_queue_pending ON render_queue(priority, queued_at)
    WHERE status = 'pending';
CREATE INDEX idx_render_queue_data_hash ON render_queue(data_hash);
CREATE INDEX idx_render_queue_worker ON render_queue(worker_id) WHERE worker_id IS NOT NULL;
CREATE INDEX idx_render_queue_cue_item ON render_queue(cue_item_id);
```

### 4.3 sync_status (동기화 상태)

```sql
-- ============================================================================
-- sync_status: 데이터 소스별 동기화 상태 추적
-- ============================================================================

CREATE TABLE sync_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 소스 식별
    source orch_data_source NOT NULL,
    entity_type TEXT NOT NULL,  -- 'sessions', 'players', 'events' 등
    entity_id UUID,  -- 특정 엔티티의 경우

    -- 복합 유니크 키
    source_entity_key TEXT GENERATED ALWAYS AS (
        source::TEXT || ':' || entity_type || ':' || COALESCE(entity_id::TEXT, 'all')
    ) STORED UNIQUE,

    -- 동기화 상태
    status orch_sync_status DEFAULT 'pending',
    sync_direction TEXT DEFAULT 'pull',  -- pull, push, bidirectional

    -- 마지막 동기화 정보
    last_synced_at TIMESTAMPTZ,
    last_sync_duration_ms INTEGER,
    sync_hash TEXT,  -- 마지막 동기화 데이터 해시

    -- 통계
    total_records INTEGER DEFAULT 0,
    last_record_count INTEGER DEFAULT 0,
    last_created_count INTEGER DEFAULT 0,
    last_updated_count INTEGER DEFAULT 0,
    last_deleted_count INTEGER DEFAULT 0,

    -- 에러 정보
    last_error TEXT,
    last_error_at TIMESTAMPTZ,
    consecutive_failures INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,

    -- 스케줄링
    sync_interval_minutes INTEGER DEFAULT 60,
    next_sync_at TIMESTAMPTZ,
    sync_enabled BOOLEAN DEFAULT TRUE,

    -- 메타데이터
    metadata JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "last_file_path": "/nas/gfx_json/...",
        "cursor": "2024-01-15T10:00:00Z",
        "filter": {"status": "active"}
    }
    */

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_sync_status_source ON sync_status(source);
CREATE INDEX idx_sync_status_entity_type ON sync_status(entity_type);
CREATE INDEX idx_sync_status_status ON sync_status(status);
CREATE INDEX idx_sync_status_next_sync ON sync_status(next_sync_at)
    WHERE sync_enabled = TRUE;
CREATE INDEX idx_sync_status_last_synced ON sync_status(last_synced_at DESC);
```

### 4.4 sync_history (동기화 이력)

```sql
-- ============================================================================
-- sync_history: 동기화 작업 이력
-- ============================================================================

CREATE TABLE sync_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 동기화 상태 참조
    sync_status_id UUID NOT NULL REFERENCES sync_status(id) ON DELETE CASCADE,
    job_id UUID REFERENCES job_queue(id) ON DELETE SET NULL,

    -- 작업 정보
    operation orch_sync_operation NOT NULL,
    source orch_data_source NOT NULL,
    entity_type TEXT NOT NULL,

    -- 결과 통계
    records_processed INTEGER DEFAULT 0,
    records_created INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_deleted INTEGER DEFAULT 0,
    records_skipped INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,

    -- 성능 메트릭
    duration_ms INTEGER,
    throughput_per_second NUMERIC(10,2),

    -- 체크섬
    before_hash TEXT,
    after_hash TEXT,

    -- 에러 정보
    error_count INTEGER DEFAULT 0,
    errors JSONB DEFAULT '[]'::JSONB,
    /*
    [
        {
            "record_id": "uuid",
            "error": "Validation failed",
            "field": "chips",
            "value": -100
        }
    ]
    */

    -- 메타데이터
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 타임스탬프
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_sync_history_status ON sync_history(sync_status_id);
CREATE INDEX idx_sync_history_job ON sync_history(job_id);
CREATE INDEX idx_sync_history_operation ON sync_history(operation);
CREATE INDEX idx_sync_history_source ON sync_history(source);
CREATE INDEX idx_sync_history_created ON sync_history(created_at DESC);

-- 파티셔닝 고려 (대용량 이력)
-- PARTITION BY RANGE (created_at);
```

### 4.5 system_config (시스템 설정)

```sql
-- ============================================================================
-- system_config: 시스템 전역 설정 저장
-- ============================================================================

CREATE TABLE system_config (
    key TEXT PRIMARY KEY,

    -- 값
    value JSONB NOT NULL,
    value_type TEXT NOT NULL,  -- string, number, boolean, json, array

    -- 분류
    category TEXT NOT NULL DEFAULT 'general',
    subcategory TEXT,

    -- 설명
    description TEXT,
    display_name TEXT,
    help_text TEXT,

    -- 검증
    validation JSONB,
    /*
    {
        "type": "number",
        "min": 1,
        "max": 100,
        "required": true
    }
    */

    -- 기본값
    default_value JSONB,

    -- 보안
    is_sensitive BOOLEAN DEFAULT FALSE,  -- 암호화 필요 여부
    is_readonly BOOLEAN DEFAULT FALSE,   -- 읽기 전용

    -- 환경별 오버라이드
    environment_overrides JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "production": {"value": 100},
        "staging": {"value": 50}
    }
    */

    -- 메타데이터
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    sort_order INTEGER DEFAULT 0,

    -- 관리 정보
    updated_by TEXT,
    updated_reason TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_system_config_category ON system_config(category);
CREATE INDEX idx_system_config_tags ON system_config USING GIN (tags);
```

### 4.6 notifications (알림)

```sql
-- ============================================================================
-- notifications: 시스템 알림
-- ============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 알림 정보
    type orch_notification_type NOT NULL,
    level orch_notification_level DEFAULT 'medium',
    title TEXT NOT NULL,
    message TEXT NOT NULL,

    -- 상세 데이터
    data JSONB DEFAULT '{}'::JSONB,

    -- 소스 정보
    source orch_data_source,
    entity_type TEXT,
    entity_id UUID,

    -- 관련 작업
    job_id UUID REFERENCES job_queue(id) ON DELETE SET NULL,

    -- 대상
    target_user TEXT,  -- 특정 사용자 또는 'all'
    target_role TEXT,  -- 특정 역할

    -- 상태
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    read_by TEXT,

    dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMPTZ,
    dismissed_by TEXT,

    -- 만료
    expires_at TIMESTAMPTZ,

    -- 액션
    action_url TEXT,
    action_label TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_level ON notifications(level);
CREATE INDEX idx_notifications_source ON notifications(source);
CREATE INDEX idx_notifications_job ON notifications(job_id);
CREATE INDEX idx_notifications_unread ON notifications(target_user, read)
    WHERE read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
```

### 4.7 api_keys (API 키)

```sql
-- ============================================================================
-- api_keys: API 인증 키 관리
-- ============================================================================

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 키 정보 (실제 키는 해시로만 저장)
    key_hash TEXT NOT NULL UNIQUE,
    key_prefix TEXT NOT NULL,  -- 표시용 (예: "sk_live_abc...")
    name TEXT NOT NULL,

    -- 권한
    permissions JSONB DEFAULT '[]'::JSONB,
    /*
    [
        {"resource": "players", "actions": ["read", "write"]},
        {"resource": "events", "actions": ["read"]}
    ]
    */

    -- 제한
    rate_limit_per_minute INTEGER DEFAULT 60,
    rate_limit_per_day INTEGER DEFAULT 10000,
    allowed_ips INET[] DEFAULT ARRAY[]::INET[],
    allowed_origins TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 상태
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,

    -- 사용 통계
    last_used_at TIMESTAMPTZ,
    total_requests INTEGER DEFAULT 0,
    last_request_ip INET,

    -- 메타데이터
    description TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 관리 정보
    created_by TEXT NOT NULL,
    revoked_by TEXT,
    revoked_at TIMESTAMPTZ,
    revoke_reason TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_active ON api_keys(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_api_keys_expires ON api_keys(expires_at) WHERE expires_at IS NOT NULL;
```

### 4.8 activity_log (활동 로그)

```sql
-- ============================================================================
-- activity_log: 시스템 활동 로그
-- ============================================================================

CREATE TABLE activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 활동 정보
    action TEXT NOT NULL,
    action_category TEXT,

    -- 주체
    actor TEXT NOT NULL,
    actor_type orch_actor_type NOT NULL,
    actor_id UUID,

    -- 대상
    entity_type TEXT,
    entity_id UUID,
    entity_name TEXT,

    -- 변경 내용
    changes JSONB,
    /*
    {
        "before": {"status": "pending"},
        "after": {"status": "completed"}
    }
    */

    -- 메타데이터
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 클라이언트 정보
    ip_address INET,
    user_agent TEXT,
    request_id TEXT,

    -- 결과
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_activity_log_action ON activity_log(action);
CREATE INDEX idx_activity_log_actor ON activity_log(actor);
CREATE INDEX idx_activity_log_actor_type ON activity_log(actor_type);
CREATE INDEX idx_activity_log_entity ON activity_log(entity_type, entity_id);
CREATE INDEX idx_activity_log_created ON activity_log(created_at DESC);

-- 파티셔닝 (대용량 로그)
-- PARTITION BY RANGE (created_at);
```

---

## 5. 통합 뷰 정의

### 5.1 unified_players (통합 플레이어 뷰)

> ⚠️ **변경됨 (2026-01-16)**: manual_players 삭제 → gfx/wsop만 UNION

```sql
-- ============================================================================
-- unified_players: 모든 소스의 플레이어 통합 뷰
-- GFX, WSOP+ 데이터를 병합 (manual_players 삭제됨)
-- ============================================================================

CREATE OR REPLACE VIEW unified_players AS
SELECT
    id,
    'gfx' AS source,
    player_hash AS external_id,
    name,
    name AS name_display,
    NULL AS country_code,
    NULL AS profile_image_url,
    created_at,
    updated_at
FROM gfx_players

UNION ALL

SELECT
    id,
    'wsop' AS source,
    wsop_player_id AS external_id,
    name,
    name AS name_display,
    country_code,
    profile_image_url,
    created_at,
    updated_at
FROM wsop_players;

-- 연결된 플레이어 정보는 player_link_mapping에서 조회
-- SELECT * FROM player_link_mapping WHERE is_verified = TRUE;
```

### 5.2 unified_events (통합 이벤트 뷰)

```sql
-- ============================================================================
-- unified_events: 통합 이벤트 뷰
-- WSOP+, GFX, Cuesheet 이벤트 병합
-- ============================================================================

CREATE OR REPLACE VIEW unified_events AS
SELECT
    'wsop' AS source,
    we.id AS source_id,
    we.event_id AS source_code,
    we.event_name AS name,
    we.event_type::TEXT AS event_type,
    we.start_date,
    we.end_date,
    we.buy_in,
    we.prize_pool,
    we.total_entries,
    we.status::TEXT AS status,
    we.venue,
    we.created_at,
    we.updated_at

FROM wsop_events we

UNION ALL

SELECT
    'gfx' AS source,
    gs.id AS source_id,
    gs.session_id::TEXT AS source_code,
    gs.event_title AS name,
    gs.table_type::TEXT AS event_type,
    gs.session_created_at::DATE AS start_date,
    gs.session_created_at::DATE AS end_date,
    NULL AS buy_in,
    NULL AS prize_pool,
    gs.player_count AS total_entries,
    gs.sync_status::TEXT AS status,
    NULL AS venue,
    gs.created_at,
    gs.updated_at

FROM gfx_sessions gs

UNION ALL

SELECT
    'cuesheet' AS source,
    bs.id AS source_id,
    bs.session_code AS source_code,
    bs.event_name AS name,
    'broadcast' AS event_type,
    bs.broadcast_date AS start_date,
    bs.broadcast_date AS end_date,
    NULL AS buy_in,
    NULL AS prize_pool,
    bs.total_cue_items AS total_entries,
    bs.status::TEXT AS status,
    NULL AS venue,
    bs.created_at,
    bs.updated_at

FROM broadcast_sessions bs

ORDER BY start_date DESC;
```

### 5.3 unified_chip_data (통합 칩 데이터 뷰)

> ⚠️ **변경됨 (2026-01-16)**: chip_snapshots 삭제 → wsop_chip_counts/gfx_hand_players만

```sql
-- ============================================================================
-- unified_chip_data: 통합 칩 데이터 뷰
-- WSOP+ 칩카운트 + GFX 핸드별 스택 병합 (chip_snapshots 삭제됨)
-- ============================================================================

CREATE OR REPLACE VIEW unified_chip_data AS
-- WSOP Chip Counts
SELECT
    'wsop' AS source,
    wcc.id,
    wcc.event_id,
    wcc.player_id,
    wp.name AS player_name,
    wp.country_code,
    wcc.chip_count,
    wcc.rank,
    wcc.table_num,
    wcc.seat_num,
    wcc.recorded_at,
    wcc.source AS data_source
FROM wsop_chip_counts wcc
LEFT JOIN wsop_players wp ON wcc.player_id = wp.id

UNION ALL

-- GFX Hand Players (핸드 종료 시점 스택)
SELECT
    'gfx' AS source,
    ghp.id,
    NULL::UUID AS event_id,
    ghp.player_id,
    ghp.player_name,
    NULL AS country_code,
    ghp.end_stack_amt::BIGINT AS chip_count,
    NULL::INTEGER AS rank,
    NULL::INTEGER AS table_num,
    ghp.seat_num,
    gh.start_time AS recorded_at,
    'gfx_hand' AS data_source
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id;

-- chip_snapshots UNION 제거됨 (테이블 삭제)
```

### 5.4 v_job_queue_summary (작업 큐 요약 뷰)

```sql
-- ============================================================================
-- v_job_queue_summary: 작업 큐 상태 요약
-- ============================================================================

CREATE OR REPLACE VIEW v_job_queue_summary AS
SELECT
    job_type,
    status,
    COUNT(*) AS count,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) AS avg_duration_seconds,
    MAX(created_at) AS last_created,
    MAX(completed_at) AS last_completed

FROM job_queue
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY job_type, status
ORDER BY job_type, status;
```

### 5.5 v_sync_dashboard (동기화 대시보드 뷰)

```sql
-- ============================================================================
-- v_sync_dashboard: 동기화 상태 대시보드
-- ============================================================================

CREATE OR REPLACE VIEW v_sync_dashboard AS
SELECT
    ss.id,
    ss.source,
    ss.entity_type,
    ss.status,
    ss.last_synced_at,
    ss.next_sync_at,
    ss.consecutive_failures,
    ss.total_records,
    ss.sync_enabled,

    -- 마지막 동기화 결과
    sh.records_processed AS last_records_processed,
    sh.records_created AS last_records_created,
    sh.records_failed AS last_records_failed,
    sh.duration_ms AS last_duration_ms,

    -- 상태 계산
    CASE
        WHEN ss.status = 'failed' OR ss.consecutive_failures > 3 THEN 'error'
        WHEN ss.status = 'in_progress' THEN 'syncing'
        WHEN ss.last_synced_at < NOW() - (ss.sync_interval_minutes * INTERVAL '2 minutes') THEN 'stale'
        ELSE 'healthy'
    END AS health_status,

    ss.updated_at

FROM sync_status ss
LEFT JOIN LATERAL (
    SELECT * FROM sync_history
    WHERE sync_status_id = ss.id
    ORDER BY created_at DESC
    LIMIT 1
) sh ON TRUE
ORDER BY ss.source, ss.entity_type;
```

---

## 6. 함수 및 트리거

### 6.1 작업 큐 다음 작업 가져오기

```sql
-- ============================================================================
-- 함수: 다음 처리할 작업 가져오기 (락 포함)
-- ============================================================================

CREATE OR REPLACE FUNCTION claim_next_job(
    p_worker_id TEXT,
    p_job_types orch_job_type[] DEFAULT NULL,
    p_lock_duration_minutes INTEGER DEFAULT 30
)
RETURNS TABLE (
    job_id UUID,
    job_type orch_job_type,
    job_name TEXT,
    payload JSONB
) AS $$
DECLARE
    v_job_id UUID;
BEGIN
    -- 대기 중인 작업 중 가장 높은 우선순위 선택 및 락
    UPDATE job_queue jq
    SET
        status = 'running',
        worker_id = p_worker_id,
        started_at = NOW(),
        locked_at = NOW(),
        lock_expires_at = NOW() + (p_lock_duration_minutes || ' minutes')::INTERVAL
    WHERE jq.id = (
        SELECT id FROM job_queue
        WHERE status = 'pending'
          AND (scheduled_at IS NULL OR scheduled_at <= NOW())
          AND (p_job_types IS NULL OR job_type = ANY(p_job_types))
          AND (lock_expires_at IS NULL OR lock_expires_at < NOW())
        ORDER BY priority ASC, created_at ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    RETURNING jq.id INTO v_job_id;

    -- 결과 반환
    RETURN QUERY
    SELECT jq.id, jq.job_type, jq.job_name, jq.payload
    FROM job_queue jq
    WHERE jq.id = v_job_id;
END;
$$ LANGUAGE plpgsql;
```

### 6.2 작업 완료 처리

```sql
-- ============================================================================
-- 함수: 작업 완료 처리
-- ============================================================================

CREATE OR REPLACE FUNCTION complete_job(
    p_job_id UUID,
    p_result JSONB DEFAULT NULL,
    p_success BOOLEAN DEFAULT TRUE,
    p_error_message TEXT DEFAULT NULL,
    p_error_details JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE job_queue
    SET
        status = CASE WHEN p_success THEN 'completed' ELSE 'failed' END,
        result = p_result,
        error_message = p_error_message,
        error_details = p_error_details,
        completed_at = NOW(),
        worker_id = NULL,
        locked_at = NULL,
        lock_expires_at = NULL,
        progress = CASE WHEN p_success THEN 100 ELSE progress END
    WHERE id = p_job_id;

    -- 알림 생성
    INSERT INTO notifications (type, level, title, message, job_id, source)
    SELECT
        CASE WHEN p_success THEN 'success' ELSE 'error' END,
        CASE WHEN p_success THEN 'low' ELSE 'high' END,
        CASE WHEN p_success THEN 'Job Completed' ELSE 'Job Failed' END,
        CASE
            WHEN p_success THEN 'Job ' || job_name || ' completed successfully'
            ELSE 'Job ' || job_name || ' failed: ' || COALESCE(p_error_message, 'Unknown error')
        END,
        p_job_id,
        'system'
    FROM job_queue
    WHERE id = p_job_id;
END;
$$ LANGUAGE plpgsql;
```

### 6.3 동기화 상태 업데이트

```sql
-- ============================================================================
-- 함수: 동기화 완료 후 상태 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_sync_completion(
    p_sync_status_id UUID,
    p_success BOOLEAN,
    p_records_processed INTEGER DEFAULT 0,
    p_records_created INTEGER DEFAULT 0,
    p_records_updated INTEGER DEFAULT 0,
    p_records_failed INTEGER DEFAULT 0,
    p_duration_ms INTEGER DEFAULT 0,
    p_error_message TEXT DEFAULT NULL,
    p_sync_hash TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- sync_status 업데이트
    UPDATE sync_status
    SET
        status = CASE WHEN p_success THEN 'synced' ELSE 'failed' END,
        last_synced_at = NOW(),
        last_sync_duration_ms = p_duration_ms,
        sync_hash = COALESCE(p_sync_hash, sync_hash),
        last_record_count = p_records_processed,
        last_created_count = p_records_created,
        last_updated_count = p_records_updated,
        total_records = CASE WHEN p_success THEN total_records + p_records_created ELSE total_records END,
        last_error = p_error_message,
        last_error_at = CASE WHEN NOT p_success THEN NOW() ELSE last_error_at END,
        consecutive_failures = CASE WHEN p_success THEN 0 ELSE consecutive_failures + 1 END,
        next_sync_at = NOW() + (sync_interval_minutes || ' minutes')::INTERVAL,
        updated_at = NOW()
    WHERE id = p_sync_status_id;

    -- sync_history 기록
    INSERT INTO sync_history (
        sync_status_id,
        operation,
        source,
        entity_type,
        records_processed,
        records_created,
        records_updated,
        records_failed,
        duration_ms,
        started_at,
        completed_at
    )
    SELECT
        p_sync_status_id,
        'incremental',
        source,
        entity_type,
        p_records_processed,
        p_records_created,
        p_records_updated,
        p_records_failed,
        p_duration_ms,
        NOW() - (p_duration_ms || ' milliseconds')::INTERVAL,
        NOW()
    FROM sync_status
    WHERE id = p_sync_status_id;
END;
$$ LANGUAGE plpgsql;
```

### 6.4 활동 로그 기록

```sql
-- ============================================================================
-- 함수: 활동 로그 기록
-- ============================================================================

CREATE OR REPLACE FUNCTION log_activity(
    p_action TEXT,
    p_actor TEXT,
    p_actor_type orch_actor_type,
    p_entity_type TEXT DEFAULT NULL,
    p_entity_id UUID DEFAULT NULL,
    p_changes JSONB DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO activity_log (
        action,
        actor,
        actor_type,
        entity_type,
        entity_id,
        changes,
        metadata,
        ip_address,
        request_id
    ) VALUES (
        p_action,
        p_actor,
        p_actor_type,
        p_entity_type,
        p_entity_id,
        p_changes,
        p_metadata,
        NULLIF(current_setting('app.client_ip', TRUE), '')::INET,
        current_setting('app.request_id', TRUE)
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;
```

### 6.5 시스템 설정 조회

```sql
-- ============================================================================
-- 함수: 시스템 설정 조회 (환경별 오버라이드 적용)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_config(
    p_key TEXT,
    p_environment TEXT DEFAULT 'production'
)
RETURNS JSONB AS $$
DECLARE
    v_value JSONB;
    v_override JSONB;
BEGIN
    SELECT value, environment_overrides->p_environment
    INTO v_value, v_override
    FROM system_config
    WHERE key = p_key;

    -- 환경별 오버라이드가 있으면 적용
    IF v_override IS NOT NULL THEN
        RETURN COALESCE(v_override->'value', v_value);
    END IF;

    RETURN v_value;
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## 7. 초기 설정 데이터

### 7.1 시스템 설정 초기값

```sql
-- ============================================================================
-- 시스템 설정 초기 데이터
-- ============================================================================

INSERT INTO system_config (key, value, value_type, category, description) VALUES
-- 동기화 설정
('sync.gfx.interval_minutes', '60', 'number', 'sync', 'GFX JSON 동기화 간격 (분)'),
('sync.gfx.enabled', 'true', 'boolean', 'sync', 'GFX 동기화 활성화'),
('sync.wsop.interval_minutes', '30', 'number', 'sync', 'WSOP+ 동기화 간격 (분)'),
('sync.wsop.enabled', 'true', 'boolean', 'sync', 'WSOP+ 동기화 활성화'),

-- 렌더링 설정
('render.default_format', '"mp4"', 'string', 'render', '기본 출력 포맷'),
('render.default_resolution', '"1920x1080"', 'string', 'render', '기본 해상도'),
('render.max_concurrent_jobs', '3', 'number', 'render', '최대 동시 렌더링 작업'),
('render.timeout_minutes', '30', 'number', 'render', '렌더링 타임아웃 (분)'),

-- 작업 큐 설정
('job.max_retries', '3', 'number', 'job', '최대 재시도 횟수'),
('job.retry_delay_seconds', '60', 'number', 'job', '재시도 대기 시간 (초)'),
('job.timeout_seconds', '3600', 'number', 'job', '작업 타임아웃 (초)'),

-- 알림 설정
('notification.email_enabled', 'false', 'boolean', 'notification', '이메일 알림 활성화'),
('notification.slack_enabled', 'false', 'boolean', 'notification', 'Slack 알림 활성화'),

-- 일반 설정
('general.timezone', '"Asia/Seoul"', 'string', 'general', '기본 시간대'),
('general.language', '"ko"', 'string', 'general', '기본 언어');
```

### 7.2 초기 동기화 상태

```sql
-- ============================================================================
-- 동기화 상태 초기 데이터
-- ============================================================================

INSERT INTO sync_status (source, entity_type, status, sync_interval_minutes) VALUES
('gfx', 'sessions', 'pending', 60),
('gfx', 'hands', 'pending', 60),
('gfx', 'players', 'pending', 60),
('wsop', 'events', 'pending', 30),
('wsop', 'players', 'pending', 30),
('wsop', 'chip_counts', 'pending', 15),
-- ('manual', 'players', 'pending', 120),  -- manual_players 삭제됨
('cuesheet', 'broadcast_sessions', 'pending', 60),
('cuesheet', 'cue_sheets', 'pending', 60),
('cuesheet', 'cue_items', 'pending', 30);
-- ('cuesheet', 'chip_snapshots', 'pending', 15);  -- chip_snapshots 삭제됨
```

---

## 8. 인덱스 전략 및 쿼리 패턴

### 8.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 대기 작업 조회 | `WHERE status = 'pending'` | `idx_job_queue_pending` |
| 실행 중 작업 | `WHERE status = 'running'` | `idx_job_queue_running` |
| 예약 작업 | `WHERE scheduled_at <= NOW()` | `idx_job_queue_scheduled` |
| 동기화 대상 | `WHERE next_sync_at <= NOW()` | `idx_sync_status_next_sync` |
| 미읽은 알림 | `WHERE read = FALSE` | `idx_notifications_unread` |
| API 키 검증 | `WHERE key_hash = ?` | `idx_api_keys_hash` |
| 활동 로그 검색 | `WHERE entity_type = ? AND entity_id = ?` | `idx_activity_log_entity` |

### 8.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- job_queue.id, render_queue.id, sync_status.id, etc.

-- Unique Constraints
-- system_config.key
-- api_keys.key_hash
-- sync_status.source_entity_key

-- B-tree Indexes (범위/정렬 쿼리)
-- job_queue: priority, created_at, scheduled_at
-- render_queue: priority, queued_at
-- sync_status: next_sync_at

-- Partial Indexes (조건부 최적화)
-- job_queue.status WHERE 'pending'
-- notifications.read WHERE FALSE
-- api_keys.is_active WHERE TRUE

-- GIN Indexes (배열/JSONB 검색)
-- job_queue.tags
-- system_config.tags
```

---

## 9. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE job_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE render_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- job_queue 정책
-- ============================================================================
CREATE POLICY "job_queue_select_authenticated"
    ON job_queue FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "job_queue_all_service"
    ON job_queue FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- render_queue 정책
-- ============================================================================
CREATE POLICY "render_queue_select_authenticated"
    ON render_queue FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "render_queue_all_service"
    ON render_queue FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- sync_status 정책
-- ============================================================================
CREATE POLICY "sync_status_select_authenticated"
    ON sync_status FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "sync_status_all_service"
    ON sync_status FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- system_config 정책
-- ============================================================================
CREATE POLICY "system_config_select_authenticated"
    ON system_config FOR SELECT
    USING (auth.role() = 'authenticated' AND is_sensitive = FALSE);

CREATE POLICY "system_config_select_service"
    ON system_config FOR SELECT
    USING (auth.role() = 'service_role');

CREATE POLICY "system_config_update_service"
    ON system_config FOR UPDATE
    USING (auth.role() = 'service_role' AND is_readonly = FALSE);

-- ============================================================================
-- notifications 정책
-- ============================================================================
CREATE POLICY "notifications_select_own"
    ON notifications FOR SELECT
    USING (
        auth.role() = 'authenticated' AND
        (target_user IS NULL OR target_user = auth.uid()::TEXT)
    );

CREATE POLICY "notifications_update_own"
    ON notifications FOR UPDATE
    USING (
        auth.role() = 'authenticated' AND
        (target_user IS NULL OR target_user = auth.uid()::TEXT)
    );

CREATE POLICY "notifications_all_service"
    ON notifications FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- api_keys 정책
-- ============================================================================
CREATE POLICY "api_keys_select_service"
    ON api_keys FOR SELECT
    USING (auth.role() = 'service_role');

CREATE POLICY "api_keys_all_service"
    ON api_keys FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- activity_log 정책
-- ============================================================================
CREATE POLICY "activity_log_select_authenticated"
    ON activity_log FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "activity_log_insert_service"
    ON activity_log FOR INSERT
    WITH CHECK (auth.role() = 'service_role');
```

---

## 10. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. job_queue 테이블 생성
3. render_queue 테이블 생성
4. sync_status 테이블 생성
5. sync_history 테이블 생성
6. system_config 테이블 생성
7. notifications 테이블 생성
8. api_keys 테이블 생성
9. activity_log 테이블 생성
10. 통합 뷰 생성 (CREATE VIEW) - 다른 스키마 테이블 참조
11. 함수 생성 (CREATE FUNCTION)
12. 인덱스 생성 (CREATE INDEX)
13. RLS 정책 적용 (ALTER TABLE, CREATE POLICY)
14. 초기 데이터 삽입 (INSERT)
```

### Rollback 순서 (역순)

```
1. 초기 데이터 삭제 (DELETE)
2. RLS 정책 삭제 (DROP POLICY)
3. 인덱스 삭제 (DROP INDEX)
4. 함수 삭제 (DROP FUNCTION)
5. 뷰 삭제 (DROP VIEW)
6. 테이블 삭제 (역순)
7. ENUM 타입 삭제 (DROP TYPE)
```

---

## 11. 제약조건 요약

| 테이블 | 제약조건 | 설명 |
|--------|----------|------|
| `sync_status` | `source_entity_key UNIQUE` | 소스/엔티티 조합 중복 방지 |
| `system_config` | `key PRIMARY KEY` | 설정 키 중복 방지 |
| `api_keys` | `key_hash UNIQUE` | API 키 해시 중복 방지 |

---

## 12. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `src/services/job_service.py` | 작업 큐 관리 | job_queue |
| `src/services/render_service.py` | 렌더 큐 관리 | render_queue |
| `src/services/sync_service.py` | 동기화 관리 | sync_status, sync_history |
| `src/services/config_service.py` | 설정 관리 | system_config |
| `src/services/notification_service.py` | 알림 관리 | notifications |
| `src/workers/job_worker.py` | 작업 워커 | job_queue |
| `src/workers/render_worker.py` | 렌더 워커 | render_queue |
| `src/api/unified_api.py` | 통합 API | 통합 뷰 |
