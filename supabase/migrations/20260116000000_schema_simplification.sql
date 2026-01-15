-- ============================================================================
-- Migration: schema_simplification
-- Description: 스키마 단순화 - manual_players, chip_snapshots 삭제 및 구조 변경
-- Version: 1.0.0
-- Date: 2026-01-16
-- ============================================================================

-- ============================================================================
-- Phase 1: manual_players 관련 테이블 삭제
-- ============================================================================

-- 1.1 player_overrides에서 manual_player_id 컬럼 제거 및 gfx_player_id 추가
-- 기존 manual_player_id 참조 데이터가 있으면 삭제됨
ALTER TABLE player_overrides
    DROP COLUMN IF EXISTS manual_player_id;

ALTER TABLE player_overrides
    ADD COLUMN IF NOT EXISTS gfx_player_id UUID REFERENCES gfx_players(id);

-- 제약 조건 업데이트 (gfx 또는 wsop 중 하나 이상 필수)
ALTER TABLE player_overrides
    DROP CONSTRAINT IF EXISTS chk_player_override_target;
ALTER TABLE player_overrides
    ADD CONSTRAINT chk_player_override_target
    CHECK (gfx_player_id IS NOT NULL OR wsop_player_id IS NOT NULL);

-- 1.2 player_link_mapping에서 manual_player_id 컬럼 제거
ALTER TABLE player_link_mapping
    DROP COLUMN IF EXISTS manual_player_id;

-- UNIQUE 제약조건 재정의 (gfx + wsop만)
ALTER TABLE player_link_mapping
    DROP CONSTRAINT IF EXISTS player_link_mapping_unique_combo;
-- 새 UNIQUE 제약조건은 필요시 추가

-- 1.3 manual 관련 테이블 삭제 (CASCADE로 의존성 처리)
DROP TABLE IF EXISTS manual_audit_log CASCADE;

-- ============================================================================
-- Phase 1.5: chip_snapshots 삭제
-- ============================================================================

-- 2.1 cue_items에서 snapshot_id FK 제거
ALTER TABLE cue_items
    DROP COLUMN IF EXISTS snapshot_id;

-- 2.2 chip_snapshots 테이블 삭제
DROP TABLE IF EXISTS chip_snapshots CASCADE;

-- 2.3 sync_status에서 chip_snapshots 제거
DELETE FROM sync_status WHERE entity_type = 'chip_snapshots';

-- ============================================================================
-- Phase 1.5: profile_images 구조 변경
-- ============================================================================

-- 3.1 기존 player_id (manual_players FK) 컬럼 제거
-- 먼저 FK 제약 조건 삭제
ALTER TABLE profile_images
    DROP CONSTRAINT IF EXISTS profile_images_player_id_fkey;

-- player_id 컬럼 삭제
ALTER TABLE profile_images
    DROP COLUMN IF EXISTS player_id;

-- 3.2 새로운 FK 컬럼 추가
ALTER TABLE profile_images
    ADD COLUMN IF NOT EXISTS wsop_player_id UUID REFERENCES wsop_players(id),
    ADD COLUMN IF NOT EXISTS gfx_player_id UUID REFERENCES gfx_players(id);

-- 제약 조건: wsop 또는 gfx 중 하나 이상 필수
ALTER TABLE profile_images
    DROP CONSTRAINT IF EXISTS chk_profile_player_ref;
ALTER TABLE profile_images
    ADD CONSTRAINT chk_profile_player_ref
    CHECK (wsop_player_id IS NOT NULL OR gfx_player_id IS NOT NULL);

-- 인덱스 재생성
DROP INDEX IF EXISTS idx_profile_images_player;
CREATE INDEX idx_profile_images_wsop ON profile_images(wsop_player_id) WHERE wsop_player_id IS NOT NULL;
CREATE INDEX idx_profile_images_gfx ON profile_images(gfx_player_id) WHERE gfx_player_id IS NOT NULL;

-- ============================================================================
-- Phase 1: manual_players 테이블 삭제 (profile_images 참조 해제 후)
-- ============================================================================

DROP TABLE IF EXISTS manual_players CASCADE;

-- ============================================================================
-- Phase 1: 관련 ENUM 삭제
-- ============================================================================

-- manual_image_type은 profile_images에서 사용 중이므로 유지 (향후 필요시 변경)
-- DROP TYPE IF EXISTS manual_image_type CASCADE;

DROP TYPE IF EXISTS manual_storage_type CASCADE;
DROP TYPE IF EXISTS manual_audit_action CASCADE;

-- ============================================================================
-- Phase 3: unified_views 업데이트
-- ============================================================================

-- 3.1 unified_players 뷰 재정의 (manual_players 제거)
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

-- 3.2 unified_chip_data 뷰 재정의 (chip_snapshots 제거)
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

-- chip_snapshots UNION 제거됨

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '스키마 단순화 마이그레이션 완료:';
    RAISE NOTICE '  - manual_players 테이블 삭제';
    RAISE NOTICE '  - manual_audit_log 테이블 삭제';
    RAISE NOTICE '  - chip_snapshots 테이블 삭제';
    RAISE NOTICE '  - profile_images: wsop_player_id/gfx_player_id로 변경';
    RAISE NOTICE '  - player_overrides: gfx_player_id 추가';
    RAISE NOTICE '  - player_link_mapping: manual_player_id 제거';
    RAISE NOTICE '  - unified_players 뷰 업데이트';
    RAISE NOTICE '  - unified_chip_data 뷰 업데이트';
END $$;
