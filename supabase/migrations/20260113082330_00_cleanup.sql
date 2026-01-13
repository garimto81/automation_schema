-- ============================================================================
-- 00_cleanup.sql: 기존 스키마 삭제 (Clean Start)
-- ============================================================================

-- 모든 테이블 삭제 (CASCADE로 의존성 포함)
DROP TABLE IF EXISTS layers CASCADE;
DROP TABLE IF EXISTS compositions CASCADE;
DROP TABLE IF EXISTS footage_assets CASCADE;
DROP TABLE IF EXISTS aep_projects CASCADE;
DROP TABLE IF EXISTS gfx_sessions CASCADE;
DROP TABLE IF EXISTS sync_log CASCADE;

-- 모든 ENUM 타입 삭제
DROP TYPE IF EXISTS analysis_status CASCADE;
DROP TYPE IF EXISTS footage_type CASCADE;
DROP TYPE IF EXISTS layer_type CASCADE;

-- 함수 삭제
DROP FUNCTION IF EXISTS calculate_bb_count CASCADE;
DROP FUNCTION IF EXISTS format_chips CASCADE;
DROP FUNCTION IF EXISTS format_currency CASCADE;
DROP FUNCTION IF EXISTS get_dynamic_layers CASCADE;
DROP FUNCTION IF EXISTS get_project_stats CASCADE;
DROP FUNCTION IF EXISTS upsert_composition CASCADE;
DROP FUNCTION IF EXISTS upsert_footage_batch CASCADE;
DROP FUNCTION IF EXISTS search_layers_by_text CASCADE;
DROP FUNCTION IF EXISTS update_footage_usage_count CASCADE;
DROP FUNCTION IF EXISTS update_updated_at CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
DROP FUNCTION IF EXISTS get_hands_from_session CASCADE;
DROP FUNCTION IF EXISTS search_sessions_with_premium_hands CASCADE;
