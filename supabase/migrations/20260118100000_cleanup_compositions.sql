-- ============================================================================
-- Migration: cleanup_compositions
-- Description: gfx_aep_compositions 테이블 정리 (v2.0.0 문서 기준)
-- Version: 1.0.0
-- Date: 2026-01-18
-- Reference: docs/08-GFX-AEP-Mapping.md v2.1.0
-- ============================================================================

-- ============================================================================
-- Phase 1: 제외 범위 컴포지션 삭제
-- v2.0.0 문서 기준으로 Source comp/ 폴더 위치 컴포지션 제거
-- ============================================================================

-- Chips (Source Comp): Source comp/ 폴더로 이동됨 (범위 외)
DELETE FROM gfx_aep_compositions
WHERE name = 'Chips (Source Comp)';

-- 관련 매핑 규칙도 삭제
DELETE FROM gfx_aep_field_mappings
WHERE composition_name = 'Chips (Source Comp)';

-- ============================================================================
-- Phase 2: Chip VPIP 메타데이터 업데이트
-- v2.0.0에서 NAME 컴포지션에 VPIP 통합됨 → 별도 컴포지션 비활성화
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    is_active = FALSE,
    metadata = metadata || '{"deprecated": true, "reason": "v2.0.0에서 NAME 컴포지션에 통합됨", "deprecated_at": "2026-01-18"}'::JSONB,
    updated_at = NOW()
WHERE name = 'Chip VPIP';

-- ============================================================================
-- Phase 3: NAME 컴포지션 슬롯 필드 키 업데이트
-- v2.0.0 확장 필드 반영: chips, bbs, flag, vpip 추가
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY['name', 'text_내용', 'chips', 'bbs', 'flag'],
    metadata = metadata || '{"version": "2.1.0", "updated_fields": ["chips", "bbs", "flag"]}'::JSONB,
    updated_at = NOW()
WHERE name = 'NAME';

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY['player_name', 'flag'],
    metadata = metadata || '{"version": "2.1.0", "updated_fields": ["flag"]}'::JSONB,
    updated_at = NOW()
WHERE name = 'NAME 1줄';

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY['player_name', 'chips', 'bbs'],
    metadata = metadata || '{"version": "2.1.0", "updated_fields": ["chips", "bbs"]}'::JSONB,
    updated_at = NOW()
WHERE name = 'NAME 2줄 (국기 빼고)';

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY['player_name', 'chips', 'bbs', 'vpip', 'flag', 'chips_10_hands_ago', 'chips_20_hands_ago', 'chips_30_hands_ago'],
    metadata = metadata || '{"version": "2.1.0", "updated_fields": ["vpip", "chips_N_hands_ago"]}'::JSONB,
    updated_at = NOW()
WHERE name = 'NAME 3줄+';

-- ============================================================================
-- Phase 4: At Risk of Elimination 필드 키 업데이트
-- v2.0.0 필드 분리 반영: text_내용 → player_name, rank, prize, flag
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY['player_name', 'rank', 'prize', 'flag'],
    metadata = metadata || '{"version": "2.1.0", "field_split": "text_내용 → player_name, rank, prize, flag"}'::JSONB,
    updated_at = NOW()
WHERE name = 'At Risk of Elimination';

-- ============================================================================
-- Phase 5: 전체 컴포지션 버전 업데이트
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    metadata = COALESCE(metadata, '{}'::JSONB) || '{"schema_version": "2.1.0"}'::JSONB,
    updated_at = NOW()
WHERE is_active = TRUE;

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
DECLARE
    v_deleted_count INTEGER;
    v_updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_deleted_count
    FROM gfx_aep_compositions
    WHERE name = 'Chips (Source Comp)';

    SELECT COUNT(*) INTO v_updated_count
    FROM gfx_aep_compositions
    WHERE metadata->>'schema_version' = '2.1.0';

    RAISE NOTICE 'gfx_aep_compositions 정리 완료:';
    RAISE NOTICE '  - Chips (Source Comp) 삭제: % 건', v_deleted_count;
    RAISE NOTICE '  - Chip VPIP 비활성화';
    RAISE NOTICE '  - NAME 계열 필드 키 업데이트 (4개)';
    RAISE NOTICE '  - At Risk of Elimination 필드 분리 적용';
    RAISE NOTICE '  - 전체 활성 컴포지션 버전 업데이트: % 건', v_updated_count;
END $$;
