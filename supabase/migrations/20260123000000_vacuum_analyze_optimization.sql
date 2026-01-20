-- Migration: 통계 수집 최적화
-- Issue: #2 - ANALYZE 실행으로 쿼리 최적화
-- Date: 2026-01-23
--
-- 주의: VACUUM은 마이그레이션에서 실행 불가 (별도 수동 실행 필요)
-- 이 마이그레이션은 ANALYZE만 수행합니다.

-- ============================================================
-- 1. 주요 테이블 통계 수집
-- ============================================================

-- public 스키마
ANALYZE public.gfx_aep_compositions;
ANALYZE public.gfx_sessions;
ANALYZE public.gfx_hands;
ANALYZE public.gfx_hand_players;
ANALYZE public.gfx_players;
ANALYZE public.sync_status;
ANALYZE public.aep_media_sources;
ANALYZE public.broadcast_sessions;
ANALYZE public.render_queue;
ANALYZE public.wsop_events;
ANALYZE public.wsop_standings;
ANALYZE public.gfx_aep_field_mappings;
ANALYZE public.system_config;

-- json 스키마
ANALYZE json.gfx_sessions;
ANALYZE json.hands;
ANALYZE json.hand_players;
ANALYZE json.hand_actions;
ANALYZE json.hand_results;
ANALYZE json.hand_cards;

-- ae 스키마
ANALYZE ae.compositions;
ANALYZE ae.composition_layers;
ANALYZE ae.templates;
ANALYZE ae.render_jobs;
ANALYZE ae.render_outputs;
ANALYZE ae.data_types;
ANALYZE ae.layer_data_mappings;

-- manual 스키마
ANALYZE manual.players_master;
ANALYZE manual.events;
ANALYZE manual.venues;
ANALYZE manual.commentators;
ANALYZE manual.feature_tables;
ANALYZE manual.player_profiles;
ANALYZE manual.seating_assignments;

-- wsop_plus 스키마
ANALYZE wsop_plus.tournaments;
ANALYZE wsop_plus.player_instances;
ANALYZE wsop_plus.blind_levels;
ANALYZE wsop_plus.payouts;
ANALYZE wsop_plus.schedules;

-- ============================================================
-- 2. 완료 확인
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE 'ANALYZE optimization completed successfully.';
    RAISE NOTICE 'All tables have been analyzed.';
    RAISE NOTICE '';
    RAISE NOTICE 'NOTE: VACUUM must be run separately (not in migrations).';
    RAISE NOTICE 'Run manually: VACUUM ANALYZE <table_name>;';
END $$;
