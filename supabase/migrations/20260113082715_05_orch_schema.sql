-- ============================================================================
-- Migration: 05_orch_schema
-- Description: Orchestration layer schema (작업 큐, 렌더 큐, 동기화 상태 관리)
-- Version: 1.0.0
-- Date: 2026-01-13
-- ============================================================================

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

-- ============================================================================
-- Tables
-- ============================================================================

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

-- ============================================================================
-- sync_status: 데이터 소스별 동기화 상태 추적
-- ============================================================================

CREATE TABLE sync_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 소스 식별
    source orch_data_source NOT NULL,
    entity_type TEXT NOT NULL,  -- 'sessions', 'players', 'events' 등
    entity_id UUID,  -- 특정 엔티티의 경우

    -- 복합 유니크 키 (source, entity_type, entity_id 조합)

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
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약조건
    CONSTRAINT uq_sync_status_source_entity UNIQUE (source, entity_type, entity_id)
);

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

-- ============================================================================
-- Indexes
-- ============================================================================

-- job_queue 인덱스
CREATE INDEX idx_job_queue_type ON job_queue(job_type);
CREATE INDEX idx_job_queue_status ON job_queue(status);
CREATE INDEX idx_job_queue_priority ON job_queue(priority, created_at);
CREATE INDEX idx_job_queue_scheduled ON job_queue(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_job_queue_pending ON job_queue(priority, created_at)
    WHERE status = 'pending';
CREATE INDEX idx_job_queue_running ON job_queue(worker_id, started_at)
    WHERE status = 'running';
CREATE INDEX idx_job_queue_parent ON job_queue(parent_job_id);
CREATE INDEX idx_job_queue_tags ON job_queue USING GIN (tags);
CREATE INDEX idx_job_queue_created ON job_queue(created_at DESC);

-- render_queue 인덱스
CREATE INDEX idx_render_queue_job ON render_queue(job_id);
CREATE INDEX idx_render_queue_type ON render_queue(render_type);
CREATE INDEX idx_render_queue_status ON render_queue(status);
CREATE INDEX idx_render_queue_priority ON render_queue(priority, queued_at);
CREATE INDEX idx_render_queue_pending ON render_queue(priority, queued_at)
    WHERE status = 'pending';
CREATE INDEX idx_render_queue_data_hash ON render_queue(data_hash);
CREATE INDEX idx_render_queue_worker ON render_queue(worker_id) WHERE worker_id IS NOT NULL;
CREATE INDEX idx_render_queue_cue_item ON render_queue(cue_item_id);

-- sync_status 인덱스
CREATE INDEX idx_sync_status_source ON sync_status(source);
CREATE INDEX idx_sync_status_entity_type ON sync_status(entity_type);
CREATE INDEX idx_sync_status_status ON sync_status(status);
CREATE INDEX idx_sync_status_next_sync ON sync_status(next_sync_at)
    WHERE sync_enabled = TRUE;
CREATE INDEX idx_sync_status_last_synced ON sync_status(last_synced_at DESC);

-- sync_history 인덱스
CREATE INDEX idx_sync_history_status ON sync_history(sync_status_id);
CREATE INDEX idx_sync_history_job ON sync_history(job_id);
CREATE INDEX idx_sync_history_operation ON sync_history(operation);
CREATE INDEX idx_sync_history_source ON sync_history(source);
CREATE INDEX idx_sync_history_created ON sync_history(created_at DESC);

-- system_config 인덱스
CREATE INDEX idx_system_config_category ON system_config(category);
CREATE INDEX idx_system_config_tags ON system_config USING GIN (tags);

-- notifications 인덱스
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_level ON notifications(level);
CREATE INDEX idx_notifications_source ON notifications(source);
CREATE INDEX idx_notifications_job ON notifications(job_id);
CREATE INDEX idx_notifications_unread ON notifications(target_user, read)
    WHERE read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- api_keys 인덱스
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_active ON api_keys(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_api_keys_expires ON api_keys(expires_at) WHERE expires_at IS NOT NULL;

-- activity_log 인덱스
CREATE INDEX idx_activity_log_action ON activity_log(action);
CREATE INDEX idx_activity_log_actor ON activity_log(actor);
CREATE INDEX idx_activity_log_actor_type ON activity_log(actor_type);
CREATE INDEX idx_activity_log_entity ON activity_log(entity_type, entity_id);
CREATE INDEX idx_activity_log_created ON activity_log(created_at DESC);

-- ============================================================================
-- Functions
-- ============================================================================

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

-- ============================================================================
-- Triggers
-- ============================================================================

-- updated_at 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- job_queue 업데이트 트리거
CREATE TRIGGER trigger_job_queue_updated_at
    BEFORE UPDATE ON job_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- render_queue 업데이트 트리거
CREATE TRIGGER trigger_render_queue_updated_at
    BEFORE UPDATE ON render_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- sync_status 업데이트 트리거
CREATE TRIGGER trigger_sync_status_updated_at
    BEFORE UPDATE ON sync_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- system_config 업데이트 트리거
CREATE TRIGGER trigger_system_config_updated_at
    BEFORE UPDATE ON system_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- api_keys 업데이트 트리거
CREATE TRIGGER trigger_api_keys_updated_at
    BEFORE UPDATE ON api_keys
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RLS Policies
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
-- sync_history 정책
-- ============================================================================
CREATE POLICY "sync_history_select_authenticated"
    ON sync_history FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "sync_history_all_service"
    ON sync_history FOR ALL
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

-- ============================================================================
-- Initial Data
-- ============================================================================

-- 시스템 설정 초기 데이터
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

-- 동기화 상태 초기 데이터
INSERT INTO sync_status (source, entity_type, status, sync_interval_minutes) VALUES
('gfx', 'sessions', 'pending', 60),
('gfx', 'hands', 'pending', 60),
('gfx', 'players', 'pending', 60),
('wsop', 'events', 'pending', 30),
('wsop', 'players', 'pending', 30),
('wsop', 'chip_counts', 'pending', 15),
('manual', 'players', 'pending', 120),
('cuesheet', 'broadcast_sessions', 'pending', 60),
('cuesheet', 'cue_sheets', 'pending', 60),
('cuesheet', 'cue_items', 'pending', 30),
('cuesheet', 'chip_snapshots', 'pending', 15);
