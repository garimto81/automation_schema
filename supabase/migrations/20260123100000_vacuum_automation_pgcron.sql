-- Migration: pg_cron을 통한 VACUUM 자동화
-- Issue: #2 - VACUUM ANALYZE 자동화
-- Date: 2026-01-23
--
-- pg_cron 확장을 사용하여 정기적인 VACUUM ANALYZE 작업을 스케줄링합니다.
-- Supabase Pro 플랜 이상에서 pg_cron 사용 가능

-- ============================================================
-- 1. pg_cron 확장 활성화 (이미 활성화된 경우 무시)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================
-- 2. 기존 스케줄 정리 (멱등성)
-- ============================================================
DO $$
BEGIN
    -- 기존 VACUUM 작업 삭제 시도
    PERFORM cron.unschedule('vacuum-gfx-tables');
    PERFORM cron.unschedule('vacuum-json-tables');
    PERFORM cron.unschedule('vacuum-ae-tables');
    PERFORM cron.unschedule('analyze-all-tables');
EXCEPTION WHEN OTHERS THEN
    -- 작업이 없으면 무시
    NULL;
END $$;

-- ============================================================
-- 3. VACUUM ANALYZE 스케줄 등록
-- ============================================================

-- 매일 새벽 3시 (UTC) - 주요 GFX 테이블 VACUUM
SELECT cron.schedule(
    'vacuum-gfx-tables',
    '0 3 * * *',
    E'VACUUM ANALYZE public.gfx_aep_compositions; VACUUM ANALYZE public.gfx_sessions; VACUUM ANALYZE public.gfx_hands; VACUUM ANALYZE public.gfx_hand_players;'
);

-- 매일 새벽 3시 30분 (UTC) - JSON 테이블 VACUUM
SELECT cron.schedule(
    'vacuum-json-tables',
    '30 3 * * *',
    E'VACUUM ANALYZE json.hands; VACUUM ANALYZE json.hand_players; VACUUM ANALYZE json.hand_actions; VACUUM ANALYZE json.gfx_sessions;'
);

-- 매일 새벽 4시 (UTC) - AE 테이블 VACUUM
SELECT cron.schedule(
    'vacuum-ae-tables',
    '0 4 * * *',
    E'VACUUM ANALYZE ae.compositions; VACUUM ANALYZE ae.templates; VACUUM ANALYZE ae.render_jobs;'
);

-- 매주 일요일 새벽 5시 (UTC) - 전체 ANALYZE
SELECT cron.schedule(
    'analyze-all-tables',
    '0 5 * * 0',
    'ANALYZE;'
);

-- ============================================================
-- 4. 스케줄 확인 쿼리 (정보용)
-- ============================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM cron.job;

    RAISE NOTICE 'pg_cron VACUUM 자동화 설정 완료!';
    RAISE NOTICE '등록된 스케줄: % 개', v_count;
    RAISE NOTICE '';
    RAISE NOTICE '스케줄 확인: SELECT * FROM cron.job;';
    RAISE NOTICE '실행 로그: SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;';
END $$;
