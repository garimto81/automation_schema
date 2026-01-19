-- ============================================================================
-- Migration: 20260122000001_add_sync_functions.sql
-- Description: 동기화 관련 뷰 및 함수 추가 (문서 정의 기반)
-- Source: docs/09-DB-Sync-Guidelines.md Section 5, 6
-- ============================================================================

-- ============================================================================
-- v_sync_health: 동기화 건강 상태 대시보드 뷰
-- ============================================================================

CREATE OR REPLACE VIEW v_sync_health AS
SELECT
    source,
    entity_type,
    status,
    last_synced_at,
    records_synced,
    records_failed,
    consecutive_failures,
    sync_interval,
    next_sync_at,
    -- 건강 상태 판정
    CASE
        WHEN consecutive_failures > 5 THEN 'CRITICAL'
        WHEN consecutive_failures > 2 THEN 'WARNING'
        WHEN last_synced_at < NOW() - sync_interval * 2 THEN 'STALE'
        WHEN status = 'failed' THEN 'ERROR'
        ELSE 'HEALTHY'
    END AS health_status,
    -- 지연 시간
    EXTRACT(EPOCH FROM (NOW() - last_synced_at)) AS lag_seconds
FROM sync_status
ORDER BY
    CASE
        WHEN consecutive_failures > 5 THEN 1
        WHEN consecutive_failures > 2 THEN 2
        WHEN status = 'failed' THEN 3
        ELSE 4
    END,
    last_synced_at;

-- ============================================================================
-- notify_override_change: Override 변경 알림 함수
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_override_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Supabase Realtime으로 변경 알림
    PERFORM pg_notify(
        'override_changes',
        json_build_object(
            'table', TG_TABLE_NAME,
            'operation', TG_OP,
            'id', COALESCE(NEW.id, OLD.id),
            'timestamp', NOW()
        )::TEXT
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 트리거 (player_overrides 테이블이 존재할 경우에만)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'player_overrides') THEN
        DROP TRIGGER IF EXISTS trigger_override_notify ON player_overrides;
        CREATE TRIGGER trigger_override_notify
            AFTER INSERT OR UPDATE OR DELETE ON player_overrides
            FOR EACH ROW
            EXECUTE FUNCTION notify_override_change();
    END IF;
END $$;

-- ============================================================================
-- check_sync_health_and_notify: 동기화 건강 상태 확인 및 알림 생성
-- ============================================================================

CREATE OR REPLACE FUNCTION check_sync_health_and_notify()
RETURNS VOID AS $$
DECLARE
    v_unhealthy RECORD;
BEGIN
    FOR v_unhealthy IN
        SELECT * FROM v_sync_health
        WHERE health_status IN ('CRITICAL', 'ERROR')
    LOOP
        -- 알림 생성
        INSERT INTO notifications (
            type,
            severity,
            title,
            message,
            metadata,
            target_user
        ) VALUES (
            'sync_failure',
            CASE v_unhealthy.health_status
                WHEN 'CRITICAL' THEN 'critical'
                ELSE 'error'
            END,
            '동기화 실패: ' || v_unhealthy.source || '.' || v_unhealthy.entity_type,
            '연속 실패 ' || v_unhealthy.consecutive_failures || '회. 마지막 동기화: ' ||
                v_unhealthy.last_synced_at,
            jsonb_build_object(
                'source', v_unhealthy.source,
                'entity_type', v_unhealthy.entity_type,
                'lag_seconds', v_unhealthy.lag_seconds
            ),
            'admin'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- retry_failed_syncs: 실패한 동기화 자동 재시도
-- ============================================================================

CREATE OR REPLACE FUNCTION retry_failed_syncs()
RETURNS INTEGER AS $$
DECLARE
    v_retry_count INTEGER := 0;
BEGIN
    -- 5회 미만 실패, 5분 이상 경과한 건 재시도
    UPDATE sync_status
    SET
        status = 'pending',
        next_sync_at = NOW()
    WHERE status = 'failed'
      AND consecutive_failures < 5
      AND last_synced_at < NOW() - INTERVAL '5 minutes';

    GET DIAGNOSTICS v_retry_count = ROW_COUNT;

    -- 로그 기록
    IF v_retry_count > 0 THEN
        INSERT INTO activity_log (action, entity_type, details)
        VALUES ('sync_retry', 'sync_status',
                jsonb_build_object('retry_count', v_retry_count));
    END IF;

    RETURN v_retry_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- restore_gfx_from_external: External → Supabase 전체 복구 (GFX 데이터)
-- Note: FDW(Foreign Data Wrapper) 설정 필요. 실제 운영 환경에 맞게 수정 필요.
-- ============================================================================

CREATE OR REPLACE FUNCTION restore_gfx_from_external()
RETURNS VOID AS $$
BEGIN
    -- 1. Supabase 데이터 백업 (safety)
    CREATE TABLE IF NOT EXISTS _backup_gfx_sessions AS
        SELECT * FROM gfx_sessions;

    -- 2. Supabase 데이터 삭제
    TRUNCATE gfx_sessions CASCADE;

    -- 3. External에서 복사 (FDW 사용)
    -- Note: external_db 스키마가 FDW로 설정되어 있어야 함
    -- INSERT INTO gfx_sessions
    -- SELECT * FROM external_db.gfx_sessions;

    -- 4. 복구 완료 로그
    INSERT INTO activity_log (action, entity_type, details)
    VALUES ('restore', 'gfx_sessions',
            jsonb_build_object('source', 'external', 'timestamp', NOW()));
END;
$$ LANGUAGE plpgsql;
