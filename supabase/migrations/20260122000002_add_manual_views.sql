-- ============================================================================
-- Migration: 20260122000002_add_manual_views.sql
-- Description: Manual 스키마 뷰 및 Realtime 알림 함수 추가 (문서 정의 기반)
-- Source: docs/04-Manual-DB.md Section 5, docs/01-DATA_FLOW.md Section 6.2
-- ============================================================================

-- ============================================================================
-- v_player_images_all: 플레이어별 모든 이미지 목록
-- GFX/WSOP 플레이어 기반 (manual_players 삭제됨)
-- ============================================================================

CREATE OR REPLACE VIEW v_player_images_all AS
-- GFX 플레이어 이미지
SELECT
    'gfx' AS source,
    gp.id AS player_id,
    gp.player_hash AS player_code,
    gp.name AS player_name,
    pi.id AS image_id,
    pi.image_type,
    pi.storage_type,
    pi.file_path,
    pi.file_name,
    pi.file_size,
    pi.width,
    pi.height,
    pi.is_primary,
    pi.is_approved,
    pi.uploaded_by,
    pi.uploaded_at
FROM gfx_players gp
JOIN profile_images pi ON gp.id = pi.gfx_player_id

UNION ALL

-- WSOP 플레이어 이미지
SELECT
    'wsop' AS source,
    wp.id AS player_id,
    wp.wsop_player_id AS player_code,
    wp.name AS player_name,
    pi.id AS image_id,
    pi.image_type,
    pi.storage_type,
    pi.file_path,
    pi.file_name,
    pi.file_size,
    pi.width,
    pi.height,
    pi.is_primary,
    pi.is_approved,
    pi.uploaded_by,
    pi.uploaded_at
FROM wsop_players wp
JOIN profile_images pi ON wp.id = pi.wsop_player_id

ORDER BY source, player_name, image_type, is_primary DESC;

-- ============================================================================
-- v_active_overrides: 현재 활성화된 오버라이드 목록
-- GFX/WSOP 플레이어 기반 (manual_player_id 삭제됨)
-- ============================================================================

CREATE OR REPLACE VIEW v_active_overrides AS
SELECT
    po.id,
    CASE
        WHEN po.gfx_player_id IS NOT NULL THEN 'gfx'
        ELSE 'wsop'
    END AS source,
    COALESCE(gp.name, wp.name) AS player_name,
    COALESCE(gp.player_hash, wp.wsop_player_id) AS player_code,
    po.field_name,
    po.override_value,
    po.original_value,
    po.reason,
    po.priority,
    po.valid_from,
    po.valid_until,
    po.created_by,
    po.approved_by,
    po.created_at

FROM player_overrides po
LEFT JOIN gfx_players gp ON po.gfx_player_id = gp.id
LEFT JOIN wsop_players wp ON po.wsop_player_id = wp.id
WHERE po.active = TRUE
  AND (po.valid_from IS NULL OR po.valid_from <= NOW())
  AND (po.valid_until IS NULL OR po.valid_until > NOW())
ORDER BY po.priority, player_name;

-- ============================================================================
-- v_linked_players: GFX ↔ WSOP 연결된 플레이어 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_linked_players AS
SELECT
    plm.id AS link_id,
    plm.gfx_player_id,
    plm.wsop_player_id,
    gp.name AS gfx_name,
    wp.name AS wsop_name,
    wp.country_code,
    plm.match_confidence,
    plm.match_method,
    plm.is_verified,
    plm.verified_by,
    plm.verified_at,
    plm.created_at
FROM player_link_mapping plm
JOIN gfx_players gp ON plm.gfx_player_id = gp.id
JOIN wsop_players wp ON plm.wsop_player_id = wp.id
ORDER BY plm.match_confidence DESC, gp.name;

-- ============================================================================
-- notify_cue_item_change: Cue item 변경 시 Realtime 알림
-- Source: docs/01-DATA_FLOW.md Section 6.2
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_cue_item_change()
RETURNS TRIGGER AS $$
DECLARE
    v_session_id UUID;
BEGIN
    -- 세션 ID 조회
    SELECT cs.session_id INTO v_session_id
    FROM cue_sheets cs
    WHERE cs.id = NEW.sheet_id;

    -- Realtime 채널로 알림
    PERFORM pg_notify(
        'cue_changes',
        json_build_object(
            'event', TG_OP,
            'session_id', v_session_id,
            'sheet_id', NEW.sheet_id,
            'cue_id', NEW.id,
            'cue_number', NEW.cue_number,
            'status', NEW.status,
            'timestamp', NOW()
        )::TEXT
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 (cue_items 테이블이 존재할 경우에만)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'cue_items') THEN
        DROP TRIGGER IF EXISTS cue_item_realtime_trigger ON cue_items;
        CREATE TRIGGER cue_item_realtime_trigger
            AFTER INSERT OR UPDATE ON cue_items
            FOR EACH ROW
            EXECUTE FUNCTION notify_cue_item_change();
    END IF;
END $$;
