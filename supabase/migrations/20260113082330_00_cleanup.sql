-- ============================================================================
-- 00_cleanup.sql: 전체 스키마 삭제 (Clean Start)
-- ============================================================================

-- ============================================================================
-- 1. 뷰 삭제 (통합 뷰)
-- ============================================================================
DROP VIEW IF EXISTS v_sync_dashboard CASCADE;
DROP VIEW IF EXISTS v_job_queue_summary CASCADE;
DROP VIEW IF EXISTS unified_chip_data CASCADE;
DROP VIEW IF EXISTS unified_events CASCADE;
DROP VIEW IF EXISTS unified_players CASCADE;
DROP VIEW IF EXISTS v_recent_hands CASCADE;
DROP VIEW IF EXISTS v_showdown_players CASCADE;
DROP VIEW IF EXISTS v_session_summary CASCADE;
DROP VIEW IF EXISTS v_event_summary CASCADE;
DROP VIEW IF EXISTS v_player_stats CASCADE;
DROP VIEW IF EXISTS v_chip_count_latest CASCADE;
DROP VIEW IF EXISTS v_leaderboard CASCADE;

-- ============================================================================
-- 2. 테이블 삭제 (의존성 역순)
-- ============================================================================

-- Orchestration 테이블
DROP TABLE IF EXISTS activity_log CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS system_config CASCADE;
DROP TABLE IF EXISTS sync_history CASCADE;
DROP TABLE IF EXISTS sync_status CASCADE;
DROP TABLE IF EXISTS render_queue CASCADE;
DROP TABLE IF EXISTS job_queue CASCADE;

-- Cuesheet 테이블
DROP TABLE IF EXISTS gfx_triggers CASCADE;
DROP TABLE IF EXISTS cue_items CASCADE;
DROP TABLE IF EXISTS chip_snapshots CASCADE;
DROP TABLE IF EXISTS cue_templates CASCADE;
DROP TABLE IF EXISTS cue_sheets CASCADE;
DROP TABLE IF EXISTS broadcast_sessions CASCADE;

-- Manual 테이블
DROP TABLE IF EXISTS manual_audit_log CASCADE;
DROP TABLE IF EXISTS player_link_mapping CASCADE;
DROP TABLE IF EXISTS player_overrides CASCADE;
DROP TABLE IF EXISTS profile_images CASCADE;
DROP TABLE IF EXISTS manual_players CASCADE;

-- WSOP 테이블
DROP TABLE IF EXISTS wsop_import_logs CASCADE;
DROP TABLE IF EXISTS wsop_standings CASCADE;
DROP TABLE IF EXISTS wsop_chip_counts CASCADE;
DROP TABLE IF EXISTS wsop_event_players CASCADE;
DROP TABLE IF EXISTS wsop_events CASCADE;
DROP TABLE IF EXISTS wsop_players CASCADE;

-- GFX 테이블
DROP TABLE IF EXISTS sync_log CASCADE;
DROP TABLE IF EXISTS hand_grades CASCADE;
DROP TABLE IF EXISTS gfx_events CASCADE;
DROP TABLE IF EXISTS gfx_hand_players CASCADE;
DROP TABLE IF EXISTS gfx_hands CASCADE;
DROP TABLE IF EXISTS gfx_sessions CASCADE;
DROP TABLE IF EXISTS gfx_players CASCADE;

-- Sample data 테이블 (존재 시)
DROP TABLE IF EXISTS aep_media_sources CASCADE;
DROP TABLE IF EXISTS aep_field_keys CASCADE;
DROP TABLE IF EXISTS aep_compositions CASCADE;

-- 기존 레거시 테이블
DROP TABLE IF EXISTS layers CASCADE;
DROP TABLE IF EXISTS compositions CASCADE;
DROP TABLE IF EXISTS footage_assets CASCADE;
DROP TABLE IF EXISTS aep_projects CASCADE;

-- ============================================================================
-- 3. ENUM 타입 삭제 (전체)
-- ============================================================================

-- Orchestration ENUMs
DROP TYPE IF EXISTS orch_actor_type CASCADE;
DROP TYPE IF EXISTS orch_notification_level CASCADE;
DROP TYPE IF EXISTS orch_notification_type CASCADE;
DROP TYPE IF EXISTS orch_sync_operation CASCADE;
DROP TYPE IF EXISTS orch_sync_status CASCADE;
DROP TYPE IF EXISTS orch_render_status CASCADE;
DROP TYPE IF EXISTS orch_render_type CASCADE;
DROP TYPE IF EXISTS orch_job_status CASCADE;
DROP TYPE IF EXISTS orch_job_type CASCADE;
DROP TYPE IF EXISTS orch_data_source CASCADE;

-- Cuesheet ENUMs
DROP TYPE IF EXISTS cue_template_type CASCADE;
DROP TYPE IF EXISTS cue_render_status CASCADE;
DROP TYPE IF EXISTS cue_trigger_type CASCADE;
DROP TYPE IF EXISTS cue_item_status CASCADE;
DROP TYPE IF EXISTS cue_hand_rank CASCADE;
DROP TYPE IF EXISTS cue_item_type CASCADE;
DROP TYPE IF EXISTS cue_content_type CASCADE;
DROP TYPE IF EXISTS cue_sheet_status CASCADE;
DROP TYPE IF EXISTS cue_sheet_type CASCADE;
DROP TYPE IF EXISTS cue_broadcast_status CASCADE;

-- Manual ENUMs
DROP TYPE IF EXISTS manual_override_field CASCADE;
DROP TYPE IF EXISTS manual_audit_action CASCADE;
DROP TYPE IF EXISTS manual_match_method CASCADE;
DROP TYPE IF EXISTS manual_storage_type CASCADE;
DROP TYPE IF EXISTS manual_image_type CASCADE;

-- WSOP ENUMs
DROP TYPE IF EXISTS wsop_chip_source CASCADE;
DROP TYPE IF EXISTS wsop_import_status CASCADE;
DROP TYPE IF EXISTS wsop_import_type CASCADE;
DROP TYPE IF EXISTS wsop_player_status CASCADE;
DROP TYPE IF EXISTS wsop_event_status CASCADE;
DROP TYPE IF EXISTS wsop_event_type CASCADE;

-- GFX ENUMs
DROP TYPE IF EXISTS gfx_sync_status CASCADE;
DROP TYPE IF EXISTS sync_status CASCADE;
DROP TYPE IF EXISTS ante_type CASCADE;
DROP TYPE IF EXISTS event_type CASCADE;
DROP TYPE IF EXISTS bet_structure CASCADE;
DROP TYPE IF EXISTS game_class CASCADE;
DROP TYPE IF EXISTS game_variant CASCADE;
DROP TYPE IF EXISTS table_type CASCADE;

-- 기존 레거시 ENUMs
DROP TYPE IF EXISTS analysis_status CASCADE;
DROP TYPE IF EXISTS footage_type CASCADE;
DROP TYPE IF EXISTS layer_type CASCADE;

-- ============================================================================
-- 4. 함수 삭제
-- ============================================================================

-- GFX 함수
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS generate_player_hash(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_session_stats(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS parse_iso8601_duration(TEXT) CASCADE;

-- WSOP 함수
DROP FUNCTION IF EXISTS update_wsop_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS normalize_player_name(TEXT) CASCADE;
DROP FUNCTION IF EXISTS set_normalized_name() CASCADE;
DROP FUNCTION IF EXISTS update_event_player_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_event_rankings(UUID) CASCADE;

-- Manual 함수
DROP FUNCTION IF EXISTS update_manual_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS generate_player_code() CASCADE;
DROP FUNCTION IF EXISTS set_player_code() CASCADE;
DROP FUNCTION IF EXISTS normalize_manual_player_name(TEXT) CASCADE;
DROP FUNCTION IF EXISTS set_manual_normalized_name() CASCADE;
DROP FUNCTION IF EXISTS log_manual_audit() CASCADE;
DROP FUNCTION IF EXISTS get_player_field_with_override(UUID, TEXT, TEXT) CASCADE;

-- Cuesheet 함수
DROP FUNCTION IF EXISTS update_cue_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS update_cue_sheet_stats() CASCADE;
DROP FUNCTION IF EXISTS update_session_stats() CASCADE;
DROP FUNCTION IF EXISTS increment_template_usage() CASCADE;
DROP FUNCTION IF EXISTS transition_cue_item_status(UUID, cue_item_status, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_next_cue_item(UUID) CASCADE;

-- Orchestration 함수
DROP FUNCTION IF EXISTS claim_next_job(TEXT, orch_job_type[], INTEGER) CASCADE;
DROP FUNCTION IF EXISTS complete_job(UUID, JSONB, BOOLEAN, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS update_sync_completion(UUID, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS log_activity(TEXT, TEXT, orch_actor_type, TEXT, UUID, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS get_config(TEXT, TEXT) CASCADE;

-- 기존 레거시 함수
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
DROP FUNCTION IF EXISTS get_hands_from_session CASCADE;
DROP FUNCTION IF EXISTS search_sessions_with_premium_hands CASCADE;

-- ============================================================================
-- 완료
-- ============================================================================
