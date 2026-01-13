-- ============================================================================
-- Migration: 07_seed_data
-- Description: Additional seed data (if needed)
-- Version: 1.0.0
-- Date: 2026-01-13
-- ============================================================================

-- Note: 기본 초기 데이터(system_config, sync_status)는
-- 05_orch_schema.sql에 이미 포함되어 있습니다.

-- 이 파일은 추가적인 시드 데이터가 필요한 경우 사용합니다.

-- ============================================================================
-- 추가 시드 데이터 (필요 시 추가)
-- ============================================================================

-- 예시: 기본 큐 템플릿 추가 (필요시 주석 해제)
-- INSERT INTO cue_templates (template_code, template_name, description, template_type, gfx_template_name, default_duration) VALUES
-- ('TPL-MINI-CHIP-LEFT', 'Mini Chip Table (Left)', '좌측 미니 칩 테이블', 'mini_chip_left', 'Mini_Chip_Table', 10),
-- ('TPL-MINI-CHIP-RIGHT', 'Mini Chip Table (Right)', '우측 미니 칩 테이블', 'mini_chip_right', 'Mini_Chip_Table', 10),
-- ('TPL-PLAYER-PROFILE', 'Player Profile', '선수 프로필', 'player_profile', 'L3_Profile', 15);

-- 예시: 테스트 API 키 추가 (개발 환경용, 프로덕션에서는 사용 금지)
-- INSERT INTO api_keys (key_hash, key_prefix, name, permissions, rate_limit_per_minute, rate_limit_per_day, created_by) VALUES
-- ('test_key_hash_placeholder', 'sk_test_', 'Development Test Key', '["*"]', 1000, 100000, 'system');
