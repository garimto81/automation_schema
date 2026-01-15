-- ============================================================================
-- Migration: update_compositions_v2
-- Description: gfx_aep_compositions 데이터 v2.0.0 업데이트
-- Version: 1.0.0
-- Date: 2026-01-17
-- Reference: docs/08-GFX-AEP-Mapping.md v2.0.0
-- ============================================================================

-- ============================================================================
-- Phase 1: 비활성화할 컴포지션 (v2.0.0에서 제외됨)
-- ============================================================================

-- Chip VPIP: NAME 3줄+로 통합됨
UPDATE gfx_aep_compositions
SET
    is_active = FALSE,
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{deprecated}',
        jsonb_build_object(
            'version', '2.0.0',
            'reason', 'NAME 3줄+로 통합',
            'deprecated_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'Chip VPIP';

-- Chips (Source Comp): Source comp/ 폴더로 이동됨
UPDATE gfx_aep_compositions
SET
    is_active = FALSE,
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{deprecated}',
        jsonb_build_object(
            'version', '2.0.0',
            'reason', 'Source comp/ 폴더로 이동 (범위 외)',
            'deprecated_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'Chips (Source Comp)';

-- ============================================================================
-- Phase 2: NAME 3줄+ 필드 키 업데이트 (히스토리 칩, VPIP 통합)
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'player_name',
        'chips',
        'bbs',
        'vpip',
        'chips_10_hands_ago',
        'chips_20_hands_ago',
        'chips_30_hands_ago',
        'chip_change_10h',
        'chip_change_20h',
        'chip_change_30h'
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'Chip VPIP 통합, 히스토리 칩 필드 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'NAME 3줄+';

-- ============================================================================
-- Phase 3: At Risk of Elimination 필드 분리 (v2.0.0)
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'player_name',
        'rank',
        'prize',
        'flag',
        'chips'
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'text_내용 → player_name, rank, prize, flag 필드 분리',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'At Risk of Elimination';

-- ============================================================================
-- Phase 4: Payouts 필드 확장 (event_name, start_rank 추가)
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'wsop_super_circuit_cyprus',
        'payouts',
        'total_prize',
        'event_name'  -- v2.0.0 추가
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'event_name 필드 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'Payouts';

-- Payouts 등수 바꾸기 가능: start_rank 파라미터 지원
UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'wsop_super_circuit_cyprus',
        'payouts',
        'event_name',  -- v2.0.0 추가
        'start_rank'   -- v2.0.0 추가 (파라미터)
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'event_name, start_rank 파라미터 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'Payouts 등수 바꾸기 가능';

-- ============================================================================
-- Phase 5: NAME 컴포지션 필드 확장 (chips, bbs 추가)
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'name',
        'text_내용',
        'chips',  -- v2.0.0 추가
        'bbs',    -- v2.0.0 추가
        'flag'    -- v2.0.0 추가
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'chips, bbs, flag 필드 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'NAME';

-- NAME 1줄: 국기 필드 추가
UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'player_name',
        'flag'  -- v2.0.0 추가
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'flag 필드 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'NAME 1줄';

-- NAME 2줄 (국기 빼고): chips, bbs 필드 추가
UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'player_name',
        'chips',  -- v2.0.0 추가
        'bbs'     -- v2.0.0 추가
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', 'chips, bbs 필드 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'NAME 2줄 (국기 빼고)';

-- ============================================================================
-- Phase 6: Chip Comparison 필드 업데이트 (v2.0.0 신규)
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'selected_player_name',
        'selected_player_chips',
        'selected_player_percent',
        'others_chips',
        'others_percent'
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', '완전한 필드 정의 추가',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'Chip Comparison';

-- ============================================================================
-- Phase 7: Chip Flow 필드 업데이트 (v2.0.0 신규)
-- ============================================================================

UPDATE gfx_aep_compositions
SET
    single_field_keys = ARRAY[
        'player_name',
        'chips_10h',
        'chips_20h',
        'chips_30h',
        'max_label',
        'min_label'
    ],
    metadata = jsonb_set(
        COALESCE(metadata, '{}'::JSONB),
        '{v2_upgrade}',
        jsonb_build_object(
            'version', '2.0.0',
            'changes', '완전한 필드 정의 추가 (배열 필드)',
            'upgraded_at', NOW()
        )
    ),
    updated_at = NOW()
WHERE name = 'Chip Flow';

-- ============================================================================
-- Phase 8: gfx_aep_field_mappings 업데이트
-- ============================================================================

-- At Risk of Elimination 매핑 추가 (필드 분리)
INSERT INTO gfx_aep_field_mappings (
    composition_name, composition_category, target_field_key,
    source_table, source_column, transform, default_value, notes
) VALUES
    ('At Risk of Elimination', 'elimination', 'player_name', 'v_render_at_risk', 'player_name', 'direct', '', 'v2.0.0 필드 분리'),
    ('At Risk of Elimination', 'elimination', 'rank', 'v_render_at_risk', 'rank', 'direct', '', 'v2.0.0 필드 분리'),
    ('At Risk of Elimination', 'elimination', 'prize', 'v_render_at_risk', 'prize', 'direct', '$0', 'v2.0.0 필드 분리'),
    ('At Risk of Elimination', 'elimination', 'flag', 'v_render_at_risk', 'flag', 'direct', 'Flag/Unknown.png', 'v2.0.0 필드 분리')
ON CONFLICT (composition_name, target_field_key, COALESCE(slot_range_start, 0)) DO UPDATE
SET
    source_table = EXCLUDED.source_table,
    source_column = EXCLUDED.source_column,
    notes = EXCLUDED.notes,
    updated_at = NOW();

-- ============================================================================
-- 검증 쿼리
-- ============================================================================

DO $$
DECLARE
    v_active_count INTEGER;
    v_chip_display_count INTEGER;
    v_event_info_count INTEGER;
BEGIN
    -- 전체 활성 컴포지션 수 확인
    SELECT COUNT(*) INTO v_active_count
    FROM gfx_aep_compositions
    WHERE is_active = TRUE;

    -- chip_display 카테고리 수 확인 (기대값: 6)
    SELECT COUNT(*) INTO v_chip_display_count
    FROM gfx_aep_compositions
    WHERE category = 'chip_display' AND is_active = TRUE;

    -- event_info 카테고리 수 확인 (기대값: 4)
    SELECT COUNT(*) INTO v_event_info_count
    FROM gfx_aep_compositions
    WHERE category = 'event_info' AND is_active = TRUE;

    RAISE NOTICE 'gfx_aep_compositions v2.0.0 업데이트 완료:';
    RAISE NOTICE '  - 전체 활성 컴포지션: % 개', v_active_count;
    RAISE NOTICE '  - chip_display 카테고리: % 개 (기대: 6)', v_chip_display_count;
    RAISE NOTICE '  - event_info 카테고리: % 개 (기대: 4)', v_event_info_count;
    RAISE NOTICE '  - Chip VPIP: 비활성화 (NAME 3줄+로 통합)';
    RAISE NOTICE '  - Chips (Source Comp): 비활성화 (범위 외)';
END $$;
